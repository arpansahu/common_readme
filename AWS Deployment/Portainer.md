## Portainer

Portainer is a web UI to manage your Docker and Kubernetes. Portainer consists of two elements: the Portainer Server and the Portainer Agent. Both elements run as lightweight Docker containers on a Docker engine. This guide provides a clean, repeatable, production-ready setup for Portainer with Docker and Kubernetes, accessible locally via LAN IP + port and publicly via Nginx + HTTPS.

### Prerequisites

Before installing Portainer, ensure you have:

1. Ubuntu Server (20.04 / 22.04 recommended)
2. Static local IP (example: 192.168.1.200)
3. Internet access
4. Docker installed and running
5. Nginx installed (for HTTPS access)
6. Certbot installed (for SSL certificates)

### Installing Required Packages

1. Update package list

    ```bash
    sudo apt update
    ```

2. Install Docker, Nginx, and Certbot

    ```bash
    sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx
    ```

3. Enable and start Docker

    ```bash
    sudo systemctl enable docker
    sudo systemctl start docker
    ```

### Installing Portainer Server

1. Create a Docker Volume for Portainer Data (recommended)

    This step is optional but recommended as it allows you to persist Portainer's data across container restarts.

    ```bash
    docker volume create portainer_data
    ```

2. Run Portainer Server Container

    ```bash
    docker run -d \
      -p 0.0.0.0:9998:9000 \
      -p 9443:9443 \
      --name portainer \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce
    ```

    Port mapping:
    - `9998` → Portainer UI (LAN / Nginx upstream)
    - `9443` → Native HTTPS (not used when behind Nginx)

3. Access Portainer UI (Initial Setup)

    Immediately open ONE URL only (important):

    Local LAN:
    ```
    http://192.168.1.200:9998
    ```

    OR Public (after Nginx setup):
    ```
    https://portainer.yourdomain.com
    ```

    Create admin user and password.

    Important: If setup is not completed quickly, Portainer will lock itself.

    If locked, restart Portainer:

    ```bash
    docker restart portainer
    ```

### Configuring Nginx as Reverse Proxy

1. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

    If /etc/nginx/sites-available/services does not exist:

    1. Create a new configuration file in the Nginx configuration directory:

        ```bash
        touch /etc/nginx/sites-available/services
        vi /etc/nginx/sites-available/services
        ```

2. Add Server Block Configuration

    ```bash
    server {
        listen         80;
        server_name    portainer.arpansahu.space;
        
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }

        location / {
            proxy_pass              http://127.0.0.1:9998;
            proxy_set_header        Host $host;
            proxy_set_header        X-Forwarded-Proto $scheme;
        }

        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/arpansahu.space/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.space/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    }
    ```

3. Enable the Configuration

    If using sites-available/sites-enabled pattern:

    ```bash
    sudo ln -s /etc/nginx/sites-available/services /etc/nginx/sites-enabled/
    ```

4. Test the Nginx Configuration

    ```bash
    sudo nginx -t
    ```

5. Reload Nginx to apply the new configuration

    ```bash
    sudo systemctl reload nginx
    ```

### Installing Portainer Agent

Portainer Agent is mandatory for production environments because it provides:
- Stable Docker communication
- Multi-node and Kubernetes support
- No direct Docker socket exposure in UI

1. Run Portainer Agent Container

    Important: Older agent versions or missing `/host` mount cause restart loops.

    ```bash
    docker run -d \
      -p 9001:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      -v /:/host \
      portainer/agent:2.33.6
    ```

2. Verify Agent is Running

    ```bash
    docker ps | grep portainer
    ```

    Expected output:
    ```
    Up   0.0.0.0:9001->9001/tcp   portainer_agent
    ```

### Adding Docker Environment in Portainer

1. Access Portainer UI

    Go to: https://portainer.arpansahu.space

2. Navigate to Environments

    Portainer UI → Environments → Add Environment

3. Configure Docker Environment

    - Type: Docker Standalone
    - Name: `docker-prod-env`
    - Environment address: `192.168.1.200:9001`

    Important:
    - Do NOT use public domain for agent
    - Do NOT proxy agent via Nginx
    - Use LAN IP address only

4. Click Connect

### Access Methods

Important: Never mix access origins in the same session.

Choose ONE method per session:

| Access Type  | URL                                          |
| ------------ | -------------------------------------------- |
| Local LAN    | http://192.168.1.200:9998                    |
| Public HTTPS | https://portainer.arpansahu.space            |

Mixing IP + domain causes 403 CSRF errors.

If broken, restart Portainer:

```bash
docker restart portainer
```

### Managing Portainer with Docker

1. View Portainer Status

    ```bash
    docker ps | grep portainer
    ```

2. Stop Portainer

    ```bash
    docker stop portainer
    ```

3. Start Portainer

    ```bash
    docker start portainer
    ```

4. Restart Portainer

    ```bash
    docker restart portainer
    ```

5. View Logs

    ```bash
    docker logs portainer
    docker logs -f portainer  # Follow logs
    ```

6. Remove Container (keeps data if using volumes)

    ```bash
    docker stop portainer
    docker rm portainer
    ```

### Security Hardening (Recommended)

After confirming everything works:

1. Block direct UI from WAN

    ```bash
    sudo ufw deny 9998
    ```

2. Allow agent only from LAN

    ```bash
    sudo ufw allow from 192.168.1.0/24 to any port 9001
    ```

3. Optional Security Measures

    - Enable RBAC in Portainer
    - Create teams and roles
    - Regularly backup portainer_data volume

### Common Issues and Fixes

1. Portainer Agent Restarting

    Cause: Missing `/host` mount or old agent version

    Fix:

    ```bash
    docker rm -f portainer_agent
    # Re-run correct agent command with /host mount
    ```

2. 403 Forbidden on Login/Logout

    Cause: Mixed HTTP/HTTPS or IP/domain access

    Fix:

    - Use only ONE URL consistently
    - Clear browser cache
    - Restart Portainer:

    ```bash
    docker restart portainer
    ```

3. Cannot Access Portainer UI

    Cause: Container not running or port conflict

    Fix:

    ```bash
    docker ps -a | grep portainer
    docker start portainer
    sudo netstat -tulnp | grep 9998
    ```

4. Agent Connection Failed

    Cause: Wrong IP address or port

    Fix:

    - Use LAN IP (192.168.1.200:9001)
    - Do NOT use domain name
    - Verify agent is running:

    ```bash
    docker ps | grep portainer_agent
    ```

5. Setup Timeout

    Cause: Portainer initial setup not completed in time

    Fix:

    ```bash
    docker restart portainer
    # Immediately open URL and complete setup
    ```

### Architecture Overview

```
Browser (Client)
   │
   ├─ Local: 192.168.1.200:9998
   └─ Public: https://portainer.domain.com
        │
        └─ Nginx (HTTPS)
             │
             └─ Portainer Server (9998)
                  │
                  └─ Portainer Agent (9001)
                       │
                       └─ Docker / Kubernetes
```

### Final Verification Checklist

Run these commands to verify everything is working:

```bash
docker ps | grep portainer
docker logs portainer | tail -20
curl http://localhost:9998
```

Then access in browser:
- Local: http://192.168.1.200:9998
- Public: https://portainer.arpansahu.space

### What This Setup Provides

After following this guide, you will have:

1. Repeatable Portainer setup
2. No authentication or CSRF issues
3. No agent crashes
4. Secure production layout
5. Works on both LAN and Internet
6. Docker management through web UI
7. Ready for Kubernetes integration

### Example Access Details

| Item                | Value                                 |
| ------------------- | ------------------------------------- |
| Portainer UI URL    | https://portainer.arpansahu.space     |
| Local Access        | http://192.168.1.200:9998             |
| Agent Address       | 192.168.1.200:9001                    |
| Portainer UI Port   | 9998                                  |
| Agent Port          | 9001                                  |
| HTTPS Port          | 9443                                  |

My Portainer can be accessed here: https://portainer.arpansahu.space

For Kubernetes setup with Portainer, see: [Kubernetes with Portainer Setup](kubernetes_with_portainer/deployment.md)

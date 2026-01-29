## RabbitMQ Server

RabbitMQ is a reliable and mature messaging and streaming broker, which is easy to deploy on cloud environments, on-premises, and on your local machine. It is currently used by millions worldwide.

### Prerequisites

Before installing RabbitMQ, ensure you have:

1. Ubuntu / Debian server
2. Docker and Docker Compose installed
3. Nginx installed (for domain-based access with HTTPS)
4. Ports 5672 (AMQP) and 15672 (Management UI) available

### Installing RabbitMQ

#### Method 1: Docker Installation (Recommended)

1. Fix Docker IPv4/MTU Issues (Critical for Indian ISPs)

    Before running any Docker containers, fix Docker's DNS and MTU settings to avoid network issues:

    ```bash
    sudo nano /etc/docker/daemon.json
    ```

    Add or update with:

    ```json
    {
      "dns": ["8.8.8.8", "8.8.4.4"],
      "mtu": 1400
    }
    ```

    Restart Docker:

    ```bash
    sudo systemctl restart docker
    ```

2. Create Persistent Data Directory

    Create a directory to persist RabbitMQ data:

    ```bash
    sudo mkdir -p /var/lib/rabbitmq
    sudo chown -R 999:999 /var/lib/rabbitmq
    ```

3. Run RabbitMQ with Docker

    Run RabbitMQ with management plugin enabled:

    ```bash
    docker run -d \
      --name rabbitmq \
      --restart unless-stopped \
      -p 5672:5672 \
      -p 15672:15672 \
      -e RABBITMQ_DEFAULT_USER=admin \
      -e RABBITMQ_DEFAULT_PASS=your_secure_password \
      -v /var/lib/rabbitmq:/var/lib/rabbitmq \
      rabbitmq:3-management
    ```

    Replace `your_secure_password` with a strong password.

4. Verify RabbitMQ is Running

    Check container status:

    ```bash
    docker ps | grep rabbitmq
    ```

    Expected output:
    ```
    rabbitmq   Up   0.0.0.0:5672->5672/tcp, 0.0.0.0:15672->15672/tcp
    ```

    Check logs:

    ```bash
    docker logs rabbitmq
    ```

    You should see: "Server startup complete"

5. Test RabbitMQ Connection

    Test AMQP connection:

    ```bash
    telnet localhost 5672
    ```

    Test Management UI (local):

    ```bash
    curl http://localhost:15672
    ```

#### Method 2: Docker Compose Installation

1. Create docker-compose.yml

    Create a file for RabbitMQ configuration:

    ```bash
    mkdir -p ~/rabbitmq-docker
    cd ~/rabbitmq-docker
    nano docker-compose.yml
    ```

2. Add Docker Compose Configuration

    ```yaml
    version: '3.8'

    services:
      rabbitmq:
        image: rabbitmq:3-management
        container_name: rabbitmq
        restart: unless-stopped
        ports:
          - "5672:5672"
          - "15672:15672"
        environment:
          RABBITMQ_DEFAULT_USER: admin
          RABBITMQ_DEFAULT_PASS: your_secure_password
        volumes:
          - /var/lib/rabbitmq:/var/lib/rabbitmq
        networks:
          - rabbitmq-network

    networks:
      rabbitmq-network:
        driver: bridge
    ```

3. Start RabbitMQ

    ```bash
    docker-compose up -d
    ```

4. Verify Installation

    ```bash
    docker-compose ps
    docker-compose logs -f rabbitmq
    ```

### Access Methods

RabbitMQ can be accessed in three ways:

#### Access Method 1: Domain with HTTPS (Recommended for Production)

This method uses Nginx as a reverse proxy with SSL termination.

Access URL: https://rabbitmq-admin.arpansahu.space

#### Access Method 2: Static IP with Port

Access directly via IP address and port.

Management UI: http://your-server-ip:15672
AMQP Connection: your-server-ip:5672

#### Access Method 3: Local/Private IP

For internal network access only.

Management UI: http://192.168.1.x:15672
AMQP Connection: 192.168.1.x:5672

### Configuring Nginx as Reverse Proxy (For Domain Access)

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

    For HTTP to HTTPS redirect:

    ```bash
    # ---------------- RABBITMQ ADMIN ----------------

    server {
        listen 80;
        listen [::]:80;

        server_name rabbitmq-admin.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name rabbitmq-admin.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        location / {
            proxy_pass http://127.0.0.1:15672;
            proxy_http_version 1.1;

            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade           $http_upgrade;
            proxy_set_header Connection        "upgrade";
        }
    }
    ```

    Alternative configuration (if using Certbot managed certificates):

    ```bash
    server {
        listen         80;
        server_name    rabbitmq-admin.arpansahu.space;
        
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }

        location / {
            proxy_pass              http://127.0.0.1:15672;
            proxy_set_header        Host $host;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_set_header        Upgrade $http_upgrade;
            proxy_set_header        Connection "upgrade";
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

### Firewall Configuration

If using UFW firewall, allow the necessary ports:

1. For direct access (optional):

    ```bash
    sudo ufw allow 5672/tcp
    sudo ufw allow 15672/tcp
    ```

2. For Nginx access only:

    ```bash
    sudo ufw allow 'Nginx Full'
    ```

### Creating RabbitMQ Users and Virtual Hosts

1. Access RabbitMQ Container

    ```bash
    docker exec -it rabbitmq bash
    ```

2. Create a New User

    ```bash
    rabbitmqctl add_user myuser mypassword
    ```

3. Set User Tags (Administrator)

    ```bash
    rabbitmqctl set_user_tags myuser administrator
    ```

4. Set User Permissions

    ```bash
    rabbitmqctl set_permissions -p / myuser ".*" ".*" ".*"
    ```

5. Create Virtual Host

    ```bash
    rabbitmqctl add_vhost myvhost
    ```

6. Set Permissions on Virtual Host

    ```bash
    rabbitmqctl set_permissions -p myvhost myuser ".*" ".*" ".*"
    ```

7. List Users

    ```bash
    rabbitmqctl list_users
    ```

8. List Virtual Hosts

    ```bash
    rabbitmqctl list_vhosts
    ```

9. Exit Container

    ```bash
    exit
    ```

### Managing RabbitMQ with Docker

1. View Container Status

    ```bash
    docker ps | grep rabbitmq
    ```

2. Stop RabbitMQ

    ```bash
    docker stop rabbitmq
    ```

3. Start RabbitMQ

    ```bash
    docker start rabbitmq
    ```

4. Restart RabbitMQ

    ```bash
    docker restart rabbitmq
    ```

5. View Logs

    ```bash
    docker logs rabbitmq
    docker logs -f rabbitmq  # Follow logs
    ```

6. Remove Container (keeps data if using volumes)

    ```bash
    docker stop rabbitmq
    docker rm rabbitmq
    ```

### Testing RabbitMQ

1. Test Management API

    ```bash
    curl -u admin:your_secure_password http://localhost:15672/api/overview
    ```

2. Test Queue Creation via API

    ```bash
    curl -u admin:your_secure_password -X GET http://localhost:15672/api/queues
    ```

3. Test from External Server

    ```bash
    curl -u admin:your_secure_password https://rabbitmq-admin.arpansahu.space/api/overview
    ```

### Architecture Notes

Important points about this setup:

1. SSL termination happens at Nginx only (improves performance)
2. RabbitMQ listens on localhost (127.0.0.1) via Docker port mapping
3. Nginx handles HTTPS and reverse proxy
4. Docker ensures automatic restart and isolation
5. Data persistence is handled via Docker volumes

### Debugging Common Issues

1. Connection Refused Error

    Cause: RabbitMQ container not running

    Fix:

    ```bash
    docker ps -a | grep rabbitmq
    docker start rabbitmq
    docker logs rabbitmq
    ```

2. 502 Bad Gateway (Nginx)

    Cause: RabbitMQ not responding or wrong proxy_pass address

    Fix:

    ```bash
    docker ps | grep rabbitmq
    curl http://127.0.0.1:15672
    sudo nginx -t
    sudo systemctl reload nginx
    ```

3. Authentication Failed

    Cause: Wrong credentials or user not created

    Fix:

    ```bash
    docker exec -it rabbitmq rabbitmqctl list_users
    docker exec -it rabbitmq rabbitmqctl change_password admin new_password
    ```

4. Docker Network Issues

    Cause: DNS or MTU problems

    Fix:

    ```bash
    # Check /etc/docker/daemon.json has correct DNS and MTU
    cat /etc/docker/daemon.json
    sudo systemctl restart docker
    docker restart rabbitmq
    ```

5. Port Already in Use

    Cause: Another service using ports 5672 or 15672

    Fix:

    ```bash
    sudo netstat -tulnp | grep 5672
    sudo netstat -tulnp | grep 15672
    # Stop conflicting service or change Docker port mapping
    ```

### Final Verification Checklist

Run these commands to verify everything is working:

```bash
docker ps | grep rabbitmq
docker logs rabbitmq | tail -20
curl http://localhost:15672
curl -u admin:your_secure_password http://localhost:15672/api/overview
```

Then access in browser:
- Management UI: https://rabbitmq-admin.arpansahu.space
- Login with: admin / your_secure_password

### Performance Note

SSL is terminated at Nginx level, not at RabbitMQ. This approach:

1. Reduces RabbitMQ CPU overhead
2. Centralizes SSL certificate management
3. Allows Nginx to handle SSL optimization
4. Keeps RabbitMQ focused on message brokering

For direct AMQP connections (from applications), use:
- Host: your-server-ip or rabbitmq-admin.arpansahu.space
- Port: 5672 (non-SSL) or configure SSL separately if needed
- Username: admin
- Password: your_secure_password

### Example Access Details

| Item                  | Value                                      |
| --------------------- | ------------------------------------------ |
| Management UI URL     | https://rabbitmq-admin.arpansahu.space     |
| AMQP Connection       | your-server-ip:5672                        |
| Default Username      | admin                                      |
| Default Password      | your_secure_password                       |
| Management UI Port    | 15672                                      |
| AMQP Port             | 5672                                       |

My RabbitMQ Admin Panel can be accessed at: https://rabbitmq-admin.arpansahu.space

## Redis Commander

Redis Commander is a web-based management tool for Redis databases. It provides a user-friendly interface to interact with Redis, making it easier to manage and monitor your Redis instances.

![Image](https://raw.githubusercontent.com/joeferner/redis-commander/HEAD/docs/GUI_EXAMPLE.png)

![Image](https://assets.northflank.com/tls_enabled_env_var_a528b10009.png)

![Image](https://i.sstatic.net/tgtI9.png)

### Prerequisites

Before installing Redis Commander, ensure you have:

1. Ubuntu / Debian server with Redis already installed and running
2. Node.js and npm installed
3. Nginx installed
4. Redis accessible locally:

    ```bash
    redis-cli -h 127.0.0.1 -p 6379 -a <REDIS_PASSWORD> ping
    ```

5. SSL certificates available (if using HTTPS):

    ```
    /etc/nginx/ssl/arpansahu.space/fullchain.pem
    /etc/nginx/ssl/arpansahu.space/privkey.pem
    ```

### Installing Redis Commander

#### Method 1: Docker Installation (Recommended)

1. Pull Redis Commander Image

    ```bash
    docker pull rediscommander/redis-commander:latest
    ```

2. Run Redis Commander (Basic - single Redis)

    ```bash
    docker run -d \
      --name redis-commander \
      -p 8081:8081 \
      -e REDIS_HOSTS=local:127.0.0.1:6379 \
      rediscommander/redis-commander:latest
    ```

    Access UI at: http://<server-ip>:8081

3. Run Redis Commander (Multiple Redis instances)

    ```bash
    docker run -d \
      --name redis-commander \
      -p 8081:8081 \
      -e REDIS_HOSTS="redis1:10.0.0.1:6379,redis2:10.0.0.2:6379" \
      rediscommander/redis-commander:latest
    ```

4. If Redis is running in Docker (same host)

    ```bash
    docker run -d \
      --name redis-commander \
      --network host \
      -e REDIS_HOSTS=local:127.0.0.1:6379 \
      rediscommander/redis-commander:latest
    ```

    Note: --network host avoids Docker networking issues and is recommended for servers.

5. Persist Redis Commander via Docker Restart Policy

    ```bash
    docker update --restart unless-stopped redis-commander
    ```

6. Verify Docker Installation

    ```bash
    docker ps
    ```

    You should see:
    ```
    redis-commander   Up   0.0.0.0:8081->8081/tcp
    ```

#### Method 2: NPM Installation with PM2

1. Installation

    Install redis-commander globally using npm (Node Package Manager):

    ```bash
    sudo npm install -g redis-commander
    ```

    Note: npm warnings about deprecated packages are normal and safe.

    Verify installation:

    ```bash
    redis-commander --version
    ```

2. Install PM2 (Process Manager)

    PM2 is used to run Redis Commander in background, restart it if it crashes, and auto-start on server reboot:

    ```bash
    sudo npm install -g pm2
    ```

3. Start Redis Commander with PM2

    Replace the values with your Redis configuration:

    ```bash
    pm2 start redis-commander \
      --name redis-commander \
      -- \
      --port 9996 \
      --redis-host 127.0.0.1 \
      --redis-port 6379 \
      --redis-password 'your-redis-password'
    ```

    Check status:

    ```bash
    pm2 status
    ```

    Expected output should show: redis-commander online

4. Save PM2 State (CRITICAL)

    Without this, Redis Commander will disappear after reboot:

    ```bash
    pm2 save
    ```

    This creates: /home/your-username/.pm2/dump.pm2

5. Enable PM2 Auto-Start on Boot (CRITICAL)

    ```bash
    pm2 startup
    ```

    PM2 will print a command like:

    ```bash
    sudo env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u your-username --hp /home/your-username
    ```

    Copy and run that exact command, then save again:

    ```bash
    pm2 save
    ```

6. Verify Redis Commander Is Running

    ```bash
    ss -lntp | grep 9996
    ```

    Expected: LISTEN 127.0.0.1:9996

    Local test:

    ```bash
    curl http://127.0.0.1:9996
    ```

### Serving with Nginx and Password Protection

Redis Commander does not have native password protection enabled, so we secure it at the Nginx level.

1. Install htpasswd utility

    ```bash
    sudo apt update
    sudo apt install apache2-utils -y
    ```

2. Create a Basic Authentication File

    Use the htpasswd utility to create a username and password combination. Replace your_username with your desired username:

    ```bash
    sudo htpasswd -c /etc/nginx/.htpasswd your_username
    ```

    You'll be prompted to enter a password.

3. Fix permissions

    ```bash
    sudo chown root:www-data /etc/nginx/.htpasswd
    sudo chmod 640 /etc/nginx/.htpasswd
    ```

    Verify:

    ```bash
    ls -l /etc/nginx/.htpasswd
    ```

    Expected: -rw-r----- 1 root www-data

4. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

    If /etc/nginx/sites-available/services does not exist:

    1. Create a new configuration file in the Nginx configuration directory:

        ```bash
        touch /etc/nginx/sites-available/services
        vi /etc/nginx/sites-available/services
        ```

5. Add server block configuration

    For HTTP to HTTPS redirect with Basic Auth:

    ```bash
    # ---------------- REDIS COMMANDER ----------------

    server {
        listen 80;
        listen [::]:80;

        server_name redis.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name redis.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        # Basic Auth
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        location / {
            proxy_pass http://127.0.0.1:9996;
            proxy_http_version 1.1;

            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    ```

    Alternative configuration (if using Certbot managed certificates):

    ```bash
    server {
        listen         80;
        server_name    redis.arpansahu.space;
        
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }

        location / {
            proxy_pass              http://127.0.0.1:9996;
            proxy_set_header        Host $host;
            proxy_set_header        X-Forwarded-Proto $scheme;
            auth_basic "Restricted Access";
            auth_basic_user_file /etc/nginx/.htpasswd;
        }

        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/arpansahu.space/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.space/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    }
    ```

6. Test the Nginx Configuration

    ```bash
    sudo nginx -t
    ```

7. Reload Nginx to apply the new configuration

    ```bash
    sudo systemctl reload nginx
    ```

### Managing Redis Commander with PM2

Now, redis-commander is running in the background managed by pm2. You can view its status, logs, and manage it using pm2 commands:

1. View the status

    ```bash
    pm2 status
    ```

2. Stop the process

    ```bash
    pm2 stop redis-commander
    ```

3. Restart the process

    ```bash
    pm2 restart redis-commander
    ```

4. View logs

    ```bash
    pm2 logs redis-commander
    ```

5. Delete the process

    ```bash
    pm2 delete redis-commander
    ```

### Architecture Notes

Important points about this setup:

1. Redis is never exposed publicly
2. Redis Commander listens only on 127.0.0.1
3. Nginx handles HTTPS, Authentication, and Reverse proxy
4. PM2 ensures Auto restart, Crash recovery, and Reboot survival

### Debugging Common Issues

1. 403 Forbidden Error

    Cause: .htpasswd missing or unreadable

    Fix:

    ```bash
    sudo htpasswd -c /etc/nginx/.htpasswd your_username
    sudo chown root:www-data /etc/nginx/.htpasswd
    sudo chmod 640 /etc/nginx/.htpasswd
    ```

2. 502 Bad Gateway Error

    Cause: Redis Commander not running or PM2 process missing

    Fix:

    ```bash
    pm2 status
    pm2 start redis-commander --name redis-commander -- --port 9996 --redis-host 127.0.0.1 --redis-port 6379 --redis-password 'your-redis-password'
    ```

3. PM2 Commands Hanging

    Cause: Corrupted PM2 daemon after reboot

    Fix:

    ```bash
    sudo kill -9 <PM2_PID>
    rm -rf ~/.pm2/rpc.sock ~/.pm2/pub.sock
    pm2 status
    ```

### Final Verification Checklist

Run these commands to verify everything is working:

```bash
pm2 status
pm2 save
ss -lntp | grep 9996
curl http://127.0.0.1:9996
```

Then access in browser: https://redis.arpansahu.space

### Example Access Details

| Item           | Value                                                          |
| -------------- | -------------------------------------------------------------- |
| URL            | https://redis.arpansahu.space                                  |
| Username       | your_username                                                  |
| Password       | your_password                                                  |
| Redis Password | your-redis-password                                            |
| Internal Port  | 127.0.0.1:9996                                                 |

My Redis Commander can be accessed here: https://redis.arpansahu.space

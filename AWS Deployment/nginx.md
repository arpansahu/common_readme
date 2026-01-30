## Nginx

Nginx is a high-performance web server and reverse proxy. This guide provides a production-ready setup for hosting multiple services behind Nginx with proper SSL/TLS configuration.

### Prerequisites

Before installing Nginx, ensure you have:

1. Ubuntu Server (20.04 / 22.04 recommended)
2. Root or sudo access
3. Domain name configured (example: arpansahu.me)
4. DNS records pointing to your server
5. Firewall configured to allow HTTP/HTTPS traffic

### Installing Nginx

1. Update package list

    ```bash
    sudo apt update
    ```

2. Install Nginx

    ```bash
    sudo apt install -y nginx
    ```

3. Start Nginx

    ```bash
    sudo systemctl start nginx
    ```

4. Enable Nginx to start on boot

    ```bash
    sudo systemctl enable nginx
    ```

5. Verify Nginx is running

    ```bash
    sudo systemctl status nginx
    ```

    Expected output: Active (running)

### Configuring DNS Records

Add these DNS records to your domain provider (example for arpansahu.me):

1. Base domain A record

    ```
    Type: A Record
    Name: @
    Value: YOUR_SERVER_PUBLIC_IP
    TTL: Automatic
    ```

2. Wildcard subdomain A record

    ```
    Type: A Record
    Name: *
    Value: YOUR_SERVER_PUBLIC_IP
    TTL: Automatic
    ```

    This allows all subdomains (jenkins.arpansahu.me, portainer.arpansahu.me, etc.) to point to your server.

### Configuring Firewall

1. Allow HTTP traffic

    ```bash
    sudo ufw allow 80/tcp
    ```

2. Allow HTTPS traffic

    ```bash
    sudo ufw allow 443/tcp
    ```

3. Reload firewall

    ```bash
    sudo ufw reload
    ```

4. Verify firewall rules

    ```bash
    sudo ufw status
    ```

### Creating Nginx Configuration File

1. Create new configuration file

    ```bash
    sudo touch /etc/nginx/sites-available/services
    sudo vi /etc/nginx/sites-available/services
    ```

2. Add base configuration

    ```nginx
    server_tokens off;
    access_log /var/log/nginx/services.access.log;
    error_log /var/log/nginx/services.error.log;

    # HTTP server block (will be updated for HTTPS later)
    server {
        listen 80;
        listen [::]:80;
        server_name arpansahu.me www.arpansahu.me;

        location / {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    ```

3. Enable the configuration

    ```bash
    sudo ln -s /etc/nginx/sites-available/services /etc/nginx/sites-enabled/
    ```

4. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

    Expected output: syntax is ok, test is successful

5. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Testing Nginx

1. Test from local server

    ```bash
    curl -I http://localhost
    ```

2. Test from browser

    Open: http://YOUR_SERVER_IP

    You should see the Nginx default page or your proxied application.

### Adding Multiple Services

To host multiple services, add additional server blocks to the same file:

1. Edit configuration file

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

2. Add service-specific server blocks

    ```nginx
    # Service 1 - Jenkins
    server {
        listen 80;
        listen [::]:80;
        server_name jenkins.arpansahu.me;

        location / {
            proxy_pass http://127.0.0.1:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # Service 2 - Portainer
    server {
        listen 80;
        listen [::]:80;
        server_name portainer.arpansahu.me;

        location / {
            proxy_pass http://127.0.0.1:9998;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    ```

3. Test and reload

    ```bash
    sudo nginx -t
    sudo systemctl reload nginx
    ```

### Nginx Configuration Best Practices

1. Use descriptive server names

    Always specify exact domain names instead of wildcards when possible.

2. Enable access and error logs

    ```nginx
    access_log /var/log/nginx/service-name.access.log;
    error_log /var/log/nginx/service-name.error.log;
    ```

3. Hide Nginx version

    ```nginx
    server_tokens off;
    ```

4. Set proper proxy headers

    Always include these headers for proxied applications:

    ```nginx
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    ```

5. Enable HTTP/2 (after SSL is configured)

    ```nginx
    listen 443 ssl http2;
    ```

### Managing Nginx

1. Check status

    ```bash
    sudo systemctl status nginx
    ```

2. Start Nginx

    ```bash
    sudo systemctl start nginx
    ```

3. Stop Nginx

    ```bash
    sudo systemctl stop nginx
    ```

4. Restart Nginx

    ```bash
    sudo systemctl restart nginx
    ```

5. Reload configuration (no downtime)

    ```bash
    sudo systemctl reload nginx
    ```

6. Test configuration

    ```bash
    sudo nginx -t
    ```

### Viewing Nginx Logs

1. View access logs

    ```bash
    sudo tail -f /var/log/nginx/services.access.log
    ```

2. View error logs

    ```bash
    sudo tail -f /var/log/nginx/services.error.log
    ```

3. View all Nginx logs

    ```bash
    sudo journalctl -u nginx -f
    ```

### Common Issues and Fixes

1. Nginx fails to start

    Cause: Configuration syntax error or port already in use

    Fix:

    ```bash
    sudo nginx -t
    sudo netstat -tulnp | grep :80
    sudo systemctl status nginx
    ```

2. 502 Bad Gateway

    Cause: Backend service not running or wrong port

    Fix:

    ```bash
    # Check backend service is running
    netstat -tulnp | grep :8000
    # Check proxy_pass URL in Nginx config
    ```

3. Permission denied errors

    Cause: SELinux or file permissions

    Fix:

    ```bash
    sudo chown -R www-data:www-data /var/www
    sudo chmod -R 755 /var/www
    ```

4. Configuration not taking effect

    Cause: Configuration not reloaded

    Fix:

    ```bash
    sudo nginx -t
    sudo systemctl reload nginx
    ```

### Architecture Overview

```
Internet (Client)
   │
   └─ Nginx (Port 80/443)
        │
        ├─ Service 1 (localhost:8000)
        ├─ Service 2 (localhost:8080)
        ├─ Service 3 (localhost:9998)
        └─ Service N (localhost:XXXX)
```

### Key Rules to Remember

1. Always test configuration before reloading: `sudo nginx -t`
2. Use reload instead of restart to avoid downtime
3. One configuration file can host multiple services
4. HTTP goes on port 80, HTTPS on port 443
5. Proxy to localhost (127.0.0.1) for security
6. Keep logs enabled for debugging
7. Disable server_tokens to hide Nginx version

### Final Verification Checklist

Run these commands to verify Nginx is working:

```bash
# Check Nginx is running
sudo systemctl status nginx

# Check port binding
sudo netstat -tulnp | grep nginx

# Test configuration
sudo nginx -t

# Test HTTP access
curl -I http://localhost
```

### What This Setup Provides

After following this guide, you will have:

1. Nginx installed and running
2. Multiple services behind single reverse proxy
3. Clean, maintainable configuration structure
4. Proper logging for debugging
5. Firewall configured for HTTP/HTTPS
6. DNS records configured
7. Ready for SSL/TLS configuration
8. Production-ready reverse proxy setup

### Example Service Configuration

| Service      | Domain                          | Backend Port |
| ------------ | ------------------------------- | ------------ |
| Main Site    | arpansahu.me                    | 8000         |
| Jenkins      | jenkins.arpansahu.me            | 8080         |
| Portainer    | portainer.arpansahu.me          | 9998         |
| PgAdmin      | pgadmin.arpansahu.me            | 5050         |
| RabbitMQ     | rabbitmq.arpansahu.me           | 15672        |
| Kafka AKHQ   | kafka.arpansahu.me              | 8086         |

### Next Steps

After completing this basic Nginx setup, proceed to:

1. Configure HTTPS with SSL certificates (see nginx_https.md)
2. Add security headers
3. Enable rate limiting
4. Configure caching if needed
5. Set up monitoring and alerts

For HTTPS setup, see: [Nginx HTTPS Setup Guide](nginx_https.md)

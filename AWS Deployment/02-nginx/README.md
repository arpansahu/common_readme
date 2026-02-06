## Nginx - Web Server & Reverse Proxy

Nginx is a high-performance web server and reverse proxy used to route HTTPS traffic to all services.

### Access Details

- **HTTP Port:** 80 (redirects to HTTPS)
- **HTTPS Port:** 443
- **Config Directory:** `/etc/nginx/sites-available/`
- **Enabled Sites:** `/etc/nginx/sites-enabled/`
- **SSL Certificates:** `/etc/nginx/ssl/arpansahu.space/`
- **Logs:** `/var/log/nginx/`

### Quick Install

```bash
cd "AWS Deployment/nginx"
chmod +x install.sh
./install.sh
```

### Installation Script

```bash file=install.sh
```

### SSL Certificate Installation

```bash file=install-ssl.sh
```

**Prerequisites for SSL:**
1. Namecheap account with API access enabled
2. Server IP whitelisted in Namecheap API settings
3. Environment variables set:

```bash
export NAMECHEAP_USERNAME="your_username"
export NAMECHEAP_API_KEY="your_api_key"
export NAMECHEAP_SOURCEIP="your_server_ip"
./install-ssl.sh
```

### Manual Installation

#### 1. Install Nginx

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 2. Configure Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

#### 3. Configure DNS

Add A records to your DNS provider:

```
Type: A Record
Name: @
Value: YOUR_SERVER_IP

Type: A Record  
Name: *
Value: YOUR_SERVER_IP
```

This allows all subdomains (*.arpansahu.space) to point to your server.

#### 4. Create Service Configuration

```bash
sudo nano /etc/nginx/sites-available/services
```

Add server blocks for each service (see individual service nginx configs).

#### 5. Enable Configuration

```bash
sudo ln -sf /etc/nginx/sites-available/services /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### SSL Certificate Setup (acme.sh)

#### Why acme.sh?

- Native DNS-01 challenge support
- Works perfectly with Namecheap
- Automatic renewal via cron
- Supports wildcard certificates
- Simpler than Certbot for DNS challenges

#### Install acme.sh

```bash
curl https://get.acme.sh | sh
source ~/.bashrc
acme.sh --set-default-ca --server letsencrypt
```

#### Configure Namecheap API

1. Login to Namecheap → Profile → Tools → API Access
2. Enable API Access
3. Whitelist your server's public IP
4. Get API credentials

#### Issue Wildcard Certificate

```bash
export NAMECHEAP_USERNAME="your_username"
export NAMECHEAP_API_KEY="your_api_key"
export NAMECHEAP_SOURCEIP="your_server_ip"

acme.sh --issue \
  --dns dns_namecheap \
  -d arpansahu.space \
  -d "*.arpansahu.space" \
  --server letsencrypt
```

#### Install Certificate for Nginx

```bash
sudo mkdir -p /etc/nginx/ssl/arpansahu.space

acme.sh --install-cert \
  -d arpansahu.space \
  -d "*.arpansahu.space" \
  --key-file /etc/nginx/ssl/arpansahu.space/privkey.pem \
  --fullchain-file /etc/nginx/ssl/arpansahu.space/fullchain.pem \
  --reloadcmd "systemctl reload nginx"
```

#### Setup Auto-Renewal

```bash
crontab -e
```

Add:
```
0 0 * * * ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null
```

### Nginx Configuration Structure

Each service has its own nginx config with this pattern:

```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name service.arpansahu.space;
    return 301 https://$host$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name service.arpansahu.space;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Proxy to backend service
    location / {
        proxy_pass http://127.0.0.1:PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### Service Routing Table

| Service         | Domain                           | Backend Port |
|-----------------|----------------------------------|--------------|
| Harbor          | harbor.arpansahu.space           | 8888         |
| RabbitMQ        | rabbitmq.arpansahu.space         | 15672        |
| PgAdmin         | pgadmin.arpansahu.space          | 5050         |
| SSH Terminal    | ssh.arpansahu.space              | 8084         |
| Jenkins         | jenkins.arpansahu.space          | 8080         |
| Portainer       | portainer.arpansahu.space        | 9443         |
| Redis (stream)  | redis.arpansahu.space            | 6380 (TCP)   |

### Common Commands

**Test configuration:**
```bash
sudo nginx -t
```

**Reload (no downtime):**
```bash
sudo systemctl reload nginx
```

**Restart:**
```bash
sudo systemctl restart nginx
```

**View status:**
```bash
sudo systemctl status nginx
```

**View logs:**
```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log

# Service-specific
sudo tail -f /var/log/nginx/services.access.log
```

**Check active connections:**
```bash
sudo ss -tuln | grep -E ':80|:443'
```

**List enabled sites:**
```bash
ls -la /etc/nginx/sites-enabled/
```

### Redis TCP Stream Configuration

Redis requires TCP stream instead of HTTP proxy:

```nginx
stream {
    upstream redis_backend {
        server 127.0.0.1:6380;
    }

    server {
        listen 6379 ssl;
        proxy_pass redis_backend;
        proxy_connect_timeout 1s;
        
        ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
    }
}
```

This goes in `/etc/nginx/nginx.conf` at the root level (outside http block).

### Troubleshooting

**502 Bad Gateway:**
```bash
# Check backend service is running
sudo ss -tuln | grep PORT

# Check nginx can connect
curl http://127.0.0.1:PORT

# Check logs
sudo tail -f /var/log/nginx/error.log
```

**Certificate errors:**
```bash
# Check certificate files exist
ls -la /etc/nginx/ssl/arpansahu.space/

# Check certificate validity
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -text -noout

# Check acme.sh status
acme.sh --list
```

**Configuration not loading:**
```bash
# Test syntax
sudo nginx -t

# Check enabled sites
ls -la /etc/nginx/sites-enabled/

# Reload nginx
sudo systemctl reload nginx
```

**Port already in use:**
```bash
# Find what's using port 80/443
sudo ss -tuln | grep -E ':80|:443'
sudo lsof -i :80
```

### Security Best Practices

1. **Hide server version:**
   ```nginx
   server_tokens off;
   ```

2. **Enable HTTP/2:**
   ```nginx
   listen 443 ssl http2;
   ```

3. **Strong SSL protocols:**
   ```nginx
   ssl_protocols TLSv1.2 TLSv1.3;
   ssl_prefer_server_ciphers off;
   ```

4. **Security headers:**
   ```nginx
   add_header X-Frame-Options "SAMEORIGIN" always;
   add_header X-Content-Type-Options "nosniff" always;
   add_header X-XSS-Protection "1; mode=block" always;
   ```

5. **Rate limiting:**
   ```nginx
   limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
   limit_req zone=general burst=20 nodelay;
   ```

### Certificate Renewal

acme.sh automatically renews certificates via cron. To manually renew:

```bash
acme.sh --renew -d arpansahu.space -d "*.arpansahu.space" --force
```

Check renewal log:
```bash
cat ~/.acme.sh/arpansahu.space/arpansahu.space.log
```

---

## SSL Certificate Automation & Renewal

**Complete SSL automation is now centralized.** See **[SSL Automation Documentation](../ssl-automation/README.md)** for:

- ✅ Automated renewal (acme.sh + deploy_certs.sh)
- ✅ Nginx certificate deployment
- ✅ Kafka keystore regeneration
- ✅ Kubernetes secret updates
- ✅ MinIO upload for Django projects
- ✅ Complete troubleshooting guide

**Quick verification:**
```bash
# Check certificate expiry
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates

# Test automation
ssh arpansahu@arpansahu.space '~/deploy_certs.sh'
```

---

### Backup Configuration

```bash
# Backup nginx configs
sudo tar -czf nginx-backup-$(date +%Y%m%d).tar.gz \
  /etc/nginx/sites-available/ \
  /etc/nginx/sites-enabled/ \
  /etc/nginx/nginx.conf \
  /etc/nginx/ssl/

# Backup SSL certificates
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz ~/.acme.sh/
```

### Migration to New Server

1. Backup on old server (see above)
2. Install nginx on new server
3. Restore configs
4. Issue new certificates (acme.sh requires DNS validation)
5. Update DNS records to new server IP

### Architecture Diagram

```
Internet (Client)
   │
   ▼
[ Nginx - Port 443 (SSL/TLS Termination) ]
   │
   ├──▶ Harbor (8888)
   ├──▶ RabbitMQ (15672)
   ├──▶ PgAdmin (5050)
   ├──▶ SSH Terminal (8084)
   ├──▶ Jenkins (8080)
   └──▶ Portainer (9443)
```

**Key Points:**
- Nginx handles all SSL/TLS
- Backend services run on localhost (secure)
- Single wildcard certificate covers all subdomains
- Automatic certificate renewal
- Zero downtime reloads

### Configuration Files

- Installation: [`install.sh`](./install.sh)
- SSL setup: [`install-ssl.sh`](./install-ssl.sh)
- Main config: `/etc/nginx/nginx.conf`
- Sites: `/etc/nginx/sites-available/`
- SSL certs: `/etc/nginx/ssl/arpansahu.space/`
- Service configs: See individual service folders

### Performance Tuning

```nginx
# /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;

# Enable gzip
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_types text/plain text/css application/json application/javascript;

# Buffer sizes
client_body_buffer_size 128k;
client_max_body_size 500M;
```

### Monitoring

```bash
# Active connections
sudo ss -s

# Request rate
sudo tail -f /var/log/nginx/access.log | pv -l -i1 -r > /dev/null

# Error rate
sudo grep error /var/log/nginx/error.log | tail -20
```

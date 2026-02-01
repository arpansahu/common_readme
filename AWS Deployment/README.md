# AWS Deployment Guide

Complete guide for deploying services on Ubuntu server with Docker and Nginx.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Server Setup](#initial-server-setup)
- [Service Documentation](#service-documentation)
- [Network Configuration](#network-configuration)
- [SSL/TLS Setup](#ssltls-setup)

## Prerequisites

Before deploying any service:

1. **Ubuntu 22.04 LTS** server
2. **Docker & Docker Compose** installed
3. **Nginx** with SSL/TLS configured
4. **Domain name** configured (*.arpansahu.space)
5. **Let's Encrypt** wildcard certificate

## Initial Server Setup

### 1. Docker Installation

Fix Docker networking first (critical for Indian ISPs):

```bash
sudo nano /etc/docker/daemon.json
```

Add:
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

### 2. Nginx with SSL

Ensure Nginx is installed with SSL module:
```bash
nginx -V 2>&1 | grep ssl
```

## Service Documentation

Each service has its own directory with:
- **README.md** - Complete documentation
- **install.sh** - Automated installation script
- **nginx.conf** - Nginx configuration
- **Additional configs** - Service-specific files

### 🔧 Core Services

| Service | Purpose | Port | Subdomain |
|---------|---------|------|-----------|
| [**RabbitMQ**](./rabbitmq/) | Message broker | 5672, 15672 | rabbitmq.arpansahu.space |
| [**Redis**](./redis/) | In-memory cache | 6380, 9551 | redis.arpansahu.space:9551 |
| [**PostgreSQL**](./postgres/) | Database server | 5432 | postgres.arpansahu.space |
| [**MinIO**](./minio/) | Object storage | 9000, 9002 | minio.arpansahu.space |

### 🎛️ Management Tools

| Service | Purpose | Port | Subdomain |
|---------|---------|------|-----------|
| [**Portainer**](./portainer/) | Docker management | 9443 | portainer.arpansahu.space |
| [**PgAdmin**](./pgadmin/) | PostgreSQL admin | 5050 | pgadmin.arpansahu.space |
| [**Jenkins**](./jenkins/) | CI/CD automation | 8080 | jenkins.arpansahu.space |
| [**Harbor**](./harbor/) | Container registry | 8888 | harbor.arpansahu.space |

### 🌐 Web Access

| Service | Purpose | Port | Subdomain |
|---------|---------|------|-----------|
| [**SSH Web Terminal**](./ssh-web-terminal/) | Browser SSH | 8084 | ssh.arpansahu.space |

### ☁️ Orchestration

| Service | Purpose | Documentation |
|---------|---------|---------------|
| [**Kubernetes**](./kubernetes/) | Container orchestration | See subfolder |
| [**Kafka**](./kafka/) | Event streaming | See subfolder |

## Quick Start

### Example: Install RabbitMQ

```bash
cd rabbitmq
chmod +x install.sh
./install.sh

# Configure Nginx
sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Access at: https://rabbitmq.arpansahu.space

### Example: Install Redis

```bash
cd redis
chmod +x install.sh
REDIS_PASSWORD=mypassword ./install.sh

# Configure Nginx stream
# Add content from nginx-stream.conf to /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl reload nginx
```

Connect: `redis.arpansahu.space:9551`

## Network Configuration

### Port Mapping

**Internal Services (localhost only):**
- Services bind to `127.0.0.1` for security
- Nginx proxies external HTTPS (443) to internal ports
- Only Nginx ports 80/443 are exposed

**Example Flow:**
```
Internet → HTTPS (443) → Nginx → HTTP (15672) → RabbitMQ Container
```

### Firewall Rules

```bash
# Allow HTTP/HTTPS only
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Block direct service access
sudo ufw deny 5672  # RabbitMQ
sudo ufw deny 6380  # Redis
sudo ufw deny 9000  # MinIO
```

## SSL/TLS Setup

### Wildcard Certificate

Using Let's Encrypt with DNS challenge:

```bash
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d *.arpansahu.space \
  -d arpansahu.space
```

**Certificate location:**
```
/etc/nginx/ssl/arpansahu.space/
├── fullchain.pem
└── privkey.pem
```

All Nginx configs reference these files:
```nginx
ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
```

### Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Setup cron job
sudo crontab -e

# Add:
0 3 * * * certbot renew --quiet && systemctl reload nginx
```

## Common Nginx Patterns

### HTTP Server Block

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name service.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://127.0.0.1:PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### TCP Stream Block

```nginx
stream {
    upstream service_upstream {
        server 127.0.0.1:PORT;
    }

    server {
        listen 9551 ssl;
        proxy_pass service_upstream;

        ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
    }
}
```

## Troubleshooting

### Common Issues

**Docker networking problems:**
```bash
# Fix DNS and MTU
sudo nano /etc/docker/daemon.json
# Add dns and mtu settings (see above)
sudo systemctl restart docker
```

**Nginx config conflicts:**
```bash
# Test config
sudo nginx -t

# Find conflicts
sudo nginx -T | grep "server_name yourservice.arpansahu.space"

# Should only show one match
```

**Service not accessible:**
```bash
# Check container
docker ps | grep service-name

# Check ports
sudo ss -lntp | grep PORT

# Check nginx
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```

**Certificate issues:**
```bash
# Check certificate
sudo certbot certificates

# Renew if needed
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

### Useful Commands

```bash
# View all containers
docker ps -a

# View all nginx sites
ls -la /etc/nginx/sites-enabled/

# Check which process uses a port
sudo ss -lntp | grep :PORT

# Test nginx and reload
sudo nginx -t && sudo systemctl reload nginx

# View nginx error log
sudo tail -f /var/log/nginx/error.log

# Check certificate expiry
sudo certbot certificates | grep Expiry
```

## Maintenance

### Backup Strategy

```bash
# Docker volumes
docker volume ls
sudo tar -czf volumes-backup.tar.gz /var/lib/docker/volumes

# Nginx configs
sudo tar -czf nginx-backup.tar.gz /etc/nginx

# SSL certificates
sudo tar -czf ssl-backup.tar.gz /etc/nginx/ssl
```

### Updates

```bash
# Update all containers
docker images | awk '{print $1":"$2}' | tail -n +2 | xargs -L1 docker pull

# Recreate containers (example)
cd service-folder
docker stop service-name
docker rm service-name
./install.sh
```

## Documentation Structure

```
AWS Deployment/
├── README.md (this file)
│
├── rabbitmq/
│   ├── README.md
│   ├── install.sh
│   └── nginx.conf
│
├── redis/
│   ├── README.md
│   ├── install.sh
│   └── nginx-stream.conf
│
├── ssh-web-terminal/
│   ├── README.md
│   ├── install.sh
│   └── nginx.conf
│
└── [other services.../
```

## Contributing

When adding new services:

1. Create service folder: `mkdir service-name/`
2. Add `README.md` with full documentation
3. Create `install.sh` script (make executable)
4. Add `nginx.conf` or `nginx-stream.conf`
5. Update this main README.md

## Support

For issues or questions:
- Check service-specific README
- Review nginx error logs
- Verify Docker container status
- Ensure firewall rules are correct

---

**Last Updated:** February 2026

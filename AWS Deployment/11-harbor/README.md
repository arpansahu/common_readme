# Harbor - Private Container Registry

Harbor is an open source container image registry that secures artifacts with policies and role-based access control, ensures images are scanned and free from vulnerabilities, and signs images as trusted. Harbor extends the Docker Distribution by adding the functionalities usually required by users such as security, identity and management.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Installation](#installation)
- [Nginx Configuration](#nginx-configuration)
- [Router Configuration](#router-configuration)
- [Docker Usage](#docker-usage)
- [Project Management](#project-management)
- [Vulnerability Scanning](#vulnerability-scanning)
- [Image Replication](#image-replication)
- [Robot Accounts](#robot-accounts)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Ubuntu Server (22.04 or higher)
- Docker Engine (20.10+) and Docker Compose (v2.0+)
- At least 2 CPU cores and 4GB RAM
- Nginx with SSL certificate for reverse proxy
- Domain name pointing to your server (e.g., `harbor.arpansahu.space`)

## Quick Start

```bash
# 1. Copy the Harbor directory to your server
scp -r harbor/ user@your-server:"AWS Deployment/"

# 2. Create .env file from example
cd "AWS Deployment/harbor"
cp .env.example .env

# 3. Edit .env with your configuration
nano .env

# 4. Run installation
chmod +x install.sh add-nginx-config.sh
./install.sh

# 5. Configure nginx
sudo ./add-nginx-config.sh

# 6. Access Harbor
# - Local: http://localhost:8888
# - HTTPS: https://harbor.yourdomain.com
# - Username: admin
# - Password: (from .env)
```

## Configuration

### Environment Variables (.env)

Create a `.env` file from `.env.example`:

```bash
# Harbor hostname (domain or IP)
HARBOR_HOSTNAME=harbor.arpansahu.space

# Harbor HTTP port (default: 8888, accessible only on localhost)
HARBOR_HTTP_PORT=8888

# Harbor admin password
HARBOR_ADMIN_PASSWORD=your-secure-password

# Harbor database password
HARBOR_DB_PASSWORD=your-db-password

# Harbor data volume location
HARBOR_DATA_VOLUME=/data

# Harbor version
HARBOR_VERSION=v2.11.0
```

### Important Notes

1. **Port Configuration**: Harbor runs on port 8888 (localhost only) and is proxied through nginx on port 443 (HTTPS)
2. **Data Persistence**: All Harbor data is stored in `/data` by default (configurable via `HARBOR_DATA_VOLUME`)
3. **HTTPS Only**: External access should always use HTTPS through nginx reverse proxy
4. **Passwords**: Use strong passwords for both admin and database

## Installation

### Using install.sh (Recommended)

The `install.sh` script automates the entire installation process:

```bash
# Make scripts executable
chmod +x install.sh add-nginx-config.sh

# Run installation
./install.sh
```

The script will:
1. Load configuration from `.env`
2. Download Harbor v2.11.0 (if not already downloaded)
3. Extract Harbor to `~/harbor`
4. Configure `harbor.yml` with your settings
5. Run Harbor's installation script
6. Start all Harbor services

### Manual Installation

If you prefer manual installation:

```bash
# 1. Download Harbor
cd /tmp
wget https://github.com/goharbor/harbor/releases/download/v2.11.0/harbor-offline-installer-v2.11.0.tgz

# 2. Extract
tar xzf harbor-offline-installer-v2.11.0.tgz
mv harbor ~/harbor

# 3. Configure
cd ~/harbor
cp harbor.yml.tmpl harbor.yml
nano harbor.yml  # Edit configuration

# 4. Install
sudo ./install.sh

# 5. Verify
docker compose ps
```

## Nginx Configuration

### Using add-nginx-config.sh (Recommended)

The `add-nginx-config.sh` script automatically configures nginx:

```bash
sudo ./add-nginx-config.sh
```

The script will:
1. Backup existing nginx configuration
2. Add Harbor server block to `/etc/nginx/sites-available/services`
3. Configure large file uploads (1024M) for Docker images
4. Set up WebSocket support
5. Configure appropriate timeouts (300s)
6. Test and reload nginx
7. Verify Harbor accessibility

### Manual Nginx Configuration

Add this configuration to `/etc/nginx/sites-available/services`:

```nginx
# Harbor - Container Registry
server {
    listen 80;
    listen [::]:80;
    server_name harbor.arpansahu.space;
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name harbor.arpansahu.space;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/arpansahu.space/privkey.pem;

    # Large file uploads for Docker images
    client_max_body_size 1024M;
    client_body_buffer_size 128k;

    # Timeouts
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    send_timeout 300;

    location / {
        proxy_pass http://localhost:8888;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Buffering settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
```

Test and reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Router Configuration

To access Harbor from outside your network, configure port forwarding on your router:

### Port Forwarding Rules

| Service | External Port | Internal IP | Internal Port | Protocol |
|---------|--------------|-------------|---------------|----------|
| Harbor (HTTPS) | 443 | 192.168.1.200 | 443 | TCP |

### Airtel Router Example

1. Login to router admin panel: `http://192.168.1.1`
2. Navigate to: **Advanced** → **NAT** → **Port Mapping**
3. Click **Add** and configure:
   - **Name**: Harbor HTTPS
   - **External Port**: 443
   - **Internal IP**: 192.168.1.200 (your server IP)
   - **Internal Port**: 443
   - **Protocol**: TCP
4. Click **Apply**
5. Test external access: `https://harbor.yourdomain.com`

## Docker Usage

### Login to Harbor

```bash
# Login
docker login harbor.arpansahu.space -u admin
# Enter password when prompted

# Or use password from command
echo 'your-password' | docker login harbor.arpansahu.space -u admin --password-stdin
```

### Pushing Images

```bash
# Tag your image
docker tag myapp:latest harbor.arpansahu.space/myproject/myapp:latest

# Push to Harbor
docker push harbor.arpansahu.space/myproject/myapp:latest
```

### Pulling Images

```bash
# Pull from Harbor
docker pull harbor.arpansahu.space/myproject/myapp:latest

# Run container
docker run -d harbor.arpansahu.space/myproject/myapp:latest
```

### Working with Private Projects

For private projects, you need to login first:

```bash
# Login with project-specific credentials
docker login harbor.arpansahu.space -u username

# Pull private image
docker pull harbor.arpansahu.space/privateproject/app:v1.0
```

## Project Management

### Creating Projects

1. Login to Harbor web UI: `https://harbor.arpansahu.space`
2. Click **New Project**
3. Configure:
   - **Project Name**: e.g., `production`
   - **Access Level**: Public or Private
   - **Storage Quota**: Set limit or leave unlimited
   - **Proxy Cache**: Optional, for caching Docker Hub images
4. Click **OK**

### Project Access Levels

- **Public**: Anyone can pull images (login not required)
- **Private**: Only project members can pull/push images

### Adding Members

1. Go to **Projects** → Select project → **Members**
2. Click **+ User**
3. Select user and assign role:
   - **Project Admin**: Full control over the project
   - **Maintainer**: Manage images, artifacts, and helm charts
   - **Developer**: Push/pull images, cannot delete or modify project settings
   - **Guest**: Pull images only (read-only)
4. Click **OK**

### Creating Users

1. Go to **Administration** → **Users**
2. Click **+ New User**
3. Fill in details:
   - Username
   - Email
   - Full Name
   - Password
   - Comments (optional)
4. Click **OK**

## Vulnerability Scanning

Harbor includes Trivy scanner for vulnerability scanning.

### Enable Automatic Scanning

1. Go to **Projects** → Select project → **Configuration**
2. Enable **Automatically scan images on push**
3. Set **Prevent vulnerable images from running**:
   - None
   - Low
   - Medium
   - High
   - Critical
4. Click **Save**

### Manual Scan

1. Go to **Projects** → Select project → **Repositories**
2. Click on a repository → Select artifact
3. Click **Scan** button
4. View results in **Vulnerabilities** tab

### View Scan Results

```bash
# Scan results show:
- Total vulnerabilities
- Severity breakdown (Critical, High, Medium, Low)
- CVE details
- Fixed versions
- CVSS scores
```

### Export Scan Results

1. Click on an artifact
2. Go to **Vulnerabilities** tab
3. Click **Export** → Choose format (CSV, JSON)

## Image Replication

Replicate images between Harbor instances or from Docker Hub.

### Setting Up Replication

1. Go to **Administration** → **Registries**
2. Click **+ New Endpoint**
3. Configure remote registry:
   - **Provider**: Docker Hub, Harbor, etc.
   - **Name**: e.g., `DockerHub`
   - **Endpoint URL**: `https://hub.docker.com`
   - **Credentials**: Username and password/token
4. Click **Test Connection** → **OK**

### Creating Replication Rule

1. Go to **Administration** → **Replications**
2. Click **+ New Replication Rule**
3. Configure:
   - **Name**: e.g., `Replicate nginx from DockerHub`
   - **Replication mode**: Push or Pull
   - **Source registry**: Select registry
   - **Source resource filter**: e.g., `nginx/**`
   - **Destination**: Select project
   - **Trigger Mode**: Manual, Scheduled, or Event Based
4. Click **Save**

### Manual Replication

1. Go to **Administration** → **Replications**
2. Select rule → Click **Replicate**
3. Monitor progress in **Executions** tab

## Robot Accounts

Robot accounts are used for automated CI/CD pipelines.

### Creating Robot Account

1. Go to **Projects** → Select project → **Robot Accounts**
2. Click **+ New Robot Account**
3. Configure:
   - **Name**: e.g., `ci-pipeline`
   - **Expiration time**: 30 days, 90 days, never, etc.
   - **Description**: Purpose of the account
   - **Permissions**: Select repositories and access level
4. Click **Add**
5. **Important**: Copy the token immediately (shown only once)

### Using Robot Account in CI/CD

```bash
# In GitLab CI, GitHub Actions, etc.
docker login harbor.arpansahu.space -u 'robot$ci-pipeline' -p 'token-here'
docker push harbor.arpansahu.space/project/app:$CI_COMMIT_SHA
```

### Example GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - docker login harbor.arpansahu.space -u "$HARBOR_ROBOT_USER" -p "$HARBOR_ROBOT_TOKEN"
    - docker build -t harbor.arpansahu.space/myproject/app:$CI_COMMIT_SHA .
    - docker push harbor.arpansahu.space/myproject/app:$CI_COMMIT_SHA
```

## Troubleshooting

### Harbor Not Accessible

```bash
# Check if containers are running
cd ~/harbor
docker compose ps

# Check specific container logs
docker compose logs nginx
docker compose logs harbor-core

# Restart services
docker compose restart

# Full restart
docker compose down
docker compose up -d
```

### Nginx 502 Bad Gateway

```bash
# Check if Harbor is running
curl http://localhost:8888

# Check nginx configuration
sudo nginx -t

# Check nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx
```

### Login Failed

```bash
# Check admin password in harbor.yml
cd ~/harbor
grep harbor_admin_password harbor.yml

# Reset admin password (requires restart)
docker compose down
# Edit harbor.yml, change password
docker compose up -d
```

### Push/Pull Failures

```bash
# Check disk space
df -h

# Check Harbor quota
# Go to Projects → Select project → Summary → Check storage

# Check Docker daemon logs
sudo journalctl -u docker -n 50

# Verify login
docker login harbor.arpansahu.space -u admin

# Test with verbose output
docker push harbor.arpansahu.space/test/nginx:latest --debug
```

### Large Image Upload Fails

```bash
# Increase nginx upload limit (already set to 1024M)
sudo nano /etc/nginx/sites-available/services
# Verify: client_max_body_size 1024M;

# Check Harbor configuration
cd ~/harbor
grep upload_size harbor.yml

# Restart services
sudo systemctl reload nginx
docker compose restart
```

### Certificate Errors

```bash
# Verify SSL certificate
openssl s_client -connect harbor.arpansahu.space:443 -servername harbor.arpansahu.space

# Check certificate expiry
echo | openssl s_client -connect harbor.arpansahu.space:443 2>/dev/null | openssl x509 -noout -dates

# Renew Let's Encrypt certificate
sudo certbot renew
sudo systemctl reload nginx
```

### Database Issues

```bash
# Check database container
docker compose logs harbor-db

# Backup database
docker exec harbor-db pg_dump -U postgres registry > harbor-backup.sql

# Restore database
cat harbor-backup.sql | docker exec -i harbor-db psql -U postgres registry
```

### Clear Harbor Data (WARNING: Deletes everything)

```bash
cd ~/harbor
docker compose down -v
sudo rm -rf /data/*
docker compose up -d
# Reconfigure admin password and projects
```

### Check Harbor Health

```bash
# Health check endpoint
curl -k https://harbor.arpansahu.space/api/v2.0/health

# Expected output:
# {
#   "status": "healthy",
#   "components": [
#     {"name": "core", "status": "healthy"},
#     {"name": "database", "status": "healthy"},
#     ...
#   ]
# }
```

### Performance Tuning

```bash
# Increase worker processes (harbor.yml)
cd ~/harbor
nano harbor.yml
# jobservice:
#   max_job_workers: 10

# Restart services
docker compose down
docker compose up -d
```

### Garbage Collection

Free up storage by removing unreferenced blobs:

1. Go to **Administration** → **Clean Up**
2. Click **GC Now** or **Schedule GC**
3. Select options:
   - **Delete untagged artifacts**: Remove artifacts without tags
   - **Delete unreferenced blobs**: Remove unused data
4. Click **Save** or **Run Now**

### View Logs

```bash
# All logs
cd ~/harbor
docker compose logs -f

# Specific service
docker compose logs -f harbor-core
docker compose logs -f nginx
docker compose logs -f harbor-jobservice

# Last 100 lines
docker compose logs --tail=100
```

### Backup Harbor

```bash
#!/bin/bash
# backup-harbor.sh

BACKUP_DIR="/backup/harbor/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup database
docker exec harbor-db pg_dump -U postgres registry > "$BACKUP_DIR/database.sql"

# Backup configuration
cp ~/harbor/harbor.yml "$BACKUP_DIR/"
cp -r ~/harbor/common "$BACKUP_DIR/" 2>/dev/null || true

# Backup registry data
sudo tar czf "$BACKUP_DIR/data.tar.gz" /data

echo "Backup completed: $BACKUP_DIR"
```

### Restore Harbor

```bash
#!/bin/bash
# restore-harbor.sh

BACKUP_DIR="/backup/harbor/20260201_093000"

# Stop Harbor
cd ~/harbor
docker compose down

# Restore database
cat "$BACKUP_DIR/database.sql" | docker exec -i harbor-db psql -U postgres registry

# Restore configuration
cp "$BACKUP_DIR/harbor.yml" ~/harbor/

# Restore data
sudo tar xzf "$BACKUP_DIR/data.tar.gz" -C /

# Start Harbor
docker compose up -d

echo "Restore completed"
```

---

## Additional Resources

- [Official Harbor Documentation](https://goharbor.io/docs/)
- [Harbor GitHub Repository](https://github.com/goharbor/harbor)
- [Harbor REST API](https://goharbor.io/docs/latest/build-customize-contribute/configure-swagger/)
- [Trivy Scanner Documentation](https://aquasecurity.github.io/trivy/)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review Harbor logs: `docker compose logs`
3. Visit [Harbor GitHub Issues](https://github.com/goharbor/harbor/issues)
4. Check [Harbor Community](https://goharbor.io/community/)

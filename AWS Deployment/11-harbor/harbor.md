## Harbor (Self-Hosted Private Docker Registry)

Harbor is an open-source container image registry that secures images with role-based access control, scans images for vulnerabilities, and signs images as trusted. It extends Docker Distribution by adding enterprise features like security, identity management, and image replication. This guide provides a complete, production-ready setup with Nginx reverse proxy.

### Prerequisites

Before installing Harbor, ensure you have:

1. Ubuntu Server 22.04 LTS
2. Docker Engine installed (see docker_installation.md)
3. Nginx with SSL certificates configured
4. Domain name (example: harbor.arpansahu.space)
5. Wildcard SSL certificate already issued (via acme.sh)
6. Minimum 4GB RAM, 40GB disk space
7. Root or sudo access

### Architecture Overview

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │
        └─ harbor.arpansahu.space
             │
             └─ Harbor Internal Nginx (localhost:8080)
                  │
                  ├─ Harbor Core
                  ├─ Harbor Registry
                  ├─ Harbor Portal (Web UI)
                  ├─ Trivy (Vulnerability Scanner)
                  ├─ Notary (Image Signing)
                  └─ ChartMuseum (Helm Charts)
```

Key Principles:
- Harbor runs on localhost only
- System Nginx handles all external TLS
- Harbor has its own internal Nginx
- All data persisted in Docker volumes
- Automatic restart via systemd

### Why Harbor

**Advantages:**
- Role-based access control (RBAC)
- Vulnerability scanning with Trivy
- Image signing and trust (Notary)
- Helm chart repository
- Image replication
- Garbage collection
- Web UI for management
- Docker Hub proxy cache

**Use Cases:**
- Private Docker registry for organization
- Secure image storage
- Vulnerability assessment
- Compliance and auditing
- Multi-project isolation
- Image lifecycle management

### Part 1: Download and Extract Harbor

1. Download latest Harbor release

    ```bash
    cd /opt
    sudo wget https://github.com/goharbor/harbor/releases/download/v2.11.0/harbor-offline-installer-v2.11.0.tgz
    ```

    Check for latest version at: https://github.com/goharbor/harbor/releases

2. Extract Harbor installer

    ```bash
    sudo tar -xzvf harbor-offline-installer-v2.11.0.tgz
    cd harbor
    ```

3. Verify extracted files

    ```bash
    ls -la
    ```

    Expected files:
    - harbor.yml.tmpl
    - install.sh
    - prepare
    - common.sh
    - harbor.*.tar.gz (images)

### Part 2: Configure Harbor

1. Copy template configuration

    ```bash
    sudo cp harbor.yml.tmpl harbor.yml
    ```

2. Edit Harbor configuration

    ```bash
    sudo nano harbor.yml
    ```

3. Configure essential settings

    Find and modify these lines:

    ```yaml
    # Hostname for Harbor
    hostname: harbor.arpansahu.space

    # HTTP settings (used for internal communication)
    http:
      port: 8080

    # HTTPS settings (disabled - Nginx handles this)
    # Comment out or remove the https section completely
    # https:
    #   port: 443
    #   certificate: /path/to/cert
    #   private_key: /path/to/key

    # Harbor admin password
    harbor_admin_password: YourStrongPasswordHere

    # Database settings (PostgreSQL)
    database:
      password: ChangeDatabasePassword
      max_idle_conns: 100
      max_open_conns: 900

    # Data volume location
    data_volume: /data

    # Trivy (vulnerability scanner)
    trivy:
      ignore_unfixed: false
      skip_update: false
      offline_scan: false
      insecure: false

    # Job service
    jobservice:
      max_job_workers: 10

    # Notification webhook job
    notification:
      webhook_job_max_retry: 3

    # Log settings
    log:
      level: info
      local:
        rotate_count: 50
        rotate_size: 200M
        location: /var/log/harbor
    ```

    Important changes:
    - Set `hostname` to your domain
    - Set `http.port` to 8080 (internal)
    - Comment out entire `https` section
    - Change `harbor_admin_password`
    - Change `database.password`
    - Keep `data_volume: /data` for persistence

4. Save and exit

    In nano: `Ctrl + O`, `Enter`, `Ctrl + X`

### Part 3: Install Harbor

1. Run Harbor installer with all components

    ```bash
    sudo ./install.sh --with-notary --with-trivy --with-chartmuseum
    ```

    This will:
    - Load Harbor Docker images
    - Generate docker-compose.yml
    - Create necessary directories
    - Start all Harbor services

    Installation takes 5-10 minutes depending on system.

2. Verify installation

    ```bash
    sudo docker compose ps
    ```

    Expected services (all should be "Up"):
    - harbor-core
    - harbor-db (PostgreSQL)
    - harbor-jobservice
    - harbor-log
    - harbor-portal (Web UI)
    - nginx (Harbor's internal)
    - redis
    - registry
    - registryctl
    - trivy-adapter
    - notary-server
    - notary-signer
    - chartmuseum

3. Check Harbor logs

    ```bash
    sudo docker compose logs -f
    ```

    Press `Ctrl + C` to exit logs.

### Part 4: Configure System Nginx

1. Edit Nginx configuration

    ```bash
    sudo nano /etc/nginx/sites-available/services
    ```

2. Add Harbor server block

    ```nginx
    # Harbor Registry - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name harbor.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # Harbor Registry - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name harbor.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
            # Allow large image uploads (2GB recommended, 0 for unlimited)
            # Note: Set to at least 2G for typical Docker images
            client_max_body_size 2G;
            
            proxy_pass http://127.0.0.1:8080;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Timeouts for large image pushes
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 300;
        }
    }
    ```

3. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

4. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Part 5: Configure Auto-Start with Systemd

Harbor needs to start automatically after reboot. Docker Compose alone doesn't provide this.

1. Create systemd service file

    ```bash
    sudo nano /etc/systemd/system/harbor.service
    ```

2. Add service configuration

    ```bash
    [Unit]
    Description=Harbor Container Registry
    After=docker.service
    Requires=docker.service

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    WorkingDirectory=/opt/harbor
    ExecStart=/usr/bin/docker compose up -d
    ExecStop=/usr/bin/docker compose down
    Restart=on-failure
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    ```

3. Reload systemd daemon

    ```bash
    sudo systemctl daemon-reload
    ```

4. Enable Harbor service

    ```bash
    sudo systemctl enable harbor
    ```

5. Verify service status

    ```bash
    sudo systemctl status harbor
    ```

    Expected: Loaded and active

### Part 6: Configure Firewall and Port Forwarding

1. Configure UFW firewall

    ```bash
    # Allow HTTP/HTTPS (if not already allowed)
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp

    # Block direct access to Harbor port
    sudo ufw deny 8080/tcp

    # Reload firewall
    sudo ufw reload
    ```

2. Configure router port forwarding

    Access router admin: https://airtel.arpansahu.space (or http://192.168.1.1:81)

    Add port forwarding rules:

    | Service | External Port | Internal IP | Internal Port | Protocol |
    | ------- | ------------- | ----------- | ------------- | -------- |
    | Harbor HTTP | 80 | 192.168.1.200 | 80 | TCP |
    | Harbor HTTPS | 443 | 192.168.1.200 | 443 | TCP |

    Note: Do NOT forward port 8080 (Harbor internal port).

### Part 7: Test Harbor Installation

1. Check all containers are running

    ```bash
    sudo docker compose ps
    ```

    All should show "Up" status.

2. Test local access

    ```bash
    curl -I http://127.0.0.1:8080
    ```

    Expected: HTTP 200 or 301

3. Test external HTTPS access

    ```bash
    curl -I https://harbor.arpansahu.space
    ```

    Expected: HTTP 200

4. Access Harbor Web UI

    Go to: https://harbor.arpansahu.space

5. Login with admin credentials

    - Username: `admin`
    - Password: (from harbor.yml harbor_admin_password)

### Part 8: Initial Harbor Configuration

1. Change admin password

    - Click admin (top right) → Change Password
    - Set strong password
    - Save

2. Create project

    - Go to: Projects → New Project
    - Project Name: `library` (default) or custom name
    - Access Level: Private (recommended)
    - Click: OK

3. Create robot account for CI/CD

    - Go to: Projects → library → Robot Accounts
    - Click: New Robot Account
    - Name: `ci-bot`
    - Expiration: Never (or set expiry)
    - Permissions: Push Artifact, Pull Artifact
    - Click: Add
    - Save token securely (shown only once)

### Part 9: Using Harbor as Docker Registry

#### Login to Harbor

1. Login from Docker client

    ```bash
    docker login harbor.arpansahu.space
    ```

    Enter:
    - Username: `admin` (or your username)
    - Password: (your Harbor password)

    Expected: Login Succeeded

2. Login with robot account (for CI/CD)

    ```bash
    docker login harbor.arpansahu.space -u robot$ci-bot -p YOUR_ROBOT_TOKEN
    ```

#### Push Images to Harbor

1. Tag existing image

    ```bash
    docker tag nginx:latest harbor.arpansahu.space/library/nginx:latest
    ```

    Format: `harbor.domain.com/project/image:tag`

2. Push image to Harbor

    ```bash
    docker push harbor.arpansahu.space/library/nginx:latest
    ```

3. Verify in Harbor UI

    - Go to: Projects → library → Repositories
    - You should see: nginx repository

#### Pull Images from Harbor

1. Pull image from Harbor

    ```bash
    docker pull harbor.arpansahu.space/library/nginx:latest
    ```

2. Use in docker-compose.yml

    ```yaml
    services:
      web:
        image: harbor.arpansahu.space/library/nginx:latest
    ```

### Part 10: Configure Image Retention Policy

Retention policies automatically delete old images to save space.

1. Navigate to project

    - Projects → library → Policy

2. Add retention rule

    Click: Add Rule

    Configure:
    - **Repositories**: matching `**` (all repositories)
    - **By artifact count**: Retain the most recently pulled `3` artifacts
    - **Tags**: matching `**` (all tags)
    - **Untagged artifacts**: ✓ Checked (delete untagged)

    This keeps last 3 pulled images and deletes others.

    ![Add Retention Rule](https://github.com/arpansahu/common_readme/blob/main/AWS%20Deployment/harbor/retention_rule_add.png)

3. Schedule retention policy

    Click: Add Retention Rule → Schedule

    Configure schedule:
    - **Type**: Daily / Weekly / Monthly
    - **Time**: 02:00 AM (off-peak)
    - **Cron**: `0 2 * * *` (2 AM daily)

    Click: Save

    ![Retention Rule Schedule](https://github.com/arpansahu/common_readme/blob/main/AWS%20Deployment/harbor/retention_rule_schedule.png)

4. Test retention policy

    Click: Dry Run

    This shows what would be deleted without actually deleting.

### Part 11: Enable Vulnerability Scanning

Harbor uses Trivy to scan images for vulnerabilities.

1. Configure automatic scanning

    - Go to: Projects → library → Configuration
    - Enable: Automatically scan images on push
    - Click: Save

2. Manual scan existing image

    - Go to: Projects → library → Repositories → nginx
    - Select tag: latest
    - Click: Scan

3. View scan results

    - Click on tag
    - View: Vulnerabilities tab
    - See: Critical, High, Medium, Low vulnerabilities

4. Set CVE allowlist (optional)

    - Go to: Projects → library → Configuration
    - Add CVE IDs to allow despite vulnerabilities
    - Use for false positives or accepted risks

### Managing Harbor Service

1. Check Harbor status

    ```bash
    sudo systemctl status harbor
    ```

2. Stop Harbor

    ```bash
    sudo systemctl stop harbor
    ```

    or

    ```bash
    cd /opt/harbor
    sudo docker compose down
    ```

3. Start Harbor

    ```bash
    sudo systemctl start harbor
    ```

    or

    ```bash
    cd /opt/harbor
    sudo docker compose up -d
    ```

4. Restart Harbor

    ```bash
    sudo systemctl restart harbor
    ```

5. View Harbor logs

    ```bash
    cd /opt/harbor
    sudo docker compose logs -f
    ```

6. View specific service logs

    ```bash
    sudo docker compose logs -f harbor-core
    ```

### Backup and Restore

1. Backup Harbor data

    ```bash
    # Stop Harbor
    sudo systemctl stop harbor

    # Backup data directory
    sudo tar -czf harbor-data-backup-$(date +%Y%m%d).tar.gz /data

    # Backup configuration
    sudo cp /opt/harbor/harbor.yml /backup/harbor-config-$(date +%Y%m%d).yml

    # Backup database
    sudo docker exec harbor-db pg_dumpall -U postgres > harbor-db-backup-$(date +%Y%m%d).sql

    # Start Harbor
    sudo systemctl start harbor
    ```

2. Restore Harbor data

    ```bash
    # Stop Harbor
    sudo systemctl stop harbor

    # Restore data directory
    sudo tar -xzf harbor-data-backup-YYYYMMDD.tar.gz -C /

    # Restore configuration
    sudo cp /backup/harbor-config-YYYYMMDD.yml /opt/harbor/harbor.yml

    # Restore database
    sudo docker exec -i harbor-db psql -U postgres < harbor-db-backup-YYYYMMDD.sql

    # Start Harbor
    sudo systemctl start harbor
    ```

### Common Issues and Fixes

1. Harbor containers not starting

    Cause: Port conflict or insufficient resources

    Fix:

    ```bash
    # Check if port 8080 is in use
    sudo ss -tulnp | grep 8080

    # Check Docker logs
    cd /opt/harbor
    sudo docker compose logs

    # Check system resources
    free -h
    df -h
    ```

2. Cannot login to Harbor

    Cause: Wrong credentials or database issue

    Fix:

    - Verify admin password in harbor.yml
    - Reset admin password:
      ```bash
      cd /opt/harbor
      sudo docker compose exec harbor-core harbor-core password-reset
      ```

3. Image push fails

    Cause: Storage full or permission issues

    Fix:

    ```bash
    # Check disk space
    df -h /data

    # Check Harbor logs
    sudo docker compose logs -f registry

    # Check data directory permissions
    sudo ls -la /data
    ```

4. SSL certificate errors

    Cause: Nginx certificate misconfigured

    Fix:

    ```bash
    # Verify certificate
    openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates

    # Check Nginx configuration
    sudo nginx -t

    # Reload Nginx
    sudo systemctl reload nginx
    ```

5. Vulnerability scanning not working

    Cause: Trivy adapter not running or internet connectivity

    Fix:

    ```bash
    # Check Trivy adapter
    sudo docker compose ps trivy-adapter

    # Check Trivy logs
    sudo docker compose logs trivy-adapter

    # Update Trivy database manually
    sudo docker compose exec trivy-adapter /home/scanner/trivy --download-db-only
    ```

### Security Best Practices

1. Use strong passwords

    - Admin password: minimum 16 characters
    - Database password: minimum 16 characters
    - Robot account tokens: treat as secrets

2. Enable HTTPS only

    - Never use HTTP for Harbor
    - Always proxy through Nginx with TLS

3. Implement RBAC

    - Create projects with limited access
    - Use robot accounts for automation
    - Assign minimal required permissions

4. Enable vulnerability scanning

    - Automatically scan on push
    - Set CVE severity thresholds
    - Block deployment of vulnerable images

5. Configure image retention

    - Automatically delete old images
    - Keep only necessary image versions
    - Schedule during off-peak hours

6. Regular backups

    ```bash
    # Automate with cron
    sudo crontab -e
    ```

    Add:
    ```bash
    0 2 * * * /usr/local/bin/backup-harbor.sh
    ```

7. Monitor logs

    ```bash
    # Regular log review
    sudo docker compose logs --since 24h | grep ERROR
    ```

### Performance Optimization

1. Configure garbage collection

    - Go to: Administration → Garbage Collection
    - Schedule: Weekly at 2 AM
    - This removes unreferenced image layers

2. Optimize database

    ```bash
    # Run vacuum on PostgreSQL
    sudo docker compose exec harbor-db vacuumdb -U postgres -d registry
    ```

3. Configure resource limits

    Edit docker-compose.yml (auto-generated):

    ```yaml
    services:
      registry:
        deploy:
          resources:
            limits:
              memory: 2G
            reservations:
              memory: 512M
    ```

4. Enable Redis cache

    Harbor uses Redis by default for caching.
    Increase Redis memory if needed.

### Monitoring Harbor

1. Check Harbor health

    ```bash
    curl -k https://harbor.arpansahu.space/api/v2.0/health
    ```

2. Monitor Docker resources

    ```bash
    sudo docker stats
    ```

3. Check disk usage

    ```bash
    du -sh /data/*
    ```

4. View system logs

    ```bash
    sudo journalctl -u harbor -f
    ```

### Updating Harbor

1. Backup current installation

    Follow backup procedure above.

2. Download new Harbor version

    ```bash
    cd /opt
    sudo wget https://github.com/goharbor/harbor/releases/download/vX.Y.Z/harbor-offline-installer-vX.Y.Z.tgz
    ```

3. Stop current Harbor

    ```bash
    sudo systemctl stop harbor
    ```

4. Extract new version

    ```bash
    sudo tar -xzvf harbor-offline-installer-vX.Y.Z.tgz
    sudo mv harbor harbor-old
    sudo mv harbor-new harbor
    ```

5. Copy configuration

    ```bash
    sudo cp harbor-old/harbor.yml harbor/harbor.yml
    ```

6. Run migration

    ```bash
    cd /opt/harbor
    sudo ./install.sh --with-notary --with-trivy --with-chartmuseum
    ```

7. Start Harbor

    ```bash
    sudo systemctl start harbor
    ```

### Final Verification Checklist

Run these commands to verify Harbor is working:

```bash
# Check all containers
sudo docker compose ps

# Check systemd service
sudo systemctl status harbor

# Check local access
curl -I http://127.0.0.1:8080

# Check HTTPS access
curl -I https://harbor.arpansahu.space

# Check Nginx config
sudo nginx -t

# Check firewall
sudo ufw status | grep -E '(80|443)'

# Test Docker login
docker login harbor.arpansahu.space
```

Then test in browser:
- Access: https://harbor.arpansahu.space
- Login with admin credentials
- Create test project
- Push test image
- Scan image for vulnerabilities
- Verify retention policy configured

### What This Setup Provides

After following this guide, you will have:

1. Self-hosted private Docker registry
2. HTTPS access via Nginx reverse proxy
3. Automatic startup with systemd
4. Vulnerability scanning with Trivy
5. Image signing with Notary
6. Helm chart repository
7. Automatic image retention
8. Web UI for management
9. Robot accounts for CI/CD
10. Production-ready configuration

### Example Configuration Summary

| Component | Value |
| --------- | ----- |
| Harbor URL | https://harbor.arpansahu.space |
| Internal Port | 8080 (localhost only) |
| Admin User | admin |
| Default Project | library |
| Data Directory | /data |
| Config File | /opt/harbor/harbor.yml |
| Service File | /etc/systemd/system/harbor.service |

### Architecture Summary

```
Internet (HTTPS)
   │
   └─ Nginx (TLS Termination)
        │ [Wildcard Certificate: *.arpansahu.space]
        │
        └─ harbor.arpansahu.space (Port 443 → 8080)
             │
             └─ Harbor Stack (Docker Compose)
                  ├─ Harbor Core (API + Logic)
                  ├─ Harbor Portal (Web UI)
                  ├─ Registry (Image Storage)
                  ├─ PostgreSQL (Metadata)
                  ├─ Redis (Cache)
                  ├─ Trivy (Vulnerability Scanner)
                  ├─ Notary (Image Signing)
                  └─ ChartMuseum (Helm Charts)
```

### Key Rules to Remember

1. Harbor internal port (8080) never exposed externally
2. System Nginx handles all TLS termination
3. Use systemd for automatic startup
4. Robot accounts for CI/CD pipelines
5. Configure retention to manage storage
6. Enable vulnerability scanning on push
7. Regular backups of /data directory
8. Monitor disk usage in /data
9. Use RBAC for multi-tenant access
10. Keep Harbor updated

### Troubleshooting

#### 1. 413 Request Entity Too Large Error

**Symptom:** Docker push fails with `413 Request Entity Too Large` when pushing large images.

**Cause:** Nginx `client_max_body_size` limit is too small (default is 1MB).

**Solution:**

1. Edit system nginx configuration:
   ```bash
   sudo nano /etc/nginx/sites-available/services
   ```

2. Find the Harbor location block and add/update:
   ```nginx
   location / {
       client_max_body_size 2G;  # Adjust as needed
       proxy_pass http://127.0.0.1:8080;
       # ... rest of config
   }
   ```

3. Test and reload nginx:
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

**Note:** Harbor's internal nginx is already set to `client_max_body_size 0;` (unlimited), so you only need to fix the external nginx.

#### 2. Cannot Connect to Harbor

**Check these:**
```bash
# 1. Is Harbor running?
sudo systemctl status harbor
docker ps | grep harbor

# 2. Is nginx running?
sudo systemctl status nginx

# 3. Check logs
sudo journalctl -u harbor -n 50
docker logs nginx
```

#### 3. Login Issues

```bash
# Reset admin password
cd /opt/harbor
sudo docker-compose stop
sudo ./prepare
sudo docker-compose up -d
```

#### 4. Disk Space Full

```bash
# Check disk usage
df -h /data

# Run garbage collection
docker exec harbor-core harbor-gc

# Or via UI: Administration → Garbage Collection → Run Now
```

#### 5. Slow Image Pushes

Check nginx configuration for these settings:
```nginx
proxy_buffering off;
proxy_request_buffering off;
proxy_connect_timeout 300;
proxy_send_timeout 300;
proxy_read_timeout 300;
```

### Next Steps

After setting up Harbor:

1. Create projects for different teams
2. Configure robot accounts for CI/CD
3. Set up vulnerability scan policies
4. Configure image retention rules
5. Enable garbage collection
6. Set up replication (if multi-site)
7. Integrate with CI/CD pipelines

My Harbor instance: https://harbor.arpansahu.space

For CI/CD integration, see Jenkins documentation.

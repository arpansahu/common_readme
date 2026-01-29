## MinIO

MinIO is a high-performance, distributed object storage system designed for large-scale data infrastructures. It is open-source and compatible with the Amazon S3 API, making it ideal for self-hosted cloud storage. This guide provides a complete, production-ready setup using systemd, Nginx reverse proxy with HTTPS, and automatic certificate renewal.

### Prerequisites

Before installing MinIO, ensure you have:

1. Ubuntu Server (20.04 / 22.04 recommended)
2. Nginx already installed with SSL certificates configured
3. Root or sudo access
4. Domain name configured (example: arpansahu.space)
5. Wildcard SSL certificate already issued (via acme.sh)
6. Firewall configured to allow HTTP/HTTPS traffic

### Architecture Overview

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │
        ├─ minio.arpansahu.space → MinIO API (localhost:9000)
        └─ console.arpansahu.space → MinIO Console (localhost:9001)
```

Key Principles:
- MinIO runs HTTP-only on localhost
- Nginx handles all TLS/SSL termination
- API and Console on separate subdomains
- Systemd manages MinIO service
- Uses existing wildcard certificate

### Installing MinIO

1. Download MinIO server binary

    ```bash
    wget https://dl.min.io/server/minio/release/linux-amd64/minio
    ```

2. Make binary executable

    ```bash
    chmod +x minio
    ```

3. Move to system path

    ```bash
    sudo mv minio /usr/local/bin/
    ```

4. Verify installation

    ```bash
    minio --version
    ```

### Creating MinIO User and Directories

1. Create MinIO system user

    ```bash
    sudo useradd -r -s /sbin/nologin minio-user
    ```

2. Create data directory

    ```bash
    sudo mkdir -p /mnt/minio
    ```

3. Set ownership

    ```bash
    sudo chown -R minio-user:minio-user /mnt/minio
    ```

4. Set permissions

    ```bash
    sudo chmod 750 /mnt/minio
    ```

### Configuring MinIO Environment

1. Create environment configuration file

    ```bash
    sudo vi /etc/default/minio
    ```

2. Add MinIO configuration

    ```bash
    # MinIO data storage path
    MINIO_VOLUMES="/mnt/minio"

    # MinIO API address (localhost only for security)
    MINIO_ROOT_USER=minioadmin
    MINIO_ROOT_PASSWORD=YourStrongPasswordHere

    # Console address
    MINIO_OPTS="--console-address :9001 --address :9000"
    ```

    Important: Change minioadmin and YourStrongPasswordHere to secure values.

3. Set proper permissions

    ```bash
    sudo chmod 600 /etc/default/minio
    ```

### Creating Systemd Service

1. Create systemd service file

    ```bash
    sudo vi /etc/systemd/system/minio.service
    ```

2. Add service configuration

    ```bash
    [Unit]
    Description=MinIO Object Storage
    Documentation=https://docs.min.io
    Wants=network-online.target
    After=network-online.target
    AssertFileIsExecutable=/usr/local/bin/minio

    [Service]
    WorkingDirectory=/usr/local

    User=minio-user
    Group=minio-user
    ProtectProc=invisible

    EnvironmentFile=/etc/default/minio
    ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

    # Let systemd restart this service always
    Restart=always

    # Specifies the maximum file descriptor number
    LimitNOFILE=65536

    # Specifies the maximum number of threads
    TasksMax=infinity

    # Disable timeout logic
    TimeoutStopSec=infinity
    SendSIGKILL=no

    [Install]
    WantedBy=multi-user.target
    ```

3. Reload systemd daemon

    ```bash
    sudo systemctl daemon-reload
    ```

4. Enable MinIO service

    ```bash
    sudo systemctl enable minio
    ```

5. Start MinIO service

    ```bash
    sudo systemctl start minio
    ```

6. Verify service is running

    ```bash
    sudo systemctl status minio
    ```

    Expected output: Active (running)

### Configuring Nginx for MinIO API

1. Edit Nginx configuration

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

2. Add MinIO API server block

    ```nginx
    # MinIO API - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name minio.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # MinIO API - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name minio.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        # Allow special characters in headers
        ignore_invalid_headers off;

        # Allow any size file to be uploaded
        client_max_body_size 0;

        # Disable buffering
        proxy_buffering off;
        proxy_request_buffering off;

        location / {
            proxy_pass http://127.0.0.1:9000;

            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            proxy_connect_timeout 300;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            chunked_transfer_encoding off;
        }
    }
    ```

### Configuring Nginx for MinIO Console

1. Add MinIO Console server block

    ```nginx
    # MinIO Console - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name console.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # MinIO Console - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name console.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        # Allow special characters in headers
        ignore_invalid_headers off;

        # Allow any size file to be uploaded
        client_max_body_size 0;

        # Disable buffering
        proxy_buffering off;
        proxy_request_buffering off;

        location / {
            proxy_pass http://127.0.0.1:9001;

            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            # WebSocket support for real-time updates
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
    ```

2. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

3. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Testing MinIO Setup

1. Check MinIO is listening

    ```bash
    sudo ss -tulnp | grep minio
    ```

    Expected output:
    ```
    tcp   LISTEN   0.0.0.0:9000   (minio)
    tcp   LISTEN   0.0.0.0:9001   (minio)
    ```

2. Test API locally

    ```bash
    curl -I http://127.0.0.1:9000/minio/health/live
    ```

    Expected: HTTP 200 OK

3. Test Console locally

    ```bash
    curl -I http://127.0.0.1:9001
    ```

4. Access via browser

    - API: https://minio.arpansahu.space/minio/health/live
    - Console: https://console.arpansahu.space

### Creating Buckets via Console

1. Access MinIO Console

    Go to: https://console.arpansahu.space

2. Login with credentials

    - Username: minioadmin (or your configured username)
    - Password: (your configured password)

3. Create bucket

    - Navigate to: Buckets → Create Bucket
    - Bucket name: my-app-media (example)
    - Click: Create Bucket

4. Configure bucket access

    - Select bucket
    - Go to: Access → Anonymous
    - Configure read/write policies as needed

### Creating Service Account for Applications

1. Navigate to Access Keys

    Console → Identity → Service Accounts

2. Create new service account

    - Click: Create Service Account
    - Assign policy (example: readwrite)
    - Download credentials (Access Key + Secret Key)

3. Save credentials securely

    ```
    Access Key: AKIA...
    Secret Key: wJalr...
    ```

    These will be used in your application configuration.

### Using MinIO with Django

1. Install required Python packages

    ```bash
    pip install boto3 django-storages
    ```

2. Configure Django settings

    Add to settings.py:

    ```python
    # MinIO Configuration
    AWS_ACCESS_KEY_ID = 'YOUR_ACCESS_KEY'
    AWS_SECRET_ACCESS_KEY = 'YOUR_SECRET_KEY'
    AWS_STORAGE_BUCKET_NAME = 'my-app-media'
    AWS_S3_ENDPOINT_URL = 'https://minio.arpansahu.space'
    AWS_S3_REGION_NAME = 'us-east-1'
    AWS_S3_SIGNATURE_VERSION = 's3v4'
    AWS_S3_FILE_OVERWRITE = False
    AWS_DEFAULT_ACL = None
    AWS_S3_VERIFY = True

    # Use MinIO for media files
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    MEDIA_URL = f'{AWS_S3_ENDPOINT_URL}/{AWS_STORAGE_BUCKET_NAME}/'
    ```

3. Test file upload

    ```python
    from django.core.files.storage import default_storage

    # Upload test file
    with open('test.txt', 'rb') as f:
        default_storage.save('test.txt', f)
    ```

### Using MinIO CLI (mc)

1. Install MinIO Client

    ```bash
    wget https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x mc
    sudo mv mc /usr/local/bin/
    ```

2. Configure alias

    ```bash
    mc alias set myminio https://minio.arpansahu.space YOUR_ACCESS_KEY YOUR_SECRET_KEY
    ```

3. List buckets

    ```bash
    mc ls myminio
    ```

4. Upload file

    ```bash
    mc cp myfile.txt myminio/my-app-media/
    ```

5. Download file

    ```bash
    mc cp myminio/my-app-media/myfile.txt ./
    ```

6. Remove file

    ```bash
    mc rm myminio/my-app-media/myfile.txt
    ```

### Managing MinIO Service

1. Check status

    ```bash
    sudo systemctl status minio
    ```

2. Stop MinIO

    ```bash
    sudo systemctl stop minio
    ```

3. Start MinIO

    ```bash
    sudo systemctl start minio
    ```

4. Restart MinIO

    ```bash
    sudo systemctl restart minio
    ```

5. View logs

    ```bash
    sudo journalctl -u minio -f
    ```

6. View last 100 log lines

    ```bash
    sudo journalctl -u minio -n 100
    ```

### Common Issues and Fixes

1. MinIO service fails to start

    Cause: Permission issues or port conflict

    Fix:

    ```bash
    sudo journalctl -u minio -n 50
    sudo chown -R minio-user:minio-user /mnt/minio
    sudo ss -tulnp | grep -E ':(9000|9001)'
    ```

2. Cannot access via Nginx

    Cause: Nginx not configured or firewall blocking

    Fix:

    ```bash
    sudo nginx -t
    sudo systemctl reload nginx
    curl -I http://127.0.0.1:9000/minio/health/live
    ```

3. File upload fails

    Cause: Bucket doesn't exist or permissions wrong

    Fix:

    - Verify bucket exists in Console
    - Check service account has write permissions
    - Verify AWS_STORAGE_BUCKET_NAME matches bucket name

4. SSL certificate errors

    Cause: Using wrong certificate or certificate expired

    Fix:

    ```bash
    openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates
    curl -I https://minio.arpansahu.space/minio/health/live
    ```

5. Port 9000 conflict with Portainer

    Cause: Portainer also uses port 9000

    Fix:

    MinIO uses 9000 for API, Portainer uses 9000 for management.
    They run on different interfaces:
    - MinIO: 127.0.0.1:9000 (localhost only)
    - Portainer: 0.0.0.0:9000 (all interfaces)
    
    No actual conflict as they bind to different addresses.

### Security Hardening

1. Block direct access to MinIO ports

    ```bash
    sudo ufw deny 9000
    sudo ufw deny 9001
    sudo ufw reload
    ```

    This ensures all access goes through Nginx with HTTPS.

2. Use strong credentials

    Update /etc/default/minio with strong password:

    ```bash
    MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)
    ```

3. Create service accounts with limited permissions

    - Don't use root credentials in applications
    - Create separate service accounts per application
    - Assign minimal required permissions

4. Enable bucket versioning

    Console → Buckets → Select Bucket → Versioning → Enable

5. Regular backups

    ```bash
    mc mirror myminio/my-app-media /backup/minio/
    ```

### Monitoring MinIO

1. Check health endpoint

    ```bash
    curl https://minio.arpansahu.space/minio/health/live
    ```

2. Check metrics endpoint

    ```bash
    curl https://minio.arpansahu.space/minio/v2/metrics/cluster
    ```

3. View storage usage

    ```bash
    mc admin info myminio
    ```

4. Monitor logs

    ```bash
    sudo journalctl -u minio -f
    ```

### Certificate Renewal (Automatic)

Since MinIO uses Nginx's wildcard certificate, renewal is automatic via acme.sh:

1. Certificates automatically renew 60 days before expiry
2. Nginx automatically reloads via acme.sh hook
3. No MinIO restart needed (Nginx handles TLS)

Verify auto-renewal setup:

```bash
crontab -l | grep acme
```

### Backup and Restore

1. Backup MinIO data

    ```bash
    sudo tar -czf minio-backup-$(date +%Y%m%d).tar.gz /mnt/minio
    ```

2. Backup MinIO configuration

    ```bash
    sudo cp /etc/default/minio /backup/minio-config-$(date +%Y%m%d)
    ```

3. Restore MinIO data

    ```bash
    sudo systemctl stop minio
    sudo tar -xzf minio-backup-YYYYMMDD.tar.gz -C /
    sudo chown -R minio-user:minio-user /mnt/minio
    sudo systemctl start minio
    ```

### Architecture Summary

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │ [Wildcard Certificate: *.arpansahu.space]
        │
        ├─ minio.arpansahu.space
        │    └─ MinIO API (localhost:9000)
        │         └─ S3-compatible storage
        │
        └─ console.arpansahu.space
             └─ MinIO Console (localhost:9001)
                  └─ Web UI for management
```

### Key Rules to Remember

1. MinIO runs HTTP-only on localhost (secure by design)
2. Nginx handles all TLS termination
3. Use service accounts, not root credentials
4. API and Console on separate subdomains
5. Wildcard certificate covers both subdomains
6. No manual certificate renewal needed
7. Block direct access to ports 9000/9001
8. Always test uploads after configuration changes

### Final Verification Checklist

Run these commands to verify MinIO is working:

```bash
# Check MinIO service
sudo systemctl status minio

# Check port binding
sudo ss -tulnp | grep minio

# Test API health
curl -I https://minio.arpansahu.space/minio/health/live

# Test Console access
curl -I https://console.arpansahu.space

# Check Nginx config
sudo nginx -t

# Verify certificate
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates
```

Then test in browser:
- Console: https://console.arpansahu.space
- Login with your credentials
- Create test bucket
- Upload test file
- Verify file accessible

### What This Setup Provides

After following this guide, you will have:

1. MinIO server running as systemd service
2. HTTPS access via Nginx reverse proxy
3. Separate API and Console subdomains
4. Automatic certificate renewal
5. S3-compatible object storage
6. Production-ready configuration
7. Secure credential management
8. Easy Django integration
9. CLI access via mc
10. Comprehensive monitoring and logging

### Example Configuration

| Component        | Value                                 |
| ---------------- | ------------------------------------- |
| API URL          | https://minio.arpansahu.space         |
| Console URL      | https://console.arpansahu.space       |
| API Port         | 9000 (localhost only)                 |
| Console Port     | 9001 (localhost only)                 |
| Data Directory   | /mnt/minio                            |
| Config File      | /etc/default/minio                    |
| Service File     | /etc/systemd/system/minio.service     |
| User             | minio-user                            |

My MinIO can be accessed here:
- API: https://minio.arpansahu.space
- Console: https://console.arpansahu.space

For Django file storage setup, see the Django integration section above.

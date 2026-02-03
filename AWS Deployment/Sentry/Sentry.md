# Self-Hosted Sentry Setup

Sentry is an error tracking and performance monitoring platform. This guide covers setting up a self-hosted Sentry instance.

## Prerequisites

- Docker & Docker Compose installed
- Minimum 4GB RAM dedicated to Sentry
- At least 20GB disk space
- Domain/subdomain configured (e.g., sentry.arpansahu.space)

## Installation Steps

### 1. Clone Sentry Repository

```bash
cd /opt
sudo git clone https://github.com/getsentry/self-hosted.git sentry
cd sentry
sudo git checkout latest  # Use latest stable release
```

### 2. Run Installation Script

```bash
sudo ./install.sh
```

This will:
- Pull all required Docker images
- Generate secret keys
- Set up PostgreSQL, Redis, and other dependencies
- Create initial superuser (you'll be prompted for email/password)

### 3. Configure Environment

Edit `.env` file:

```bash
sudo nano .env
```

Key configurations:

```bash
# System URL (must match your domain)
SENTRY_URL=https://sentry.arpansahu.space

# Email configuration (optional but recommended)
SENTRY_MAIL_HOST=smtp.mailjet.com
SENTRY_MAIL_PORT=587
SENTRY_MAIL_USERNAME=your_mailjet_api_key
SENTRY_MAIL_PASSWORD=your_mailjet_api_secret
SENTRY_MAIL_USE_TLS=True
SENTRY_SERVER_EMAIL=noreply@arpansahu.space

# GitHub/GitLab integration (optional)
# GITHUB_APP_ID=
# GITHUB_API_SECRET=
```

### 4. Start Sentry

```bash
sudo docker compose up -d
```

Verify all containers are running:

```bash
sudo docker compose ps
```

### 5. Configure Nginx Reverse Proxy

Create nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/sentry
```

```nginx
# ================= SENTRY PROXY =================

# HTTP → HTTPS redirect
server {
    listen 80;
    listen [::]:80;

    server_name sentry.arpansahu.space;
    return 301 https://$host$request_uri;
}

# HTTPS reverse proxy
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name sentry.arpansahu.space;

    # SSL certificates (acme.sh wildcard)
    ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # Increase body size for large error payloads
    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:9000;  # Sentry default port

        proxy_http_version 1.1;

        # Required headers
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host  $host;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts for long-running requests
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/sentry /etc/nginx/sites-enabled/
sudo nginx -t
sudo nginx -s reload
```

### 6. Access Sentry

Navigate to: https://sentry.arpansahu.space

Login with the superuser credentials created during installation.

## Configuration in Django

### 1. Install Sentry SDK

```bash
pip install sentry-sdk
```

### 2. Update settings.py

```python
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

# Sentry configuration
SENTRY_ENVIRONMENT = config('SENTRY_ENVIRONMENT', default='production')
SENTRY_DSN = config('SENTRY_DSN')  # Get from Sentry project settings

sentry_sdk.init(
    dsn=SENTRY_DSN,
    integrations=[DjangoIntegration()],
    environment=SENTRY_ENVIRONMENT,
    traces_sample_rate=0.1,  # 10% of transactions for performance monitoring
    profiles_sample_rate=0.1,  # 10% for profiling
    send_default_pii=False,  # Don't send personal data
)
```

### 3. Get DSN from Sentry

1. Login to your Sentry instance
2. Create a new project (Django)
3. Copy the DSN from Project Settings → Client Keys (DSN)
4. Add to your .env file:

```bash
SENTRY_DSN=https://<key>@sentry.arpansahu.space/<project-id>
SENTRY_ENVIRONMENT=production
```

### 4. Frontend Integration (Optional)

Add to your base template:

```html
<script
  src="https://sentry.arpansahu.space/js-sdk-loader/<project-id>.min.js"
  crossorigin="anonymous"
></script>
```

Or use the JavaScript SDK directly:

```html
<script
  src="https://browser.sentry-cdn.com/@sentry/browser/7.x/bundle.min.js"
  integrity="sha384-..."
  crossorigin="anonymous"
></script>
<script>
  Sentry.init({
    dsn: "https://<key>@sentry.arpansahu.space/<project-id>",
    environment: "production",
    tracesSampleRate: 0.1,
  });
</script>
```

## Maintenance

### Update Sentry

```bash
cd /opt/sentry
sudo git pull
sudo ./install.sh --skip-user-creation
sudo docker compose up -d
```

### View Logs

```bash
cd /opt/sentry
sudo docker compose logs -f web  # Web server logs
sudo docker compose logs -f worker  # Background worker logs
```

### Backup Database

```bash
sudo docker compose exec postgres pg_dump -U postgres sentry > sentry_backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
cat sentry_backup.sql | sudo docker compose exec -T postgres psql -U postgres sentry
```

## Monitoring

Sentry uses approximately:
- **RAM**: 4-6GB
- **Disk**: Grows with usage, monitor `/opt/sentry` directory
- **CPU**: Moderate during event processing

Monitor with:

```bash
sudo docker stats
```

## Troubleshooting

### Port Conflicts

If port 9000 is in use, edit `docker-compose.yml`:

```yaml
services:
  web:
    ports:
      - "9090:9000"  # Change 9000 to 9090
```

Then update nginx proxy_pass to `http://localhost:9090`

### Out of Memory

Increase Docker memory limits in `docker-compose.yml`:

```yaml
services:
  web:
    mem_limit: 2g
  worker:
    mem_limit: 1g
```

### Clear Old Data

```bash
# Inside Sentry container
sudo docker compose exec web sentry cleanup --days 30
```

## Security Notes

- Change default admin password immediately
- Enable 2FA for admin accounts
- Restrict Sentry access to internal IPs if possible
- Regularly update Sentry to patch security vulnerabilities
- Use strong PostgreSQL passwords
- Enable rate limiting in Sentry project settings

## Resources

- [Official Self-Hosted Docs](https://develop.sentry.dev/self-hosted/)
- [GitHub Repository](https://github.com/getsentry/self-hosted)
- [Sentry Documentation](https://docs.sentry.io/)

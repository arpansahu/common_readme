## PgAdmin 4

PgAdmin 4 is a web-based administration tool for PostgreSQL. This guide provides a complete, production-ready setup using Python virtual environment, PM2 for process management, Nginx reverse proxy with HTTPS, and Mailjet SMTP for email notifications.

### Prerequisites

Before installing PgAdmin, ensure you have:

1. Ubuntu Server (20.04 / 22.04 recommended)
2. PostgreSQL already installed and running
3. Nginx installed with SSL certificates
4. Node.js and npm installed
5. Mailjet account (for SMTP email functionality)
6. Root or sudo access

### Installing Required System Packages

1. Update package list

    ```bash
    sudo apt update
    ```

2. Install required packages

    ```bash
    sudo apt install -y python3 python3-venv python3-pip nodejs npm nginx
    ```

### Creating PgAdmin Virtual Environment

1. Create directory for pgAdmin

    ```bash
    mkdir -p /home/USERNAME/root
    cd /home/USERNAME/root
    ```

    Replace USERNAME with your actual username.

2. Create virtual environment

    ```bash
    python3 -m venv pgadmin_venv
    ```

3. Activate virtual environment

    ```bash
    source pgadmin_venv/bin/activate
    ```

4. Upgrade pip

    ```bash
    pip install --upgrade pip
    ```

5. Install pgAdmin 4

    ```bash
    pip install pgadmin4
    ```

6. Verify installation

    ```bash
    pgadmin4 --version
    ```

### Preparing Required Directories

PgAdmin stores its internal data in specific directories that must exist with proper permissions.

1. Create data and log directories

    ```bash
    sudo mkdir -p /var/lib/pgadmin /var/log/pgadmin
    ```

2. Set ownership

    ```bash
    sudo chown -R USERNAME:USERNAME /var/lib/pgadmin /var/log/pgadmin
    ```

    Replace USERNAME with your actual username.

3. Set permissions

    ```bash
    sudo chmod 700 /var/lib/pgadmin /var/log/pgadmin
    ```

### Configuring PgAdmin

Create a persistent configuration file that survives upgrades.

1. Create config_local.py

    ```bash
    vi /home/USERNAME/root/pgadmin_venv/lib/python3.12/site-packages/pgadmin4/config_local.py
    ```

    Note: Adjust python3.12 to match your Python version.

2. Add configuration

    ```python
    # Bind address and port
    DEFAULT_SERVER = '0.0.0.0'
    DEFAULT_SERVER_PORT = 5050

    # Mailjet SMTP Configuration
    MAIL_SERVER = 'in-v3.mailjet.com'
    MAIL_PORT = 587
    MAIL_USE_TLS = True
    MAIL_USE_SSL = False

    MAIL_USERNAME = 'YOUR_MAILJET_API_KEY'
    MAIL_PASSWORD = 'YOUR_MAILJET_SECRET_KEY'

    MAIL_DEFAULT_SENDER = 'pgadmin@yourdomain.com'
    SECURITY_EMAIL_SENDER = MAIL_DEFAULT_SENDER
    ```

    Important: Use Mailjet API key and secret, not email/password.

### Creating Startup Script

PgAdmin must run non-interactively under PM2, so we create a startup script.

1. Create startup script

    ```bash
    vi /home/USERNAME/run_pgadmin.sh
    ```

2. Add script content

    ```bash
    #!/bin/bash
    set -e

    source /home/USERNAME/root/pgadmin_venv/bin/activate

    export PGADMIN_LISTEN_ADDRESS=0.0.0.0
    export PGADMIN_LISTEN_PORT=5050

    # Initial admin credentials (used only on first boot)
    export PGADMIN_DEFAULT_EMAIL=admin@yourdomain.com
    export PGADMIN_DEFAULT_PASSWORD=StrongPgAdminPassword@123

    exec pgadmin4
    ```

3. Make script executable

    ```bash
    chmod +x /home/USERNAME/run_pgadmin.sh
    ```

### Managing PgAdmin with PM2

1. Install PM2 globally

    ```bash
    npm install -g pm2
    ```

2. Start pgAdmin with PM2

    ```bash
    pm2 start /home/USERNAME/run_pgadmin.sh --name pgadmin4
    ```

3. Save PM2 configuration

    ```bash
    pm2 save
    ```

4. Set PM2 to start on boot

    ```bash
    pm2 startup
    ```

    Follow the command output instructions if needed.

5. Verify pgAdmin is running

    ```bash
    pm2 status
    ```

    Expected output: pgadmin4 should be in online status.

6. Check port binding

    ```bash
    ss -tulnp | grep 5050
    ```

### Testing PgAdmin Locally

1. Test local access

    ```bash
    curl -I http://127.0.0.1:5050
    ```

    Expected output:
    ```
    HTTP/1.1 200 OK
    ```
    or
    ```
    HTTP/1.1 302 FOUND
    ```

### Configuring Nginx as Reverse Proxy

1. Edit Nginx configuration

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

    If /etc/nginx/sites-available/services does not exist:

    1. Create a new configuration file:

        ```bash
        touch /etc/nginx/sites-available/services
        vi /etc/nginx/sites-available/services
        ```

2. Add server block configuration

    ```nginx
    server {
        listen         80;
        server_name    pgadmin.arpansahu.me;
        
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }

        location / {
            proxy_pass              http://127.0.0.1:5050;
            proxy_set_header        Host $host;
            proxy_set_header        X-Forwarded-Proto $scheme;
        }

        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    }
    ```

3. Enable the configuration

    If using sites-available/sites-enabled pattern:

    ```bash
    sudo ln -s /etc/nginx/sites-available/services /etc/nginx/sites-enabled/
    ```

4. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

5. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Accessing PgAdmin

1. Local access

    ```
    http://127.0.0.1:5050
    ```

2. Public access

    ```
    https://pgadmin.arpansahu.me
    ```

3. Login credentials

    - Email: admin@yourdomain.com
    - Password: StrongPgAdminPassword@123

    (or whatever you set in run_pgadmin.sh)

### Verifying Mailjet SMTP

1. Access pgAdmin preferences

    PgAdmin UI → File → Preferences → User Management

2. Test password reset

    Select your user → Reset Password

    You should receive an email via Mailjet.

### Managing PgAdmin with PM2

1. View status

    ```bash
    pm2 status
    ```

2. View logs

    ```bash
    pm2 logs pgadmin4
    pm2 logs pgadmin4 --lines 50
    ```

3. Restart pgAdmin

    ```bash
    pm2 restart pgadmin4
    ```

4. Stop pgAdmin

    ```bash
    pm2 stop pgadmin4
    ```

5. Start pgAdmin

    ```bash
    pm2 start pgadmin4
    ```

6. Remove from PM2

    ```bash
    pm2 delete pgadmin4
    ```

### Resetting PgAdmin

If you forget your password or pgAdmin becomes locked, you can reset it completely.

1. Stop and delete PM2 process

    ```bash
    pm2 stop pgadmin4
    pm2 delete pgadmin4
    ```

2. Remove pgAdmin data

    ```bash
    sudo rm -rf /var/lib/pgadmin/*
    sudo rm -rf /var/log/pgadmin/*
    ```

3. Restart pgAdmin

    ```bash
    pm2 start /home/USERNAME/run_pgadmin.sh --name pgadmin4
    pm2 save
    ```

    PgAdmin will re-initialize using environment credentials from run_pgadmin.sh.

### Security Hardening

1. Close direct access to pgAdmin port

    ```bash
    sudo ufw deny 5050
    sudo ufw allow 443
    sudo ufw reload
    ```

2. Verify firewall rules

    ```bash
    sudo ufw status
    ```

3. Optional security measures

    - Enable IP allowlist in Nginx
    - Configure pgAdmin MFA (Multi-Factor Authentication)
    - Create non-admin pgAdmin users
    - Regular security audits
    - Backup pgAdmin configuration

### Common Issues and Fixes

1. PgAdmin Not Starting

    Cause: Port already in use or permission issues

    Fix:

    ```bash
    pm2 logs pgadmin4
    ss -tulnp | grep 5050
    # Check logs for specific error
    ```

2. Cannot Access via Browser

    Cause: Nginx not configured or firewall blocking

    Fix:

    ```bash
    sudo nginx -t
    sudo systemctl status nginx
    curl -I http://127.0.0.1:5050
    ```

3. SMTP Not Working

    Cause: Incorrect Mailjet credentials or config

    Fix:

    - Verify Mailjet API key and secret
    - Check config_local.py syntax
    - Test Mailjet credentials separately
    - Check pgAdmin logs for SMTP errors

4. Permission Denied Errors

    Cause: Incorrect directory permissions

    Fix:

    ```bash
    sudo chown -R USERNAME:USERNAME /var/lib/pgadmin /var/log/pgadmin
    sudo chmod 700 /var/lib/pgadmin /var/log/pgadmin
    ```

5. PM2 Process Crashes

    Cause: Python environment issues or missing dependencies

    Fix:

    ```bash
    pm2 logs pgadmin4
    source /home/USERNAME/root/pgadmin_venv/bin/activate
    pip install --upgrade pgadmin4
    pm2 restart pgadmin4
    ```

### Upgrading PgAdmin

1. Activate virtual environment

    ```bash
    source /home/USERNAME/root/pgadmin_venv/bin/activate
    ```

2. Upgrade pgAdmin

    ```bash
    pip install --upgrade pgadmin4
    ```

3. Restart PM2 process

    ```bash
    pm2 restart pgadmin4
    ```

4. Verify version

    ```bash
    pgadmin4 --version
    ```

### Architecture Overview

```
Browser (Client)
   │
   ├─ Local: 127.0.0.1:5050
   └─ Public: https://pgadmin.domain.com
        │
        └─ Nginx (HTTPS, Port 443)
             │
             └─ PgAdmin (PM2, Port 5050)
                  │
                  └─ PostgreSQL Database
```

### Key Rules to Remember

1. PgAdmin cannot prompt for input under PM2
2. First boot requires environment credentials
3. Deleting /var/lib/pgadmin resets all users
4. SMTP config lives in config_local.py
5. config_local.py survives upgrades
6. PostgreSQL itself is NOT affected by these steps
7. HTTP services use sites-available/sites-enabled
8. Always use virtual environment for Python packages

### Final Verification Checklist

Run these commands to verify everything is working:

```bash
# Check PM2 status
pm2 status

# Check port binding
ss -tulnp | grep 5050

# Check local access
curl -I http://127.0.0.1:5050

# Check Nginx
sudo nginx -t
sudo systemctl status nginx

# Check firewall
sudo ufw status
```

Then access in browser:
- Local: http://127.0.0.1:5050
- Public: https://pgadmin.arpansahu.me

### What This Setup Provides

After following this guide, you will have:

1. PgAdmin 4 running in isolated virtual environment
2. PM2 process management with auto-restart
3. HTTPS access via Nginx reverse proxy
4. Mailjet SMTP for password reset emails
5. Production-ready configuration
6. Persistent data across restarts
7. Non-interactive startup (no prompts)
8. Easy upgrade path
9. Secure firewall configuration
10. Complete PostgreSQL web administration

### Example Access Details

| Item                | Value                                 |
| ------------------- | ------------------------------------- |
| PgAdmin URL         | https://pgadmin.arpansahu.me          |
| Local Access        | http://127.0.0.1:5050                 |
| PM2 Process Name    | pgadmin4                              |
| PgAdmin Port        | 5050                                  |
| SMTP Provider       | Mailjet (in-v3.mailjet.com:587)      |
| Data Directory      | /var/lib/pgadmin                      |
| Log Directory       | /var/log/pgadmin                      |
| Virtual Env         | /home/USERNAME/root/pgadmin_venv      |

My PgAdmin4 can be accessed here: https://pgadmin.arpansahu.me/

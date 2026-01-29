## Apache Guacamole (Browser-based SSH/RDP)

Apache Guacamole is a clientless remote desktop gateway that allows you to access your servers via SSH, RDP, or VNC through a web browser. No plugins or client software required. This guide provides production-ready setup with Nginx reverse proxy and HTTPS.

### Prerequisites

Before installing Guacamole, ensure you have:

1. Ubuntu Server 22.04 LTS
2. Docker and Docker Compose installed
3. Nginx with SSL certificates configured
4. Domain name (example: ssh.arpansahu.space)
5. Wildcard SSL certificate already issued
6. Root or sudo access

### Architecture Overview

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │
        └─ ssh.arpansahu.space
             │
             └─ Guacamole (localhost:8080)
                  │
                  ├─ Guacd (RDP/SSH/VNC backend)
                  └─ PostgreSQL (Connection storage)
```

Key Principles:
- Guacamole runs HTTP-only on localhost
- Nginx handles all TLS/SSL termination
- Access SSH/RDP through web browser
- Multi-user support with authentication
- Connection history and session recording

### Why Apache Guacamole

**Advantages:**
- No client software needed (browser-only)
- Access servers from any device
- Tablet and mobile friendly
- Copy/paste between local and remote
- Session recording and auditing
- Multi-factor authentication support
- Connection sharing

**Use Cases:**
- Emergency access when SSH client unavailable
- Mobile device server access
- Secure jump host for multiple servers
- Client demos and support
- Centralized access management

### Installing Guacamole with Docker

1. Create Guacamole directory

    ```bash
    sudo mkdir -p /opt/guacamole
    cd /opt/guacamole
    ```

2. Create Docker Compose file

    ```bash
    sudo nano docker-compose.yml
    ```

3. Add Guacamole stack configuration

    ```yaml
    version: '3.8'

    services:
      guacd:
        image: guacamole/guacd:latest
        container_name: guacd
        restart: unless-stopped
        volumes:
          - guacd-drive:/drive
          - guacd-record:/record

      postgres:
        image: postgres:15
        container_name: guacamole-postgres
        restart: unless-stopped
        environment:
          POSTGRES_DB: guacamole_db
          POSTGRES_USER: guacamole_user
          POSTGRES_PASSWORD: CHANGE_THIS_PASSWORD
        volumes:
          - postgres-data:/var/lib/postgresql/data

      guacamole:
        image: guacamole/guacamole:latest
        container_name: guacamole
        restart: unless-stopped
        ports:
          - "127.0.0.1:8080:8080"
        environment:
          GUACD_HOSTNAME: guacd
          POSTGRES_HOSTNAME: postgres
          POSTGRES_DATABASE: guacamole_db
          POSTGRES_USER: guacamole_user
          POSTGRES_PASSWORD: CHANGE_THIS_PASSWORD
        depends_on:
          - guacd
          - postgres

    volumes:
      guacd-drive:
      guacd-record:
      postgres-data:
    ```

    Important: Change `CHANGE_THIS_PASSWORD` to a strong password.

4. Initialize Guacamole database

    Generate initialization script:

    ```bash
    docker run --rm guacamole/guacamole:latest /opt/guacamole/bin/initdb.sh --postgres > initdb.sql
    ```

5. Start PostgreSQL temporarily

    ```bash
    docker compose up -d postgres
    ```

    Wait 10 seconds for PostgreSQL to initialize.

6. Initialize database schema

    ```bash
    docker cp initdb.sql guacamole-postgres:/initdb.sql
    docker exec -i guacamole-postgres psql -U guacamole_user -d guacamole_db -f /initdb.sql
    ```

7. Remove initialization script

    ```bash
    rm initdb.sql
    ```

8. Start all Guacamole services

    ```bash
    docker compose up -d
    ```

9. Verify services are running

    ```bash
    docker compose ps
    ```

    Expected: All containers should be "Up"

### Configuring Nginx for Guacamole

1. Edit Nginx services configuration

    ```bash
    sudo nano /etc/nginx/sites-available/services
    ```

2. Add Guacamole server block

    ```nginx
    # Guacamole SSH/RDP Gateway - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name ssh.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # Guacamole SSH/RDP Gateway - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name ssh.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        # Guacamole specific settings
        proxy_buffering off;
        proxy_http_version 1.1;

        location / {
            proxy_pass http://127.0.0.1:8080/guacamole/;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            # WebSocket support
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Disable buffering for smooth RDP/SSH
            proxy_buffering off;
            proxy_request_buffering off;
        }

        location /guacamole/websocket-tunnel {
            proxy_pass http://127.0.0.1:8080/guacamole/websocket-tunnel;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            # Important for WebSocket
            proxy_buffering off;
            proxy_read_timeout 86400;
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

### Initial Guacamole Setup

1. Access Guacamole web interface

    Go to: https://ssh.arpansahu.space

2. Login with default credentials

    - Username: `guacadmin`
    - Password: `guacadmin`

    **Important:** Change this immediately after first login.

3. Change admin password

    - Click username (top right) → Settings
    - Navigate to: Preferences → Change Password
    - Set strong password
    - Save

### Adding SSH Connection

1. Navigate to connections

    Settings → Connections → New Connection

2. Configure SSH connection

    **Edit Connection:**
    - Name: `My Home Server`
    - Protocol: `SSH`

    **Parameters:**
    - Hostname: `192.168.1.100` (your server IP)
    - Port: `22`
    - Username: `your-username`
    - Password: (your password) OR
    - Private Key: (paste your SSH private key)

    **Display:**
    - Color Scheme: `Gray on Black`
    - Font Name: `monospace`
    - Font Size: `12`

3. Save connection

4. Test connection

    - Go back to Home
    - Click on connection name
    - You should see SSH session in browser

### Adding RDP Connection (Windows)

1. Create new connection

    Settings → Connections → New Connection

2. Configure RDP connection

    **Edit Connection:**
    - Name: `Windows PC`
    - Protocol: `RDP`

    **Parameters:**
    - Hostname: `192.168.1.50` (Windows PC IP)
    - Port: `3389`
    - Username: `your-windows-username`
    - Password: (Windows password)
    - Domain: (if applicable)
    - Security Mode: `Any`
    - Ignore Server Certificate: `Checked`

    **Display:**
    - Width: `1920`
    - Height: `1080`
    - Color Depth: `True Color (32-bit)`

3. Save and test connection

### Creating Additional Users

1. Navigate to user management

    Settings → Users → New User

2. Create user

    - Username: `john`
    - Password: Set strong password
    - Permissions:
      - Change own password: ✓
      - Administer system: ✗ (unless admin)

3. Assign connections to user

    - Settings → Connections
    - Edit connection
    - Permissions tab
    - Add user with Read permission

### Enabling Session Recording

1. Edit connection

    Settings → Connections → Edit Connection

2. Configure recording

    **Screen Recording:**
    - Recording Path: `/record`
    - Recording Name: `${GUAC_USERNAME}-${GUAC_DATE}-${GUAC_TIME}`
    - Create Recording Path: `Checked`
    - Auto Create Recording: `Checked`

3. Save configuration

4. View recordings

    Recordings stored in Docker volume `guacd-record`

    Access via:

    ```bash
    docker exec -it guacd ls -lh /record
    ```

### Security Hardening

1. Disable default admin account

    After creating new admin user:
    - Settings → Users
    - Click `guacadmin`
    - Disable account

2. Enable two-factor authentication (optional)

    Requires TOTP extension:

    ```bash
    # Add to docker-compose.yml environment
    TOTP_ENABLED: "true"
    ```

3. Restrict IP access via Nginx

    Add to Nginx server block:

    ```nginx
    # Allow only specific IPs
    allow YOUR_HOME_IP;
    allow YOUR_OFFICE_IP;
    deny all;
    ```

4. Configure session timeout

    Add to docker-compose.yml environment:

    ```yaml
    GUACAMOLE_SESSION_TIMEOUT: "900000"  # 15 minutes in ms
    ```

### Managing Guacamole Service

1. View logs

    ```bash
    docker compose logs -f guacamole
    ```

2. Restart Guacamole

    ```bash
    docker compose restart guacamole
    ```

3. Stop all services

    ```bash
    docker compose down
    ```

4. Start all services

    ```bash
    docker compose up -d
    ```

5. Update Guacamole

    ```bash
    docker compose pull
    docker compose up -d
    ```

### Backup and Restore

1. Backup Guacamole database

    ```bash
    docker exec guacamole-postgres pg_dump -U guacamole_user guacamole_db > guacamole-backup-$(date +%Y%m%d).sql
    ```

2. Backup Docker Compose configuration

    ```bash
    sudo cp /opt/guacamole/docker-compose.yml /backup/guacamole-compose-$(date +%Y%m%d).yml
    ```

3. Restore database

    ```bash
    docker exec -i guacamole-postgres psql -U guacamole_user -d guacamole_db < guacamole-backup-YYYYMMDD.sql
    ```

### Common Issues and Fixes

1. Cannot connect to Guacamole

    Cause: Nginx misconfiguration or service not running

    Fix:

    ```bash
    docker compose ps
    curl -I http://127.0.0.1:8080/guacamole/
    sudo nginx -t
    sudo systemctl reload nginx
    ```

2. SSH connection fails

    Cause: Wrong credentials or firewall blocking

    Fix:

    - Verify SSH credentials
    - Check server IP is correct
    - Ensure SSH service running on target
    - Check firewall allows port 22

3. Copy/paste not working

    Cause: Browser clipboard API blocked

    Fix:

    - Use Ctrl+Shift+C / Ctrl+Shift+V (Linux)
    - Use Guacamole clipboard (Ctrl+Alt+Shift)
    - Enable clipboard in browser settings

4. Session recording not working

    Cause: Recording path permissions

    Fix:

    ```bash
    docker exec -it guacd mkdir -p /record
    docker exec -it guacd chmod 777 /record
    ```

5. Slow performance

    Cause: Buffering or network issues

    Fix:

    - Disable compression in connection settings
    - Reduce color depth
    - Lower resolution
    - Check network latency

### Performance Optimization

1. Adjust connection parameters

    For SSH connections:
    - Enable compression
    - Use appropriate color scheme
    - Set reasonable font size

    For RDP connections:
    - Lower color depth (16-bit vs 32-bit)
    - Disable wallpaper
    - Disable animations
    - Use appropriate resolution

2. Optimize Docker resources

    Add to docker-compose.yml:

    ```yaml
    services:
      guacamole:
        deploy:
          resources:
            limits:
              memory: 512M
            reservations:
              memory: 256M
    ```

### Integration with Authentication Systems

1. LDAP Authentication (optional)

    Add to docker-compose.yml environment:

    ```yaml
    LDAP_HOSTNAME: ldap.example.com
    LDAP_PORT: 389
    LDAP_USER_BASE_DN: ou=users,dc=example,dc=com
    LDAP_USERNAME_ATTRIBUTE: uid
    ```

2. SAML Authentication (optional)

    Requires additional configuration and identity provider.

### Monitoring Guacamole

1. Check active sessions

    Settings → Active Sessions

2. View connection history

    Settings → History

3. Monitor Docker resources

    ```bash
    docker stats guacamole guacd guacamole-postgres
    ```

4. Check logs for errors

    ```bash
    docker compose logs --tail=100 guacamole
    ```

### Final Verification Checklist

Run these commands to verify Guacamole is working:

```bash
# Check all containers running
docker compose ps

# Check Guacamole is accessible locally
curl -I http://127.0.0.1:8080/guacamole/

# Check HTTPS access
curl -I https://ssh.arpansahu.space

# Check Nginx configuration
sudo nginx -t

# Check logs for errors
docker compose logs --tail=50 guacamole

# Verify database connection
docker exec guacamole-postgres psql -U guacamole_user -d guacamole_db -c "\dt"
```

Then test in browser:
- Access: https://ssh.arpansahu.space
- Login with your credentials
- Create test SSH connection
- Connect and verify SSH works
- Test copy/paste functionality

### What This Setup Provides

After following this guide, you will have:

1. Browser-based SSH/RDP access
2. HTTPS-secured connection
3. Multi-user support
4. Connection management
5. Session recording capability
6. Automatic reconnection
7. Clipboard sharing
8. File transfer support (SFTP)
9. Mobile-friendly interface
10. Centralized access control

### Example Use Cases

**Emergency Access:**
- Access servers from any browser
- No SSH client installation needed
- Work from client's computer

**Mobile Administration:**
- Manage servers from tablet
- Emergency fixes on the go
- Monitor systems anywhere

**Client Demos:**
- Show live server environment
- No client-side software needed
- Controlled access

**Team Collaboration:**
- Multiple users, different permissions
- Shared connections
- Audit trail

### Architecture Summary

```
Browser (HTTPS)
   │
   └─ Nginx (TLS Termination)
        │
        └─ Guacamole Web (localhost:8080)
             │
             ├─ Guacd (Protocol Backend)
             │   ├─ SSH Protocol Handler
             │   ├─ RDP Protocol Handler
             │   └─ VNC Protocol Handler
             │
             └─ PostgreSQL (Connection DB)
```

### Key Rules to Remember

1. Always use HTTPS for Guacamole
2. Change default admin password immediately
3. Use strong passwords for all connections
4. Enable session recording for auditing
5. Restrict access via IP whitelist
6. Regular database backups
7. Keep Docker images updated
8. Monitor active sessions
9. Review connection history
10. Test failover and recovery

### Next Steps

After setting up Guacamole:

1. Add all your server connections
2. Create users for team members
3. Configure session recording
4. Set up automated backups
5. Enable IP whitelisting
6. Test from mobile devices
7. Document connection details

My Guacamole instance: https://ssh.arpansahu.space

For other services setup, see the main documentation index.

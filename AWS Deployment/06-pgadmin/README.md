## PgAdmin - PostgreSQL Administration Tool

PgAdmin is the most popular open-source PostgreSQL administration and development platform. This setup runs PgAdmin as a Docker container with HTTPS access via Nginx.

**Note:** PgAdmin is a web-based management interface. Unlike PostgreSQL, Redis, or RabbitMQ (which applications connect to programmatically), PgAdmin is accessed only through a web browser for database administration tasks.

---

## Step-by-Step Installation Guide

### Step 1: Create Environment Configuration

First, create the environment configuration file that will store your PgAdmin credentials.

**Create `.env.example` (Template file):**

```bash
# PgAdmin Configuration
PGADMIN_EMAIL=admin@arpansahu.space
PGADMIN_PASSWORD=your_secure_password_here
PGADMIN_PORT=5050
```

**Create your actual `.env` file:**

```bash
cd "AWS Deployment/Pgadmin"
cp .env.example .env
nano .env
```

**Your `.env` file should look like this (with your actual credentials):**

```bash
# PgAdmin Configuration
PGADMIN_EMAIL=admin@arpansahu.space
PGADMIN_PASSWORD=${PGADMIN_PASSWORD}
PGADMIN_PORT=5050
```

**⚠️ Important:** 
- Always use a strong password in production!
- Never commit your `.env` file to version control
- Keep the `.env.example` file as a template

---

### Step 2: Run Installation Script

The `install.sh` script creates a Docker volume and runs the PgAdmin container.

**Make the script executable and run:**

```bash
chmod +x install.sh
./install.sh
```

**What the script does:**
1. Loads configuration from `.env` file
2. Creates Docker volume `pgadmin_data` for persistent storage
3. Runs PgAdmin container with provided credentials
4. Binds to localhost:5050 only (not directly accessible from outside)
5. Verifies the container is running

**Expected output:**
```
=== PgAdmin Installation Script ===
Loading configuration from .env
Step 1: Creating Docker volume for PgAdmin data
✓ Volume created
Step 2: Running PgAdmin Container
Step 3: Waiting for PgAdmin to start...
Step 4: Verifying Installation
✓ PgAdmin container is running
========================================
PgAdmin installed successfully!
========================================
```

---

### Step 3: Configure Nginx for HTTPS Access

For secure HTTPS access to PgAdmin, we need to add its configuration to the Nginx services file.

**Run the Nginx configuration script:**

```bash
chmod +x add-nginx-config.sh
sudo ./add-nginx-config.sh
```

**What this script does:**
1. Backs up the current Nginx services configuration
2. Adds PgAdmin reverse proxy configuration
3. Configures HTTPS with SSL certificates
4. Tests and reloads Nginx
5. Verifies PgAdmin is accessible

**The nginx configuration includes:**
- HTTP to HTTPS redirect
- SSL/TLS encryption using existing certificates
- WebSocket support for PgAdmin features
- Proper proxy headers for secure connection

---

### Step 4: Router Port Forwarding (Optional)

**⚠️ Only required for external access (from outside your home network)**

If you want to access PgAdmin from outside your local network:

**Steps for Airtel Router:**

1. **Login to router admin panel:**
   - Open browser: `http://192.168.1.1`
   - Enter admin credentials

2. **Navigate to Port Forwarding:**
   - Go to `NAT` → `Port Forwarding` tab
   - Click "Add new rule"

3. **Configure for HTTPS (port 443):**
   - **Service Name:** User Define
   - **External Start Port:** 443
   - **External End Port:** 443
   - **Internal Start Port:** 443
   - **Internal End Port:** 443
   - **Server IP Address:** 192.168.1.200
   - **Protocol:** TCP

4. **Activate the rule** and verify it appears in the list

**Note:** This is typically already configured if you've set up other HTTPS services.

---

### Step 5: Verify Installation

**Open PgAdmin in your browser:**

1. Navigate to https://pgadmin.arpansahu.space
2. You should see the PgAdmin login page
3. Login with your credentials from `.env` file:
   - **Email:** admin@arpansahu.space
   - **Password:** (from your `.env` file)
4. After successful login, you should see the PgAdmin dashboard

**Troubleshooting:**
- If you get a 502 Bad Gateway error, wait 30-60 seconds for PgAdmin to fully start
- Check container status: `docker ps | grep pgadmin`
- Check logs: `docker logs pgadmin`

---

## Adding PostgreSQL Servers to PgAdmin

### Option 1: Connect to Local PostgreSQL (Same Server)

1. **Login to PgAdmin:** https://pgadmin.arpansahu.space
   - Email: (from your `.env` file)
   - Password: (from your `.env` file)

2. **Add Server:**
   - Right-click "Servers" → Register → Server

3. **General Tab:**
   - Name: `Local PostgreSQL`

4. **Connection Tab:**
   - Host name/address: `192.168.1.200` (server IP)
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `postgres`
   - Password: `Gandu302postgres`
   - Save password: ✓

### Option 2: Connect via Nginx Proxy (Port 9552)

For connections from outside the local network:

**Connection Tab:**
- Host name/address: `postgres.arpansahu.space`
- Port: `9552`
- Maintenance database: `postgres`
- Username: `postgres`
- Password: `Gandu302postgres`
- SSL mode: `Prefer` or `Require`
- Save password: ✓

---

## Common Tasks in PgAdmin

### Query Database

1. Navigate to: Server → Database → Schemas → public → Tables
2. Right-click table → View/Edit Data
3. Choose "All Rows" or "First 100 Rows"

### Execute SQL

1. Tools → Query Tool (or right-click database → Query Tool)
2. Write your SQL query
3. Click Execute (▶️) or press F5
4. View results in the Data Output panel

### Backup Database

1. Right-click database → Backup
2. Choose format:
   - **Custom:** Best for pg_restore (recommended)
   - **Tar:** Unix archive format
   - **Plain:** SQL script
3. Set filename and location
4. Configure options (data only, schema only, etc.)
5. Click Backup

### Restore Database

1. Right-click database → Restore
2. Select backup file
3. Choose format (auto-detects from file)
4. Configure options
5. Click Restore

### Create Database

1. Right-click "Databases" → Create → Database
2. **General Tab:**
   - Database name: `myapp_db`
   - Owner: `postgres`
3. Click Save

### Manage Users

1. Right-click "Login/Group Roles" → Create → Login/Group Role
2. **General Tab:** Set username
3. **Definition Tab:** Set password
4. **Privileges Tab:** Configure permissions
5. Click Save

---

## Configuration and Shortcuts

### Keyboard Shortcuts

- **Execute query:** F5
- **Explain query:** F7
- **Explain analyze:** Shift+F7
- **Save:** Ctrl+S (Cmd+S on Mac)
- **New query tab:** Ctrl+T
- **Auto-complete:** Ctrl+Space
- **Comment lines:** Ctrl+/

### Preferences

Access via: File → Preferences

**Useful settings:**
- **Query Tool → Auto-completion:** Enable for suggestions
- **Query Tool → Display:** Set row limit, font size
- **Browser → Display:** Customize tree view
- **Keyboard Shortcuts:** Customize keybindings

---

## Docker Commands

### View Logs

```bash
# Follow logs in real-time
docker logs -f pgadmin

# View last 50 lines
docker logs --tail 50 pgadmin
```

### Restart Container

```bash
docker restart pgadmin
```

### Stop/Start Container

```bash
# Stop
docker stop pgadmin

# Start
docker start pgadmin
```

### Update PgAdmin

```bash
# Pull latest image
docker pull dpage/pgadmin4:latest

# Stop and remove old container
docker stop pgadmin
docker rm pgadmin

# Run installation script again
./install.sh
```

### Backup PgAdmin Configuration

```bash
# Backup to tar.gz file
docker run --rm \
  -v pgadmin_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/pgadmin-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore PgAdmin Configuration

```bash
# Restore from tar.gz file
docker run --rm \
  -v pgadmin_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/pgadmin-backup.tar.gz"
```

---

## Troubleshooting

### Can't Login to PgAdmin

**Check container logs:**
```bash
docker logs pgadmin
```

**Verify credentials:**
```bash
# Check .env file
cat .env | grep PGADMIN_
```

**Restart container:**
```bash
docker restart pgadmin
```

**Reset password (recreate container):**
```bash
docker stop pgadmin && docker rm pgadmin
./install.sh
```

---

### Can't Connect to PostgreSQL from PgAdmin

**Test PostgreSQL from server:**
```bash
psql -h localhost -U postgres -d postgres
```

**Check PostgreSQL is running:**
```bash
sudo systemctl status postgresql
```

**Verify PostgreSQL allows connections:**
```bash
PG_VERSION=$(ls /etc/postgresql/)
sudo cat /etc/postgresql/$PG_VERSION/main/pg_hba.conf | grep "0.0.0.0/0"
# Should show: host all all 0.0.0.0/0 md5
```

**Check firewall (if connecting remotely):**
```bash
# For port 5432 (local)
sudo ufw status | grep 5432

# For port 9552 (via nginx)
sudo ufw status | grep 9552
```

**Test connection from server to PostgreSQL:**
```bash
# Direct connection
psql -h 192.168.1.200 -p 5432 -U postgres -d postgres

# Via nginx proxy
psql "host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=prefer"
```

---

### PgAdmin Not Accessible via HTTPS

**Check nginx configuration:**
```bash
sudo nginx -t
```

**Check if PgAdmin config exists:**
```bash
grep -A 10 "pgadmin.arpansahu.space" /etc/nginx/sites-available/services
```

**Test local access:**
```bash
curl http://localhost:5050
```

**Check nginx logs:**
```bash
sudo tail -50 /var/log/nginx/error.log
```

**Reload nginx:**
```bash
sudo systemctl reload nginx
```

---

### Slow Query Execution

**Check PostgreSQL performance:**
```bash
# Check active connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Check long-running queries
sudo -u postgres psql -c "SELECT pid, now() - query_start as duration, query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC;"
```

**Use EXPLAIN in PgAdmin:**
```sql
EXPLAIN ANALYZE SELECT * FROM your_table WHERE condition;
```

**Enable query caching in PgAdmin:**
- File → Preferences → Query Tool → Results grid
- Enable "Cache data"

---

## Security Best Practices

1. **Strong Password:** Always use a strong password for PgAdmin login
2. **HTTPS Only:** Never access PgAdmin over plain HTTP in production
3. **Keep Updated:** Regularly update PgAdmin to the latest version
4. **Limited Database Access:** Use database users with minimal required permissions
5. **Regular Backups:** Schedule automated backups of important databases
6. **Firewall Rules:** Use firewall to restrict access to PostgreSQL ports
7. **Don't Save Passwords:** Consider using pgpass file instead of saving in PgAdmin
8. **Monitor Logs:** Regularly check PgAdmin and PostgreSQL logs

### Using pgpass File (Alternative to Saving Passwords)

```bash
# Create pgpass file
nano ~/.pgpass

# Add connection details (format: hostname:port:database:username:password)
192.168.1.200:5432:*:postgres:Gandu302postgres
postgres.arpansahu.space:9552:*:postgres:Gandu302postgres

# Set proper permissions (required)
chmod 600 ~/.pgpass
```

---

## Connection Details

### Access Information

- **Web Interface:** https://pgadmin.arpansahu.space
- **Local URL:** http://localhost:5050 (server only)
- **Email:** (from `.env` file)
- **Password:** (from `.env` file)
- **Container Name:** `pgadmin`
- **Docker Volume:** `pgadmin_data`

### PostgreSQL Connection Options

**Option 1: Direct to PostgreSQL (Local Network)**
- Host: `192.168.1.200`
- Port: `5432`
- Username: `postgres`
- Password: `Gandu302postgres`
- SSL: Prefer/Require

**Option 2: Via Nginx Proxy (External Access)**
- Host: `postgres.arpansahu.space`
- Port: `9552`
- Username: `postgres`
- Password: `Gandu302postgres`
- SSL: Prefer/Require

---

## Quick Reference

### Important Files

- **Environment template:** [`.env.example`](./.env.example)
- **Environment config:** `.env` (create from .env.example)
- **Installation script:** [`install.sh`](./install.sh)
- **Nginx setup script:** [`add-nginx-config.sh`](./add-nginx-config.sh)
- **Nginx config:** [`nginx.conf`](./nginx.conf)

### Important Commands

```bash
# Install PgAdmin
./install.sh

# Configure Nginx
sudo ./add-nginx-config.sh

# Access PgAdmin
# Open https://pgadmin.arpansahu.space in your browser

# Container management
docker ps | grep pgadmin
docker logs -f pgadmin
docker restart pgadmin
docker stop pgadmin
docker start pgadmin

# Update PgAdmin
docker pull dpage/pgadmin4:latest
docker stop pgadmin && docker rm pgadmin
./install.sh

# Backup/Restore
docker run --rm -v pgadmin_data:/data -v $(pwd):/backup alpine tar czf /backup/pgadmin-backup.tar.gz -C /data .
```

---

## Database Connection Examples

### Python (psycopg2)

```python
import psycopg2

# Connect to PostgreSQL
conn = psycopg2.connect(
    host="postgres.arpansahu.space",
    port=9552,
    database="arpansahu_one_db",
    user="postgres",
    password="Gandu302postgres",
    sslmode="prefer"
)

# Execute query
cursor = conn.cursor()
cursor.execute("SELECT version();")
print(cursor.fetchone())
cursor.close()
conn.close()
```

### Django Settings

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'arpansahu_one_db',
        'USER': 'postgres',
        'PASSWORD': 'Gandu302postgres',
        'HOST': 'postgres.arpansahu.space',
        'PORT': '9552',
        'OPTIONS': {
            'sslmode': 'prefer',
        }
    }
}
```

### Command Line (psql)

```bash
# Via nginx proxy (external)
psql "host=postgres.arpansahu.space port=9552 user=postgres dbname=arpansahu_one_db sslmode=prefer"

# Direct connection (local network)
psql -h 192.168.1.200 -p 5432 -U postgres -d arpansahu_one_db
```

---

## Related Documentation

- [PostgreSQL Installation](../Postgres/README.md) - Set up PostgreSQL server
- [Redis Setup](../Redis/README.md) - Redis cache server
- [RabbitMQ Setup](../Rabbitmq/README.md) - Message broker

---

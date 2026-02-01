## Portainer - Docker Management UI

Portainer is a lightweight management UI for Docker, allowing you to easily manage containers, images, networks, volumes, and more through a web interface.

**Note:** Portainer is a web-based management interface. Like PgAdmin, it is accessed only through a web browser and does not require programmatic connection testing.

---

## Prerequisites

### Docker Installation Required

**Portainer requires Docker to be installed first.** If Docker is not installed, follow the Docker installation guide:

📄 **[Docker Installation Guide](../docker/docker_installation.md)**

**Quick verification:**
```bash
docker --version
docker compose version
```

Expected output:
```
Docker version 24.0.7 or later
Docker Compose version v2.23.0 or later
```

If these commands fail, Docker is not installed. Install Docker first, then return to this guide.

---

## Step-by-Step Installation Guide

### Step 1: Run Installation Script

Portainer does not require a `.env` file as it doesn't support environment variables for initial user creation. The admin user must be created through the web interface on first access.

**Make the script executable and run:**

```bash
chmod +x install.sh
./install.sh
```

**What the script does:**
1. Creates Docker volume `portainer_data` for persistent storage
2. Runs Portainer container with Docker socket access
3. Binds to localhost:9443 only (HTTPS with self-signed certificate)
4. Verifies the container is running

**Expected output:**
```
=== Portainer Installation Script ===
Step 1: Creating Portainer Volume
✓ Volume created
Step 2: Running Portainer Container
Step 3: Waiting for Portainer to start...
Step 4: Verifying Installation
✓ Portainer container is running
========================================
Portainer installed successfully!
========================================
```

---

### Step 2: Configure Nginx for HTTPS Access

For secure HTTPS access to Portainer, we need to add its configuration to the Nginx services file.

**Run the Nginx configuration script:**

```bash
chmod +x add-nginx-config.sh
sudo ./add-nginx-config.sh
```

**What this script does:**
1. Backs up the current Nginx services configuration
2. Adds Portainer reverse proxy configuration
3. Configures HTTPS with SSL certificates
4. Proxies to Portainer's HTTPS backend (port 9443)
5. Tests and reloads Nginx
6. Verifies Portainer is accessible

**The nginx configuration includes:**
- HTTP to HTTPS redirect
- SSL/TLS encryption using existing certificates
- WebSocket support for real-time updates
- Proxy to Portainer's self-signed HTTPS endpoint
- SSL verification disabled for backend (self-signed cert)

---

### Step 3: Router Port Forwarding (Optional)

**⚠️ Only required for external access (from outside your home network)**

If you want to access Portainer from outside your local network:

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

### Step 4: Create Admin User

**On first access to Portainer, you must create an admin user:**

1. **Open Portainer:** https://portainer.arpansahu.space

2. **Create Admin User:**
   - Username: `arpansahu` (as per creds.txt)
   - Password: `Gandu302@portainer` (as per creds.txt)
   - Confirm Password

3. **Click "Create user"**

4. **Connect to Docker Environment:**
   - Select "Get Started" or "Docker"
   - Portainer will auto-detect the local Docker environment
   - Socket: `/var/run/docker.sock` (already configured)

5. **You should now see the Portainer dashboard** with your Docker containers, images, volumes, etc.

⚠️ **Important:** You must create the admin user within the first 5 minutes of starting Portainer. If you don't, Portainer will disable the setup page for security. If this happens, restart the container: `docker restart portainer`

---

### Step 5: Verify Installation

**Access Portainer in your browser:**

1. Navigate to https://portainer.arpansahu.space
2. Login with the credentials you created
3. You should see the Portainer dashboard with:
   - Container list
   - Image management
   - Volume management
   - Network management
   - And more Docker resources

---

## Common Tasks in Portainer

### Managing Containers

**Start/Stop/Restart:**
1. Go to "Containers" in left sidebar
2. Select container(s)
3. Click action buttons at top or use individual container controls

**View Logs:**
1. Click on container name
2. Click "Logs" tab
3. Use filters and auto-refresh options

**Access Console:**
1. Click on container name
2. Click "Console" tab
3. Select shell (sh, bash, etc.)
4. Click "Connect"

**Inspect Container:**
1. Click on container name
2. View detailed information, environment variables, networks, volumes

### Managing Images

**Pull Images:**
1. Go to "Images" → "Import"
2. Enter image name (e.g., `nginx:latest`)
3. Click "Pull the image"

**Build Images:**
1. Go to "Images" → "Build"
2. Upload Dockerfile or provide URL
3. Configure build options
4. Click "Build the image"

**Remove Images:**
1. Go to "Images"
2. Select image(s)
3. Click "Remove"

### Managing Volumes

**Create Volume:**
1. Go to "Volumes" → "Add volume"
2. Enter volume name
3. Optional: Set driver options
4. Click "Create the volume"

**Browse Volume:**
1. Click on volume name
2. View size and containers using it

### Managing Networks

**Create Network:**
1. Go to "Networks" → "Add network"
2. Enter network name
3. Select driver (bridge, overlay, etc.)
4. Configure options
5. Click "Create the network"

### Stacks (Docker Compose)

**Deploy Stack:**
1. Go to "Stacks" → "Add stack"
2. Enter stack name
3. Paste docker-compose.yml content or upload file
4. Configure environment variables if needed
5. Click "Deploy the stack"

**Update Stack:**
1. Click on stack name
2. Edit YAML content
3. Click "Update the stack"

---

## Docker Commands

### View Logs

```bash
# Follow logs in real-time
docker logs -f portainer

# View last 50 lines
docker logs --tail 50 portainer
```

### Restart Container

```bash
docker restart portainer
```

### Stop/Start Container

```bash
# Stop
docker stop portainer

# Start
docker start portainer
```

### Update Portainer

```bash
# Pull latest image
docker pull portainer/portainer-ce:latest

# Stop and remove old container
docker stop portainer
docker rm portainer

# Run installation script again
./install.sh
```

### Backup Portainer Configuration

```bash
# Backup to tar.gz file
docker run --rm \
  -v portainer_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/portainer-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore Portainer Configuration

```bash
# Restore from tar.gz file
docker run --rm \
  -v portainer_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/portainer-backup.tar.gz"
```

---

## Troubleshooting

### Can't Access Portainer

**Check container is running:**
```bash
docker ps | grep portainer
```

**Check logs:**
```bash
docker logs portainer
```

**Restart container:**
```bash
docker restart portainer
```

---

### Setup Page Timeout

If you see "Portainer instance timed out" or can't create admin user:

**Reason:** Portainer disables the setup page after 5 minutes for security.

**Solution:**
```bash
# Restart container to reset the timer
docker restart portainer

# Wait 10 seconds
sleep 10

# Quickly access https://portainer.arpansahu.space and create user
```

---

### Portainer Not Accessible via HTTPS

**Check nginx configuration:**
```bash
sudo nginx -t
```

**Check if Portainer config exists:**
```bash
grep -A 10 "portainer.arpansahu.space" /etc/nginx/sites-available/services
```

**Test local access:**
```bash
curl -k https://localhost:9443
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

### Lost Admin Password

If you forgot the admin password:

**Option 1: Reset via Docker**
```bash
# Stop portainer
docker stop portainer

# Remove container and volume
docker rm portainer
docker volume rm portainer_data

# Reinstall (loses all settings)
./install.sh
```

**Option 2: Reset Password (if enabled)**
- Some Portainer versions support password reset
- Check Portainer documentation for your version

---

## Security Best Practices

1. **Strong Password:** Use a strong password for the admin account
2. **HTTPS Only:** Always access Portainer over HTTPS, never HTTP
3. **Keep Updated:** Regularly update Portainer to the latest version
4. **Limited Users:** Create specific users with limited permissions for team members
5. **Regular Backups:** Schedule automated backups of Portainer configuration
6. **Audit Logs:** Regularly check Portainer's audit logs for suspicious activity
7. **Firewall Rules:** Use firewall to restrict access
8. **2FA:** Consider enabling two-factor authentication (if available in your version)

---

## Access Details

### Connection Information

- **Web Interface:** https://portainer.arpansahu.space
- **Local URL:** https://localhost:9443 (server only)
- **Username:** arpansahu (as per creds.txt)
- **Password:** Gandu302@portainer (as per creds.txt)
- **Container Name:** `portainer`
- **Docker Volume:** `portainer_data`

---

## Quick Reference

### Important Files

- **Environment template:** [`.env.example`](./.env.example) (reference only)
- **Installation script:** [`install.sh`](./install.sh)
- **Nginx setup script:** [`add-nginx-config.sh`](./add-nginx-config.sh)
- **Nginx config:** [`nginx.conf`](./nginx.conf)

### Important Commands

```bash
# Install Portainer
./install.sh

# Configure Nginx
sudo ./add-nginx-config.sh

# Access Portainer
# Open https://portainer.arpansahu.space in your browser

# Container management
docker ps | grep portainer
docker logs -f portainer
docker restart portainer
docker stop portainer
docker start portainer

# Update Portainer
docker pull portainer/portainer-ce:latest
docker stop portainer && docker rm portainer
./install.sh

# Backup/Restore
docker run --rm -v portainer_data:/data -v $(pwd):/backup alpine tar czf /backup/portainer-backup.tar.gz -C /data .
```

---

## Useful Features

### App Templates

Portainer includes pre-configured app templates for quick deployment:
- Nginx
- MySQL
- Redis
- PostgreSQL
- WordPress
- And many more

Access via: "App Templates" in the left sidebar

### Registry Management

Connect to Docker registries (Docker Hub, private registries, Harbor):
1. Go to "Registries"
2. Click "Add registry"
3. Select type and provide credentials
4. Click "Add registry"

### Edge Computing

Portainer supports managing remote Docker hosts:
1. Install Portainer Edge Agent on remote host
2. Add edge endpoint in Portainer
3. Manage remote Docker from central Portainer instance

---

## Related Documentation

- [PostgreSQL Installation](../Postgres/README.md) - Database server management
- [Redis Setup](../Redis/README.md) - Cache server management  
- [RabbitMQ Setup](../Rabbitmq/README.md) - Message broker management
- [PgAdmin Setup](../Pgadmin/README.md) - PostgreSQL web UI

---

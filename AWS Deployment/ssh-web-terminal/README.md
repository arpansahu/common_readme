## SSH Web Terminal (ttyd)

A web-based terminal using ttyd. Access your server's command line securely through a browser with HTTPS encryption via Nginx.

---

## Step-by-Step Installation Guide

### Step 1: Create Installation Script

Create the `install.sh` script that will automatically install ttyd with openssh-client.

**Create `install.sh` file:**

```bash
#!/bin/bash
set -e

echo "=== SSH Web Terminal (ttyd) Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Stopping existing ttyd container (if any)${NC}"
docker stop ttyd 2>/dev/null || true
docker rm ttyd 2>/dev/null || true

echo -e "${YELLOW}Step 2: Running ttyd Container${NC}"
docker run -d \
  --name ttyd \
  --restart unless-stopped \
  -p 127.0.0.1:8084:7681 \
  tsl0922/ttyd:latest \
  ttyd -W bash

echo -e "${YELLOW}Step 3: Waiting for ttyd to start...${NC}"
sleep 5

echo -e "${YELLOW}Step 4: Installing openssh-client in container${NC}"
docker exec ttyd bash -c 'apt update && apt install -y openssh-client' > /dev/null 2>&1

echo -e "${YELLOW}Step 5: Verifying Installation${NC}"
docker ps | grep ttyd
docker exec ttyd which ssh

echo -e "${GREEN}ttyd installed successfully!${NC}"
echo -e "Local access: http://localhost:8084"
echo -e "Note: No authentication on ttyd - secured via nginx"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy nginx config: sudo cp $(dirname $0)/nginx.conf /etc/nginx/sites-available/ssh-terminal"
echo "2. Enable site: sudo ln -sf /etc/nginx/sites-available/ssh-terminal /etc/nginx/sites-enabled/"
echo "3. Test nginx: sudo nginx -t"
echo "4. Reload nginx: sudo systemctl reload nginx"
echo ""
echo -e "${YELLOW}How it works:${NC}"
echo "- ttyd gives you a bash shell inside the container"
echo "- openssh-client is pre-installed for SSH access"
echo "- Connect to server: ssh username@192.168.1.200"
echo "- Use your server's username and password"
```

**What this script does:**
- Removes any existing ttyd container (for clean reinstall)
- Creates ttyd container on localhost:8084 (not accessible externally)
- Waits for container to start
- Automatically installs openssh-client inside the container
- Verifies SSH is available
- No authentication on ttyd itself (secured by Nginx)

**Make it executable and run:**

```bash
cd "AWS Deployment/ssh-web-terminal"
chmod +x install.sh
./install.sh
```

**Expected output:**
```
=== SSH Web Terminal (ttyd) Installation Script ===
Step 1: Stopping existing ttyd container (if any)
Step 2: Running ttyd Container
Step 3: Waiting for ttyd to start...
Step 4: Installing openssh-client in container
Step 5: Verifying Installation
ttyd
/usr/bin/ssh
ttyd installed successfully!
Local access: http://localhost:8084
```

---

### Step 2: Configure Nginx for HTTPS Access

Create the Nginx configuration to provide secure HTTPS access to ttyd.

**Create `nginx.conf` file:**

```nginx
# SSH Web Terminal (ttyd) - HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name ssh.arpansahu.space;
    return 301 https://$host$request_uri;
}

# SSH Web Terminal (ttyd) - HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ssh.arpansahu.space;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # HTTP Basic Authentication
    auth_basic "SSH Web Terminal";
    auth_basic_user_file /etc/nginx/.htpasswd;

    # Proxy to ttyd
    location / {
        proxy_pass http://127.0.0.1:8084;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # WebSocket support (required for ttyd)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**What this configuration does:**
- Redirects all HTTP traffic to HTTPS (port 80 → 443)
- Serves ttyd on https://ssh.arpansahu.space
- Uses your wildcard SSL certificate for *.arpansahu.space
- **Requires HTTP Basic Authentication** (username/password prompt in browser)
- Enables WebSocket support (required for terminal functionality)
- Proxies requests to ttyd container on localhost:8084

**Security:**
- HTTP Basic Auth protects against unauthorized access
- Password file stored at `/etc/nginx/.htpasswd`
- Only authenticated users can access the terminal

---

### Step 3: Apply Nginx Configuration

You have two options to apply the Nginx configuration:

#### Option 1: Automated (Recommended)

Create `add-nginx-conf.sh` script:

```bash
#!/bin/bash
set -e

echo "=== Adding SSH Web Terminal Nginx Configuration ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Setting up HTTP Basic Authentication${NC}"
if [ ! -f /etc/nginx/.htpasswd ]; then
    echo "Creating password file for SSH Web Terminal access"
    read -p "Enter username for web terminal access: " WEB_USER
    read -sp "Enter password: " WEB_PASS
    echo ""
    
    # Install apache2-utils if not present (for htpasswd command)
    if ! command -v htpasswd &> /dev/null; then
        echo "Installing apache2-utils..."
        sudo apt-get update -qq
        sudo apt-get install -y apache2-utils
    fi
    
    # Create password file
    echo "$WEB_PASS" | sudo htpasswd -ci /etc/nginx/.htpasswd "$WEB_USER"
    echo -e "${GREEN}✓ Password file created${NC}"
else
    echo -e "${GREEN}✓ Password file already exists at /etc/nginx/.htpasswd${NC}"
    echo "To add/update users: sudo htpasswd /etc/nginx/.htpasswd username"
fi
echo ""

echo -e "${YELLOW}Step 2: Backing up existing config (if any)${NC}"
if [ -f /etc/nginx/sites-available/ssh-terminal ]; then
    sudo cp /etc/nginx/sites-available/ssh-terminal \
         /etc/nginx/sites-available/ssh-terminal.backup-$(date +%Y%m%d-%H%M%S)
    echo "Backup created"
else
    echo "No existing config found"
fi

echo -e "${YELLOW}Step 3: Copying nginx.conf to sites-available${NC}"
sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/ssh-terminal

echo -e "${YELLOW}Step 4: Creating symbolic link to sites-enabled${NC}"
sudo ln -sf /etc/nginx/sites-available/ssh-terminal /etc/nginx/sites-enabled/

echo -e "${YELLOW}Step 5: Testing nginx configuration${NC}"
sudo nginx -t

echo -e "${YELLOW}Step 6: Reloading nginx${NC}"
sudo systemctl reload nginx

echo -e "${YELLOW}Step 7: Verifying configuration${NC}"
sudo nginx -T | grep "server_name ssh.arpansahu.space" || echo "Configuration not found in output"

echo -e "${GREEN}SSH Web Terminal Nginx configured successfully!${NC}"
echo -e "${GREEN}Access at: https://ssh.arpansahu.space${NC}"
echo -e "${YELLOW}⚠️  You will be prompted for username/password when accessing${NC}"
```

**Run the script:**

```bash
chmod +x add-nginx-conf.sh
sudo bash add-nginx-conf.sh
```

**Expected output:**
```
=== Adding SSH Web Terminal Nginx Configuration ===
Step 1: Backing up existing config (if any)
No existing config found
Step 2: Copying nginx.conf to sites-available
Step 3: Creating symbolic link to sites-enabled
Step 4: Testing nginx configuration
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
Step 5: Reloading nginx
Step 6: Verifying configuration
server_name ssh.arpansahu.space;
SSH Web Terminal Nginx configured successfully!
Access at: https://ssh.arpansahu.space
```

#### Option 2: Manual Configuration

```bash
# 1. Copy configuration to Nginx sites-available
sudo cp nginx.conf /etc/nginx/sites-available/ssh-terminal

# 2. Enable the site (create symbolic link)
sudo ln -sf /etc/nginx/sites-available/ssh-terminal /etc/nginx/sites-enabled/

# 3. Test Nginx configuration
sudo nginx -t

# 4. Reload Nginx
sudo systemctl reload nginx
```

---

## Testing Your SSH Web Terminal

### Test 1: Access Web Terminal

Open your browser and navigate to:

**URL:** https://ssh.arpansahu.space

You should see a bash terminal in your browser. This is a shell **inside the ttyd Docker container**, not on your server.

---

### Test 2: Verify SSH Client

Inside the web terminal, verify that SSH client is installed:

```bash
# Check SSH version
ssh -V

# Check if SSH command exists
which ssh
```

**Expected output:**
```
OpenSSH_8.x, OpenSSL x.x.x
/usr/bin/ssh
```

---

### Test 3: Connect to Your Server

From the web terminal, SSH to your actual server:

```bash
# SSH to your server (use your server's username)
ssh ${SERVER_USERNAME}@${SERVER_IP}

# Example (replace with your actual values):
ssh arpansahu@192.168.1.200
```

**What happens:**
1. Terminal prompts for password (enter your server's SSH password)
2. You're now connected to your actual server
3. You can run any commands on your server

---

## Connection Details Summary

After successful installation, your SSH Web Terminal setup will have:

- **Container Name:** `ttyd`
- **Local Port:** `127.0.0.1:8084` (localhost only)
- **Public URL:** `https://ssh.arpansahu.space` (accessible from anywhere)
- **Authentication:** HTTP Basic Auth (username/password)
- **Container Shell:** Bash shell inside Docker container
- **SSH Client:** Pre-installed openssh-client
- **Web Authentication:** Required before accessing terminal

**Important:** You'll see TWO authentication prompts:
1. **First:** HTTP Basic Auth (nginx) - username/password in browser popup
2. **Second:** SSH authentication when connecting to your server

---

## Managing Web Access Authentication

### Add New User

```bash
sudo htpasswd /etc/nginx/.htpasswd newusername
```

### Update Existing User Password

```bash
sudo htpasswd /etc/nginx/.htpasswd existing username
```

### Remove User

```bash
sudo htpasswd -D /etc/nginx/.htpasswd username
```

### List All Users

```bash
sudo cat /etc/nginx/.htpasswd
```

### Reload Nginx After Changes

```bash
sudo systemctl reload nginx
```

---

## How to Use SSH Web Terminal

### Basic Usage

1. **Access terminal:** Open https://ssh.arpansahu.space in browser
2. **You're in container:** You start in the ttyd container (not your server)
3. **Connect to server:** Use `ssh ${SERVER_USERNAME}@${SERVER_IP}` to connect to your actual server
4. **Enter password:** Type your server's SSH password when prompted
5. **Work on server:** Now you can run any commands on your server

### Example Workflow

```bash
# Step 1: Check where you are (inside container)
hostname
# Output: random_container_id

# Step 2: SSH to your server
ssh ${SERVER_USERNAME}@${SERVER_IP}
# Enter password when prompted

# Step 3: Now you're on your server
hostname
# Output: your_server_name

# Step 4: Run commands on server
ls -la
docker ps
systemctl status nginx

# Step 5: Exit to go back to container
exit
```

---

## Security Considerations

### Security Architecture

```
[Your Browser] ← HTTPS (encrypted) →
[Nginx Reverse Proxy] ← Local only →
[ttyd Container (bash shell)] → SSH →
[Your Server]
```

**Security layers:**
1. **HTTPS Encryption:** All browser traffic encrypted via SSL
2. **Nginx Protection:** ttyd only accessible through Nginx
3. **SSH Authentication:** Server access requires SSH password/key
4. **Container Isolation:** ttyd runs in isolated Docker container

### Important Notes

1. **No Web Authentication:** ttyd itself has no password (protected by Nginx SSL)
2. **Container Shell:** You start in a container, not on your server
3. **SSH Required:** Must use `ssh` command to access your actual server
4. **Server Credentials:** Use your server's SSH username/password
5. **Localhost Binding:** ttyd container only binds to 127.0.0.1

### Best Practices

1. **Use SSH Keys:** Set up SSH key authentication instead of passwords
2. **Firewall Protection:** Ensure ttyd port 8084 is not exposed to internet
3. **Regular Updates:** Keep ttyd Docker image updated
4. **Monitor Access:** Check nginx access logs for suspicious activity
5. **Strong Server Password:** Use strong password/SSH keys on your server

---

## Troubleshooting

### Container Issues

If ttyd container is not running:

```bash
# Check container status
docker ps | grep ttyd

# View container logs
docker logs ttyd

# Restart container
docker restart ttyd

# Remove and reinstall
docker stop ttyd
docker rm ttyd
./install.sh
```

---

### Can't Access Web Interface

If you cannot open https://ssh.arpansahu.space:

```bash
# Check if container is running
docker ps | grep ttyd

# Check if port is listening
sudo ss -lntp | grep 8084

# Test local access
curl http://localhost:8084

# Check Nginx configuration
sudo nginx -T | grep "server_name ssh.arpansahu.space"

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

---

### Nginx Returns 404

This usually means duplicate server blocks:

```bash
# Find all configs for ssh.arpansahu.space
sudo grep -rn "server_name ssh.arpansahu.space" /etc/nginx/

# Remove duplicate configs (keep only ssh-terminal)
sudo rm /etc/nginx/sites-enabled/old-config-name

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

**Common issue:** Old Guacamole or other configs in `/etc/nginx/sites-available/services` can conflict.

---

### SSH Client Not Found

If `ssh` command doesn't work inside terminal:

```bash
# Install SSH client (run on server, not in web terminal)
docker exec ttyd apt update
docker exec ttyd apt install -y openssh-client

# Verify installation
docker exec ttyd which ssh
```

---

### WebSocket Connection Failed

If terminal shows connection errors:

```bash
# Check Nginx WebSocket headers
sudo nginx -T | grep -A 5 "proxy_pass http://127.0.0.1:8084"

# Ensure these lines exist:
# proxy_http_version 1.1;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";

# Restart Nginx
sudo systemctl restart nginx
```

---

## Maintenance Operations

### View Real-time Logs

```bash
# View ttyd container logs
docker logs -f ttyd

# View Nginx access logs
sudo tail -f /var/log/nginx/access.log | grep ssh.arpansahu.space

# View Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

---

### Update ttyd

To update to the latest ttyd version:

```bash
# Pull latest image
docker pull tsl0922/ttyd:latest

# Stop and remove old container
docker stop ttyd
docker rm ttyd

# Run installation again
./install.sh
```

---

### Restart Services

```bash
# Restart ttyd container
docker restart ttyd

# Restart Nginx
sudo systemctl restart nginx

# Check status
docker ps | grep ttyd
sudo systemctl status nginx
```

---

### Backup Configuration

```bash
# Backup Nginx config
sudo cp /etc/nginx/sites-available/ssh-terminal \
  ~/backups/ssh-terminal-$(date +%Y%m%d).conf

# Backup installation script
cp install.sh ~/backups/install-$(date +%Y%m%d).sh
```

---

## Advanced Configuration

### Adding Multiple Users (SSH Keys)

For better security, use SSH keys instead of passwords:

```bash
# On your local machine, generate SSH key pair
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to server
ssh-copy-id ${SERVER_USERNAME}@${SERVER_IP}

# Now you can SSH without password
ssh ${SERVER_USERNAME}@${SERVER_IP}
```

---

### Custom Container Port

To use a different port:

```bash
# Edit install.sh and change:
-p 127.0.0.1:8084:7681

# To your desired port (e.g., 8085):
-p 127.0.0.1:8085:7681

# Also update nginx.conf:
proxy_pass http://127.0.0.1:8085;
```

---

## Quick Reference

### Important Files

- **Installation script:** [`install.sh`](./install.sh)
- **Nginx configuration:** [`nginx.conf`](./nginx.conf)
- **Nginx setup script:** [`add-nginx-conf.sh`](./add-nginx-conf.sh)

### Important Commands

```bash
# Install ttyd
./install.sh

# Configure Nginx (automated)
sudo bash add-nginx-conf.sh

# Or configure Nginx (manual)
sudo cp nginx.conf /etc/nginx/sites-available/ssh-terminal
sudo ln -sf /etc/nginx/sites-available/ssh-terminal /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Access terminal
# Open browser: https://ssh.arpansahu.space

# SSH to server (from web terminal)
ssh ${SERVER_USERNAME}@${SERVER_IP}

# View logs
docker logs -f ttyd

# Restart container
docker restart ttyd

# Check status
docker ps | grep ttyd
```

---

## Architecture Diagram

```
[Browser]
    ↓ HTTPS (encrypted)
[Nginx Reverse Proxy] ← Port 443
    ↓ HTTP (localhost only)
[ttyd Container] ← Port 8084
    ↓ Bash Shell
[openssh-client]
    ↓ SSH connection
[Your Server] ← Port 22
```

**Data Flow:**
1. Browser connects to Nginx via HTTPS
2. Nginx proxies to ttyd on localhost:8084
3. ttyd provides web-based terminal (container shell)
4. User runs `ssh` command to connect to server
5. SSH client connects to actual server on port 22

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

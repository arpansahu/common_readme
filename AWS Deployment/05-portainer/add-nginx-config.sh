#!/bin/bash
set -e

echo "=== Portainer Nginx Configuration Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Backing up services config${NC}"
cp /etc/nginx/sites-available/services /etc/nginx/sites-available/services.backup-portainer-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding Portainer configuration to services file${NC}"

# Check if Portainer config already exists
if grep -q "portainer.arpansahu.space" /etc/nginx/sites-available/services; then
    echo -e "${YELLOW}Portainer configuration already exists, skipping...${NC}"
else
    # Add Portainer configuration before the last closing brace
    cat >> /etc/nginx/sites-available/services << 'EOF'

# Portainer
server {
    listen 80;
    listen [::]:80;
    server_name portainer.arpansahu.space;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name portainer.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass https://127.0.0.1:9443;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Disable SSL verification for self-signed cert
        proxy_ssl_verify off;
    }
}
EOF
    echo -e "${GREEN}Portainer configuration added${NC}"
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed!${NC}"
    echo "Restoring backup..."
    cp /etc/nginx/sites-available/services.backup-portainer-$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/services
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${YELLOW}Step 5: Verifying Portainer is accessible${NC}"
sleep 2
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:9443 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Portainer is accessible on port 9443${NC}"
else
    echo -e "${RED}✗ Portainer is not responding${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Portainer Nginx Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Portainer is now accessible via:"
echo "  - Local: https://localhost:9443"
echo "  - HTTPS: https://portainer.arpansahu.space"
echo ""
echo "Test connection:"
echo "  curl https://portainer.arpansahu.space"

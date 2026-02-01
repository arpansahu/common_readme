#!/bin/bash
set -e

echo "=== PgAdmin Nginx Configuration Script ==="

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
cp /etc/nginx/sites-available/services /etc/nginx/sites-available/services.backup-pgadmin-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding PgAdmin configuration to services file${NC}"

# Check if PgAdmin config already exists
if grep -q "pgadmin.arpansahu.space" /etc/nginx/sites-available/services; then
    echo -e "${YELLOW}PgAdmin configuration already exists, skipping...${NC}"
else
    # Add PgAdmin configuration before the last closing brace
    cat >> /etc/nginx/sites-available/services << 'EOF'

# PgAdmin
server {
    listen 80;
    listen [::]:80;
    server_name pgadmin.arpansahu.space;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name pgadmin.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://127.0.0.1:5050;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF
    echo -e "${GREEN}PgAdmin configuration added${NC}"
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed!${NC}"
    echo "Restoring backup..."
    cp /etc/nginx/sites-available/services.backup-pgadmin-$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/services
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${YELLOW}Step 5: Verifying PgAdmin is accessible${NC}"
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5050 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ PgAdmin is accessible on port 5050${NC}"
else
    echo -e "${RED}✗ PgAdmin is not responding${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PgAdmin Nginx Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "PgAdmin is now accessible via:"
echo "  - Local: http://localhost:5050"
echo "  - HTTPS: https://pgadmin.arpansahu.space"
echo ""
echo "Test connection:"
echo "  curl https://pgadmin.arpansahu.space"

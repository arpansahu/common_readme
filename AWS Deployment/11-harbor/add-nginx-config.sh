#!/bin/bash
set -e

echo "=== Harbor Nginx Configuration Script ==="

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

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Backing up services config${NC}"
if [ -f /etc/nginx/sites-available/services ]; then
    cp /etc/nginx/sites-available/services /etc/nginx/sites-available/services.backup-harbor-$(date +%Y%m%d-%H%M%S)
fi

echo -e "${YELLOW}Step 2: Adding Harbor configuration to services file${NC}"

# Check if Harbor config already exists
if grep -q "harbor.arpansahu.space" /etc/nginx/sites-available/services; then
    echo -e "${YELLOW}Harbor configuration already exists, skipping...${NC}"
else
    # Add Harbor configuration
    cat >> /etc/nginx/sites-available/services << EOF

# Harbor - Container Registry
server {
    listen 80;
    listen [::]:80;
    server_name ${HARBOR_HOSTNAME};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${HARBOR_HOSTNAME};

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Large file uploads (Docker images can be large)
    client_max_body_size 1024M;
    client_body_timeout 300s;

    location / {
        proxy_pass http://127.0.0.1:${HARBOR_HTTP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # WebSocket support for Harbor UI
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts for large image uploads
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
EOF
    echo -e "${GREEN}Harbor configuration added${NC}"
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed! Restoring backup...${NC}"
    if [ -f /etc/nginx/sites-available/services.backup-harbor-$(date +%Y%m%d)* ]; then
        cp /etc/nginx/sites-available/services.backup-harbor-* /etc/nginx/sites-available/services
    fi
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${YELLOW}Step 5: Verifying Harbor is accessible${NC}"
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost:${HARBOR_HTTP_PORT} | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Harbor is accessible on port ${HARBOR_HTTP_PORT}${NC}"
else
    echo -e "${RED}✗ Harbor is not responding${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Harbor Nginx Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Harbor is now accessible via:"
echo "  - Local: http://localhost:${HARBOR_HTTP_PORT}"
echo "  - HTTPS: https://${HARBOR_HOSTNAME}"
echo ""
echo "Test connection:"
echo "  curl https://${HARBOR_HOSTNAME}"

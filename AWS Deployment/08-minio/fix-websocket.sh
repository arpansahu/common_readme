#!/bin/bash
set -e

echo "=== MinIO WebSocket Fix Script ==="

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

echo -e "${YELLOW}Step 1: Backing up services config${NC}"
cp /etc/nginx/sites-available/services /etc/nginx/sites-available/services.backup-websocket-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Checking if WebSocket config exists${NC}"
if grep -A 5 "minio.arpansahu.space" /etc/nginx/sites-available/services | grep -q "Upgrade"; then
    echo -e "${GREEN}WebSocket configuration already exists${NC}"
    exit 0
fi

echo -e "${YELLOW}Step 3: Adding WebSocket support to MinIO Console${NC}"

# Use sed to add WebSocket headers after proxy_set_header X-Forwarded-Proto https;
sed -i '/server_name minio.arpansahu.space;/,/^}$/ {
    /proxy_set_header X-Forwarded-Proto https;/a\
        \
        # WebSocket support\
        proxy_http_version 1.1;\
        proxy_set_header Upgrade $http_upgrade;\
        proxy_set_header Connection "upgrade";\
        \
        # Buffering\
        proxy_buffering off;\
        proxy_request_buffering off;
}' /etc/nginx/sites-available/services

echo -e "${YELLOW}Step 4: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed! Restoring backup...${NC}"
    cp /etc/nginx/sites-available/services.backup-websocket-$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/services
    exit 1
fi

echo -e "${YELLOW}Step 5: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}WebSocket Fix Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "MinIO Console WebSocket should now work at:"
echo "  https://minio.arpansahu.space"
echo ""
echo "Refresh your browser and check the console for WebSocket errors."

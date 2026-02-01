#!/bin/bash

# Airtel Router Admin Panel - Nginx Configuration Script
# This script adds nginx reverse proxy configuration for accessing the Airtel router admin panel via HTTPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available/services"
DOMAIN="airtel.arpansahu.space"
ROUTER_IP="192.168.1.1"
ROUTER_PORT="81"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Airtel Router Nginx Configuration${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Error: Nginx is not installed${NC}"
    exit 1
fi

# Verify SSL certificates exist
SSL_CERT="/etc/nginx/ssl/arpansahu.space/fullchain.pem"
SSL_KEY="/etc/nginx/ssl/arpansahu.space/privkey.pem"

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo -e "${RED}Error: SSL certificates not found at /etc/nginx/ssl/arpansahu.space/${NC}"
    echo "Please ensure SSL certificates are installed first."
    exit 1
fi

# Check if configuration already exists
if grep -q "$DOMAIN" "$NGINX_SITES_AVAILABLE" 2>/dev/null; then
    echo -e "${YELLOW}Warning: Configuration for $DOMAIN already exists${NC}"
    read -p "Do you want to replace it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    
    # Remove existing configuration
    sed -i "/# Airtel Router Admin Panel/,/^}/d" "$NGINX_SITES_AVAILABLE"
    echo -e "${GREEN}✓ Removed existing configuration${NC}"
fi

# Add new configuration to services file
echo -e "${GREEN}Adding Airtel router configuration to nginx...${NC}"

cat >> "$NGINX_SITES_AVAILABLE" << 'EOF'

# Airtel Router Admin Panel
server {
    listen 80;
    listen [::]:80;
    server_name airtel.arpansahu.space;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name airtel.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://192.168.1.1:81;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts for router admin panel
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

echo -e "${GREEN}✓ Configuration added${NC}"

# Test nginx configuration
echo -e "${GREEN}Testing nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration test passed${NC}"
else
    echo -e "${RED}✗ Nginx configuration test failed${NC}"
    echo "Rolling back changes..."
    sed -i "/# Airtel Router Admin Panel/,/^}/d" "$NGINX_SITES_AVAILABLE"
    exit 1
fi

# Reload nginx
echo -e "${GREEN}Reloading nginx...${NC}"
systemctl reload nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}✗ Failed to reload nginx${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Configuration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Airtel Router Admin Panel is now accessible at:"
echo -e "${YELLOW}https://airtel.arpansahu.space${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "1. Ensure router admin port is set to ${ROUTER_PORT} (not 80)"
echo -e "2. Access router admin at: http://${ROUTER_IP}:${ROUTER_PORT} locally"
echo -e "3. DNS record for ${DOMAIN} must point to your server IP"
echo ""
echo -e "To test access:"
echo -e "  ${YELLOW}curl -I https://${DOMAIN}${NC}"
echo ""

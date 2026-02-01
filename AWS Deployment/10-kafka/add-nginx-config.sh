#!/bin/bash
set -e

echo "=== Kafka AKHQ Nginx Configuration Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi

NGINX_CONFIG="/etc/nginx/sites-available/services"

echo -e "${YELLOW}Step 1: Backing up nginx configuration${NC}"
if [ -f "$NGINX_CONFIG" ]; then
    sudo cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backup created"
else
    echo "Creating new services file"
    sudo touch "$NGINX_CONFIG"
fi

echo -e "${YELLOW}Step 2: Adding Kafka AKHQ configuration${NC}"

# Check if configuration already exists
if sudo grep -q "# Kafka AKHQ" "$NGINX_CONFIG"; then
    echo "Kafka AKHQ configuration already exists, skipping..."
else
    sudo tee -a "$NGINX_CONFIG" > /dev/null <<EOF

# Kafka AKHQ - Kafka UI
server {
    listen 80;
    listen [::]:80;
    server_name kafka.arpansahu.space;
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name kafka.arpansahu.space;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/arpansahu.space/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        proxy_pass http://localhost:${AKHQ_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        
        # Buffering
        proxy_buffering off;
    }
}
EOF
    echo "Configuration added"
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed!${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
sudo systemctl reload nginx

echo -e "${YELLOW}Step 5: Enabling nginx sites${NC}"
if [ ! -L "/etc/nginx/sites-enabled/services" ]; then
    sudo ln -s "$NGINX_CONFIG" /etc/nginx/sites-enabled/services
    sudo systemctl reload nginx
fi

echo -e "${YELLOW}Step 6: Verifying AKHQ is accessible${NC}"
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost:${AKHQ_PORT} | grep -q "200\|302"; then
    echo -e "${GREEN}✓ AKHQ is accessible${NC}"
else
    echo -e "${YELLOW}⚠ AKHQ might still be starting up${NC}"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kafka AKHQ Nginx Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "AKHQ is now accessible via:"
echo "  - Local: http://localhost:${AKHQ_PORT}"
echo "  - HTTPS: https://kafka.arpansahu.space"
echo ""
echo "Login credentials:"
echo "  - Username: ${AKHQ_ADMIN_USERNAME}"
echo "  - Password: (from .env)"
echo ""
echo "Test connection:"
echo "  curl https://kafka.arpansahu.space"

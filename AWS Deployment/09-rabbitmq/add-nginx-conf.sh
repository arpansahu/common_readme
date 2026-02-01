#!/bin/bash
set -e

echo "=== Adding RabbitMQ Nginx Configuration ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Backing up existing config (if any)${NC}"
if [ -f /etc/nginx/sites-available/rabbitmq ]; then
    sudo cp /etc/nginx/sites-available/rabbitmq \
         /etc/nginx/sites-available/rabbitmq.backup-$(date +%Y%m%d-%H%M%S)
    echo "Backup created"
else
    echo "No existing config found"
fi

echo -e "${YELLOW}Step 2: Copying nginx.conf to sites-available${NC}"
sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/rabbitmq

echo -e "${YELLOW}Step 3: Creating symbolic link to sites-enabled${NC}"
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/

echo -e "${YELLOW}Step 4: Testing nginx configuration${NC}"
sudo nginx -t

echo -e "${YELLOW}Step 5: Reloading nginx${NC}"
sudo systemctl reload nginx

echo -e "${YELLOW}Step 6: Verifying configuration${NC}"
sudo nginx -T | grep "server_name rabbitmq.arpansahu.space" || echo "Configuration not found in output"

echo -e "${GREEN}RabbitMQ Nginx configured successfully!${NC}"
echo -e "Access at: https://rabbitmq.arpansahu.space"

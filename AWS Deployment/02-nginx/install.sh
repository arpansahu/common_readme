#!/bin/bash
set -e

echo "=== Nginx Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Updating package list${NC}"
sudo apt update

echo -e "${YELLOW}Step 2: Installing Nginx${NC}"
sudo apt install -y nginx

echo -e "${YELLOW}Step 3: Starting Nginx${NC}"
sudo systemctl start nginx
sudo systemctl enable nginx

echo -e "${YELLOW}Step 4: Configuring firewall${NC}"
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

echo -e "${YELLOW}Step 5: Verifying Installation${NC}"
sudo systemctl status nginx --no-pager

echo -e "${GREEN}Nginx installed successfully!${NC}"
echo -e "Test: http://localhost"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure DNS A records for your domain"
echo "2. Create service configurations in /etc/nginx/sites-available/"
echo "3. Enable sites with: sudo ln -sf /etc/nginx/sites-available/SERVICE /etc/nginx/sites-enabled/"
echo "4. Test config: sudo nginx -t"
echo "5. Reload: sudo systemctl reload nginx"
echo "6. Install SSL certificates (see README.md SSL section)"

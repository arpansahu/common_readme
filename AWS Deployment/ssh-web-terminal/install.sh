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

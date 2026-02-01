#!/bin/bash
set -e

echo "=== Portainer Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Creating Portainer Volume${NC}"
if docker volume ls | grep -q "portainer_data"; then
    echo "Volume portainer_data already exists"
else
    docker volume create portainer_data
    echo -e "${GREEN}✓ Volume created${NC}"
fi

echo -e "${YELLOW}Step 2: Running Portainer Container${NC}"
docker run -d \
  --name portainer \
  --restart unless-stopped \
  -p 127.0.0.1:9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo -e "${YELLOW}Step 3: Waiting for Portainer to start...${NC}"
sleep 10

echo -e "${YELLOW}Step 4: Verifying Installation${NC}"
if docker ps | grep -q portainer; then
    echo -e "${GREEN}✓ Portainer container is running${NC}"
else
    echo -e "${RED}✗ Portainer container failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Portainer installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Access Portainer:"
echo "  Local: https://localhost:9443"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add nginx configuration to /etc/nginx/sites-available/services"
echo "2. Test nginx: sudo nginx -t"
echo "3. Reload nginx: sudo systemctl reload nginx"
echo "4. Access via: https://portainer.arpansahu.space"
echo "5. Create admin user on first access"


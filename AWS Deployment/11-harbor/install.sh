#!/bin/bash
set -e

echo "=== Harbor Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${GREEN}Loading configuration from .env${NC}"
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env from .env.example"
    exit 1
fi

# Configuration
HARBOR_INSTALL_DIR="${HOME}/harbor"

echo -e "${YELLOW}Step 1: Downloading Harbor ${HARBOR_VERSION}${NC}"
if [ -d "$HARBOR_INSTALL_DIR" ]; then
    echo -e "${YELLOW}Harbor directory exists. Removing old installation...${NC}"
    rm -rf "$HARBOR_INSTALL_DIR"
fi

cd /tmp
if [ ! -f "harbor-offline-installer-${HARBOR_VERSION}.tgz" ]; then
    wget https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-offline-installer-${HARBOR_VERSION}.tgz
fi

echo -e "${YELLOW}Step 2: Extracting Harbor${NC}"
cd /tmp
tar xzf harbor-offline-installer-${HARBOR_VERSION}.tgz
mv harbor "$HARBOR_INSTALL_DIR"

echo -e "${YELLOW}Step 3: Configuring Harbor${NC}"
cd "$HARBOR_INSTALL_DIR"
cp harbor.yml.tmpl harbor.yml

# Update configuration
sed -i "s/hostname: .*/hostname: ${HARBOR_HOSTNAME}/" harbor.yml
sed -i "s/port: 80/port: ${HARBOR_HTTP_PORT}/" harbor.yml
sed -i "s/harbor_admin_password: .*/harbor_admin_password: ${HARBOR_ADMIN_PASSWORD}/" harbor.yml
sed -i "s/password: root123/password: ${HARBOR_DB_PASSWORD}/" harbor.yml
sed -i "s|data_volume: /data|data_volume: ${HARBOR_DATA_VOLUME}|" harbor.yml

# Disable HTTPS (we use nginx for SSL termination)
sed -i '/^https:/,/^  certificate:/ s/^/#/' harbor.yml

echo -e "${YELLOW}Step 4: Installing Harbor${NC}"
sudo ./install.sh

echo -e "${YELLOW}Step 5: Verifying Installation${NC}"
sleep 5
docker compose ps

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Harbor installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Harbor is accessible at:"
echo "  - Local: http://localhost:${HARBOR_HTTP_PORT}"
echo "  - Username: admin"
echo "  - Password: ${HARBOR_ADMIN_PASSWORD}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure nginx: cd \"$SCRIPT_DIR\" && sudo ./add-nginx-config.sh"
echo "2. Access via HTTPS: https://${HARBOR_HOSTNAME}"
echo "3. Configure router port forwarding for external access"

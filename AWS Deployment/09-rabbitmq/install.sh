#!/bin/bash
set -e

echo "=== RabbitMQ Installation Script ==="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
    echo -e "${GREEN}Loaded configuration from .env file${NC}"
else
    echo -e "${YELLOW}Warning: .env file not found. Using defaults.${NC}"
    echo -e "${YELLOW}Please copy .env.example to .env and configure it.${NC}"
fi

# Configuration with defaults
RABBITMQ_USER="${RABBITMQ_USER:-admin}"
RABBITMQ_PASS="${RABBITMQ_PASS:-changeme}"

echo -e "${YELLOW}Step 1: Fixing Docker IPv4/MTU Issues${NC}"
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "mtu": 1400
}
EOF

echo -e "${GREEN}Restarting Docker...${NC}"
sudo systemctl restart docker
sleep 3

echo -e "${YELLOW}Step 2: Creating Persistent Data Directory${NC}"
sudo mkdir -p /var/lib/rabbitmq
sudo chown -R 999:999 /var/lib/rabbitmq

echo -e "${YELLOW}Step 3: Running RabbitMQ Container${NC}"
docker run -d \
  --name rabbitmq \
  --restart unless-stopped \
  -p 127.0.0.1:5672:5672 \
  -p 127.0.0.1:15672:15672 \
  -e RABBITMQ_DEFAULT_USER="$RABBITMQ_USER" \
  -e RABBITMQ_DEFAULT_PASS="$RABBITMQ_PASS" \
  -v /var/lib/rabbitmq:/var/lib/rabbitmq \
  rabbitmq:3-management

echo -e "${YELLOW}Step 4: Waiting for RabbitMQ to start...${NC}"
sleep 10

echo -e "${YELLOW}Step 5: Verifying Installation${NC}"
docker ps | grep rabbitmq

echo -e "${GREEN}RabbitMQ installed successfully!${NC}"
echo -e "Management UI: http://localhost:15672"
echo -e "Username: $RABBITMQ_USER"
echo -e "Password: $RABBITMQ_PASS"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy nginx config: sudo cp $(dirname $0)/nginx.conf /etc/nginx/sites-available/rabbitmq"
echo "2. Enable site: sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/"
echo "3. Test nginx: sudo nginx -t"
echo "4. Reload nginx: sudo systemctl reload nginx"

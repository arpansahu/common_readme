#!/bin/bash
set -e

echo "=== Redis Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
REDIS_PASSWORD="${REDIS_PASSWORD:-Kesar302redis}"
REDIS_PORT="${REDIS_PORT:-6380}"

echo -e "${YELLOW}Step 1: Running Redis Container${NC}"
docker run -d \
  --name redis-external \
  --restart unless-stopped \
  -p 127.0.0.1:${REDIS_PORT}:6379 \
  redis:7 \
  redis-server --requirepass "$REDIS_PASSWORD"

echo -e "${YELLOW}Step 2: Waiting for Redis to start...${NC}"
sleep 3

echo -e "${YELLOW}Step 3: Verifying Installation${NC}"
docker ps | grep redis-external

echo -e "${GREEN}Redis installed successfully!${NC}"
echo -e "Container: redis-external"
echo -e "Port: 127.0.0.1:${REDIS_PORT}"
echo -e "Password: $REDIS_PASSWORD"
echo ""
echo -e "${YELLOW}Test connection:${NC}"
echo "redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a $REDIS_PASSWORD ping"
echo ""
echo -e "${YELLOW}Next steps for HTTPS access:${NC}"
echo "1. Configure Nginx stream block in /etc/nginx/nginx.conf"
echo "2. See nginx-stream.conf for configuration"
echo "3. Test and reload: sudo nginx -t && sudo systemctl reload nginx"

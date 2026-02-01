#!/bin/bash
set -e

echo "=== PgAdmin Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}Loading configuration from .env${NC}"
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Configuration with defaults
PGADMIN_EMAIL="${PGADMIN_EMAIL:-admin@arpansahu.me}"
PGADMIN_PASSWORD="${PGADMIN_PASSWORD}"
PGADMIN_PORT="${PGADMIN_PORT:-5050}"

if [ -z "$PGADMIN_PASSWORD" ]; then
    echo -e "${RED}Error: PGADMIN_PASSWORD not set in .env${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating Docker volume for PgAdmin data${NC}"
if docker volume ls | grep -q "pgadmin_data"; then
    echo "Volume pgadmin_data already exists"
else
    docker volume create pgadmin_data
    echo -e "${GREEN}✓ Volume created${NC}"
fi

echo -e "${YELLOW}Step 2: Running PgAdmin Container${NC}"
docker run -d \
  --name pgadmin \
  --restart unless-stopped \
  -p 127.0.0.1:${PGADMIN_PORT}:80 \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -v pgadmin_data:/var/lib/pgadmin \
  dpage/pgadmin4:latest

echo -e "${YELLOW}Step 3: Waiting for PgAdmin to start...${NC}"
sleep 10

echo -e "${YELLOW}Step 4: Verifying Installation${NC}"
if docker ps | grep -q pgadmin; then
    echo -e "${GREEN}✓ PgAdmin container is running${NC}"
else
    echo -e "${RED}✗ PgAdmin container failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PgAdmin installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Access PgAdmin:"
echo "  Local: http://localhost:${PGADMIN_PORT}"
echo "  Email: $PGADMIN_EMAIL"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add nginx configuration to /etc/nginx/sites-available/services"
echo "2. Test nginx: sudo nginx -t"
echo "3. Reload nginx: sudo systemctl reload nginx"
echo "4. Access via: https://pgadmin.arpansahu.space"


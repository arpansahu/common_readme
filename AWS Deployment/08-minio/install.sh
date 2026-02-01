#!/bin/bash
set -e

echo "=== MinIO Installation Script ==="

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
MINIO_ROOT_USER="${MINIO_ROOT_USER:-arpansahu}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD}"
DATA_DIR="${HOME}/minio/data"

if [ -z "$MINIO_ROOT_PASSWORD" ]; then
    echo -e "${RED}Error: MINIO_ROOT_PASSWORD not set in .env${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating MinIO Directory${NC}"
mkdir -p "$DATA_DIR"
echo -e "${GREEN}✓ Directory created${NC}"

echo -e "${YELLOW}Step 2: Running MinIO Container${NC}"
docker run -d \
  --name minio \
  --restart unless-stopped \
  -p 127.0.0.1:9000:9000 \
  -p 127.0.0.1:9002:9001 \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  -v "$DATA_DIR":/data \
  quay.io/minio/minio:latest \
  server /data --console-address ":9001"

echo -e "${YELLOW}Step 3: Waiting for MinIO to start...${NC}"
sleep 10

echo -e "${YELLOW}Step 4: Verifying Installation${NC}"
if docker ps | grep -q minio; then
    echo -e "${GREEN}✓ MinIO container is running${NC}"
else
    echo -e "${RED}✗ MinIO container failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MinIO installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Access MinIO:"
echo "  Console (local): http://localhost:9002"
echo "  API (local): http://localhost:9000"
echo "  Username: $MINIO_ROOT_USER"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add nginx configuration to /etc/nginx/sites-available/services"
echo "2. Test nginx: sudo nginx -t"
echo "3. Reload nginx: sudo systemctl reload nginx"
echo "4. Access Console: https://minio.arpansahu.space"
echo "5. Access API: https://minioapi.arpansahu.space"
echo "6. Create bucket and access keys in the Console"


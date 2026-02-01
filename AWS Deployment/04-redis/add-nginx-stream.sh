#!/bin/bash
set -e

echo "=== Adding Redis Stream Block to Nginx ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Backing up nginx.conf${NC}"
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding stream block from nginx-stream.conf${NC}"
# Remove the comment line and add to nginx.conf
grep -v "^# Add this to" "$SCRIPT_DIR/nginx-stream.conf" | sudo tee -a /etc/nginx/nginx.conf > /dev/null

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
sudo nginx -t

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
sudo systemctl reload nginx

echo -e "${YELLOW}Step 5: Verifying port 9551${NC}"
ss -lntp | grep 9551 || echo "Port not yet visible (may need a moment)"

echo -e "${GREEN}Redis TLS stream configured successfully!${NC}"
echo -e "Test with: redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a PASSWORD ping"

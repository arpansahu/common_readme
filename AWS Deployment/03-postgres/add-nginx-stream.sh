#!/bin/bash
set -e

echo "=== PostgreSQL Nginx Stream Configuration Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Backing up nginx.conf${NC}"
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup-postgres-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding PostgreSQL stream configuration${NC}"
# Check if stream block already exists
if ! grep -q "stream {" /etc/nginx/nginx.conf; then
    echo -e "${RED}Error: Stream block not found in nginx.conf${NC}"
    echo "Please ensure nginx is compiled with stream module"
    exit 1
fi

# Check if PostgreSQL stream config already exists
if grep -q "# PostgreSQL TLS Proxy" /etc/nginx/nginx.conf; then
    echo -e "${YELLOW}PostgreSQL stream configuration already exists, skipping...${NC}"
else
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Insert the configuration before the closing brace of the stream block
    # Read the stream config and append it
    grep -v "^# Add this to" "$SCRIPT_DIR/nginx-stream.conf" | \
        sed -i '/^stream {/r /dev/stdin' /etc/nginx/nginx.conf
    
    echo -e "${GREEN}PostgreSQL stream configuration added${NC}"
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed!${NC}"
    echo "Restoring backup..."
    cp /etc/nginx/nginx.conf.backup-postgres-$(date +%Y%m%d-%H%M%S) /etc/nginx/nginx.conf
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${YELLOW}Step 5: Checking if port 9552 is listening${NC}"
sleep 2
if ss -lntp | grep -q ":9552"; then
    echo -e "${GREEN}✓ Nginx is listening on port 9552${NC}"
else
    echo -e "${RED}✗ Port 9552 is not listening${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PostgreSQL Nginx Stream Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "PostgreSQL is now accessible via:"
echo "  - Local: localhost:5432"
echo "  - TLS (via nginx): postgres.arpansahu.space:9552"
echo ""
echo "Test connection:"
echo "  psql 'host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=require'"

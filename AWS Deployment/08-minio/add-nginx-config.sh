#!/bin/bash
set -e

echo "=== MinIO Nginx Configuration Script ==="

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Backing up services config${NC}"
cp /etc/nginx/sites-available/services /etc/nginx/sites-available/services.backup-minio-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding MinIO configuration to services file${NC}"

# Check if MinIO config already exists
if grep -q "minio.arpansahu.space" /etc/nginx/sites-available/services; then
    echo -e "${YELLOW}MinIO configuration already exists, skipping...${NC}"
else
    # Add MinIO Console configuration
    cat >> /etc/nginx/sites-available/services << 'EOF'

# MinIO Console
server {
    listen 80;
    listen [::]:80;
    server_name minio.arpansahu.space;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name minio.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 500M;

    location / {
        proxy_pass http://127.0.0.1:9002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_buffering off;
        proxy_request_buffering off;
    }
}

# MinIO API
server {
    listen 80;
    listen [::]:80;
    server_name minioapi.arpansahu.space;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name minioapi.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 500M;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
        
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }
}
EOF
    echo -e "${GREEN}MinIO configuration added${NC}"
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed!${NC}"
    echo "Restoring backup..."
    cp /etc/nginx/sites-available/services.backup-minio-$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/services
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${YELLOW}Step 5: Verifying MinIO is accessible${NC}"
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9002 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ MinIO Console is accessible on port 9002${NC}"
else
    echo -e "${RED}✗ MinIO Console is not responding${NC}"
    exit 1
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/minio/health/live | grep -q "200"; then
    echo -e "${GREEN}✓ MinIO API is accessible on port 9000${NC}"
else
    echo -e "${RED}✗ MinIO API is not responding${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MinIO Nginx Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "MinIO is now accessible via:"
echo "  - Console (local): http://localhost:9002"
echo "  - Console (HTTPS): https://minio.arpansahu.space"
echo "  - API (local): http://localhost:9000"
echo "  - API (HTTPS): https://minioapi.arpansahu.space"
echo ""
echo "Test connection:"
echo "  curl https://minio.arpansahu.space"
echo "  curl https://minioapi.arpansahu.space/minio/health/live"

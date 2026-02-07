#!/bin/bash

# PMM (Percona Monitoring and Management) Installation Script
# This script sets up PMM Server and Client for PostgreSQL monitoring

set -e

echo "=== PMM Installation Script ==="
echo "This will install:"
echo "1. PMM Server (Docker container)"
echo "2. PMM Client"
echo "3. Configure PostgreSQL monitoring"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✓ Loaded environment variables from .env${NC}"
else
    echo -e "${RED}✗ .env file not found!${NC}"
    echo "Please create .env file with required variables (see .env.example)"
    exit 1
fi

# Validate required variables
required_vars=("PMM_ADMIN_PASSWORD" "POSTGRES_PASSWORD" "POSTGRES_HOST" "POSTGRES_PORT")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}✗ Required variable $var is not set in .env${NC}"
        exit 1
    fi
done

echo ""
echo "=== Step 1: Installing PMM Server (Docker) ==="

# Create data directory
mkdir -p /srv/pmm-data

# Pull and run PMM Server
docker pull percona/pmm-server:2
docker create \
    --name pmm-server \
    --restart always \
    -p 8443:443 \
    -v /srv/pmm-data:/srv \
    -e DISABLE_TELEMETRY=1 \
    percona/pmm-server:2

docker start pmm-server

echo -e "${GREEN}✓ PMM Server container created and started${NC}"
echo "Waiting for PMM Server to initialize (30 seconds)..."
sleep 30

# Change admin password
docker exec pmm-server change-admin-password "$PMM_ADMIN_PASSWORD"
echo -e "${GREEN}✓ Admin password set${NC}"

echo ""
echo "=== Step 2: Installing PMM Client ==="

# Install PMM Client
wget https://downloads.percona.com/downloads/pmm2/2.42.0/binary/debian/bookworm/x86_64/pmm2-client_2.42.0-6.bookworm_amd64.deb
dpkg -i pmm2-client_2.42.0-6.bookworm_amd64.deb || apt-get install -f -y
rm pmm2-client_2.42.0-6.bookworm_amd64.deb

echo -e "${GREEN}✓ PMM Client installed${NC}"

echo ""
echo "=== Step 3: Configuring PMM Client ==="

# Register PMM Client with PMM Server
pmm-admin config --server-insecure-tls --server-url=https://admin:${PMM_ADMIN_PASSWORD}@127.0.0.1:8443

echo -e "${GREEN}✓ PMM Client configured${NC}"

echo ""
echo "=== Step 4: Adding PostgreSQL Monitoring ==="

# Add PostgreSQL service
pmm-admin add postgresql \
    --username=postgres \
    --password="$POSTGRES_PASSWORD" \
    --host="$POSTGRES_HOST" \
    --port="$POSTGRES_PORT" \
    --query-source=pgstatmonitor \
    postgresql-main

echo -e "${GREEN}✓ PostgreSQL monitoring added${NC}"

echo ""
echo "=== Step 5: Setting up Nginx Reverse Proxy ==="

# Create nginx configuration
cat > /etc/nginx/sites-available/pmm << 'NGINX_EOF'
server {
    listen 80;
    server_name pmm.arpansahu.space;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pmm.arpansahu.space;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Logging
    access_log /var/log/nginx/pmm_access.log;
    error_log /var/log/nginx/pmm_error.log;
    
    # Proxy settings
    location / {
        proxy_pass https://127.0.0.1:8443;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # SSL verification (PMM uses self-signed cert)
        proxy_ssl_verify off;
    }
}
NGINX_EOF

# Enable site
ln -sf /etc/nginx/sites-available/pmm /etc/nginx/sites-enabled/

# Test and reload nginx
nginx -t && systemctl reload nginx

echo -e "${GREEN}✓ Nginx configuration created and enabled${NC}"

echo ""
echo "=== Installation Complete! ==="
echo ""
echo -e "${GREEN}PMM Server is now accessible at:${NC}"
echo "  https://pmm.arpansahu.space/"
echo ""
echo -e "${YELLOW}Login credentials:${NC}"
echo "  Username: admin"
echo "  Password: $PMM_ADMIN_PASSWORD"
echo ""
echo -e "${YELLOW}Monitoring:${NC}"
echo "  PostgreSQL: $POSTGRES_HOST:$POSTGRES_PORT"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  pmm-admin list                    # List monitored services"
echo "  pmm-admin status                  # Check PMM status"
echo "  docker logs pmm-server            # View PMM server logs"
echo "  systemctl status pmm-agent        # Check PMM agent status"
echo ""

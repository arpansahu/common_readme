#!/bin/bash

# Sentry Self-Hosted Setup Script
# This script automates the installation of self-hosted Sentry

set -e

echo "🚀 Starting Sentry Self-Hosted Setup..."

# Configuration
SENTRY_DIR="/opt/sentry"
SENTRY_DOMAIN="sentry.arpansahu.space"
SENTRY_PORT="9000"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed${NC}"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed${NC}"
    exit 1
fi

# Check available disk space (need at least 20GB)
AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    echo -e "${YELLOW}Warning: Less than 20GB disk space available${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"

# Clone Sentry repository
echo "📥 Cloning Sentry self-hosted repository..."

if [ -d "$SENTRY_DIR" ]; then
    echo -e "${YELLOW}Sentry directory already exists. Updating...${NC}"
    cd "$SENTRY_DIR"
    git pull
else
    git clone https://github.com/getsentry/self-hosted.git "$SENTRY_DIR"
    cd "$SENTRY_DIR"
fi

# Checkout latest stable
git fetch --tags
LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
echo "Checking out latest stable: $LATEST_TAG"
git checkout "$LATEST_TAG"

# Update .env with custom settings
echo "⚙️ Configuring Sentry..."

if [ ! -f .env ]; then
    cp .env.example .env || true
fi

# Update SENTRY_URL in .env
if grep -q "^SENTRY_URL=" .env; then
    sed -i "s|^SENTRY_URL=.*|SENTRY_URL=https://$SENTRY_DOMAIN|" .env
else
    echo "SENTRY_URL=https://$SENTRY_DOMAIN" >> .env
fi

echo -e "${GREEN}✓ Configuration updated${NC}"

# Run installation
echo "🔧 Running Sentry installation..."
echo -e "${YELLOW}This may take 10-20 minutes...${NC}"

./install.sh

echo -e "${GREEN}✓ Sentry installed${NC}"

# Start Sentry
echo "🚀 Starting Sentry services..."
docker compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "📊 Service Status:"
docker compose ps

# Create nginx configuration
echo "🌐 Setting up nginx reverse proxy..."

NGINX_CONFIG="/etc/nginx/sites-available/sentry"

cat > "$NGINX_CONFIG" << 'EOF'
# ================= SENTRY PROXY =================

# HTTP → HTTPS redirect
server {
    listen 80;
    listen [::]:80;

    server_name sentry.arpansahu.space;
    return 301 https://$host$request_uri;
}

# HTTPS reverse proxy
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name sentry.arpansahu.space;

    # SSL certificates (acme.sh wildcard)
    ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # Increase body size for large error payloads
    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:9000;

        proxy_http_version 1.1;

        # Required headers
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host  $host;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
EOF

# Enable site
ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/

# Test nginx config
if nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration valid${NC}"
    nginx -s reload
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    echo -e "${RED}✗ Nginx configuration error${NC}"
    exit 1
fi

# Print summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✓ Sentry Installation Complete!          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo "📌 Access Sentry at: https://$SENTRY_DOMAIN"
echo "📊 View logs: cd $SENTRY_DIR && docker compose logs -f"
echo "🔄 Restart: cd $SENTRY_DIR && docker compose restart"
echo "⏹️  Stop: cd $SENTRY_DIR && docker compose down"
echo ""
echo "📝 Next steps:"
echo "   1. Login to Sentry UI"
echo "   2. Create a new project"
echo "   3. Copy the DSN from project settings"
echo "   4. Add DSN to your Django .env file"
echo ""

#!/bin/bash
set -e

echo "=== SSL Certificate Installation with acme.sh ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
DOMAIN="${DOMAIN:-arpansahu.space}"
EMAIL="${EMAIL:-admin@arpansahu.me}"
NAMECHEAP_USERNAME="${NAMECHEAP_USERNAME}"
NAMECHEAP_API_KEY="${NAMECHEAP_API_KEY}"
NAMECHEAP_SOURCEIP="${NAMECHEAP_SOURCEIP}"

if [ -z "$NAMECHEAP_USERNAME" ] || [ -z "$NAMECHEAP_API_KEY" ]; then
    echo -e "${RED}Error: Namecheap credentials required${NC}"
    echo "Set environment variables:"
    echo "  export NAMECHEAP_USERNAME='your_username'"
    echo "  export NAMECHEAP_API_KEY='your_api_key'"
    echo "  export NAMECHEAP_SOURCEIP='your_server_ip'"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing acme.sh${NC}"
curl https://get.acme.sh | sh
source ~/.bashrc

echo -e "${YELLOW}Step 2: Setting Let's Encrypt as default CA${NC}"
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

echo -e "${YELLOW}Step 3: Issuing wildcard certificate${NC}"
export NAMECHEAP_USERNAME="$NAMECHEAP_USERNAME"
export NAMECHEAP_API_KEY="$NAMECHEAP_API_KEY"
export NAMECHEAP_SOURCEIP="$NAMECHEAP_SOURCEIP"

~/.acme.sh/acme.sh --issue \
  --dns dns_namecheap \
  -d "$DOMAIN" \
  -d "*.$DOMAIN" \
  --server letsencrypt

echo -e "${YELLOW}Step 4: Installing certificate for Nginx${NC}"
sudo mkdir -p /etc/nginx/ssl/$DOMAIN

~/.acme.sh/acme.sh --install-cert \
  -d "$DOMAIN" \
  --ecc \
  --key-file /etc/nginx/ssl/$DOMAIN/privkey.pem \
  --fullchain-file /etc/nginx/ssl/$DOMAIN/fullchain.pem \
  --reloadcmd "systemctl reload nginx"

echo -e "${YELLOW}Step 5: Setting up auto-renewal cron${NC}"
crontab -l > /tmp/mycron 2>/dev/null || true
if ! grep -q "acme.sh --cron" /tmp/mycron; then
    echo "0 0 * * * ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null" >> /tmp/mycron
    crontab /tmp/mycron
    echo "✅ Cron job configured"
fi
rm /tmp/mycron

echo -e "${GREEN}SSL certificate installed successfully!${NC}"
echo -e "Certificate location: /etc/nginx/ssl/$DOMAIN/"
echo -e "Files:"
echo -e "  - fullchain.pem (certificate)"
echo -e "  - privkey.pem (private key)"
echo ""
echo -e "${YELLOW}Auto-renewal:${NC}"
echo -e "  - Cron: Daily check at midnight"
echo -e "  - Certificate renews automatically ~60 days before expiry"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update nginx configs to use SSL certificate"
echo "2. Test: sudo nginx -t"
echo "3. Reload: sudo systemctl reload nginx"
echo ""
echo "4. (IMPORTANT) Setup automated certificate renewal:"
echo "   cd 'AWS Deployment/02-nginx'"
echo "   chmod +x ssl-renewal-automation.sh"
echo "   ./ssl-renewal-automation.sh"
echo ""
echo "5. For Kubernetes SSL automation:"
echo "   See: AWS Deployment/kubernetes_k3s/README.md"

#!/bin/bash
# SSL Certificate Renewal Automation Setup
# This script configures automated certificate renewal for nginx and optionally Kafka
# Run this AFTER initial SSL installation (install-ssl.sh)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== SSL Certificate Renewal Automation Setup ==="
echo ""

# Configuration
DOMAIN="${DOMAIN:-arpansahu.space}"
USER=$(whoami)

echo -e "${YELLOW}Step 1: Creating certificate deployment script${NC}"

cat > ~/deploy_certs.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "[$(date)] Starting certificate deployment"

# 1. Copy certificates to nginx
sudo mkdir -p /etc/nginx/ssl/DOMAIN_PLACEHOLDER
sudo cp ~/.acme.sh/DOMAIN_PLACEHOLDER_ecc/fullchain.cer /etc/nginx/ssl/DOMAIN_PLACEHOLDER/fullchain.pem
sudo cp ~/.acme.sh/DOMAIN_PLACEHOLDER_ecc/DOMAIN_PLACEHOLDER.key /etc/nginx/ssl/DOMAIN_PLACEHOLDER/privkey.pem
sudo chown USER_PLACEHOLDER:USER_PLACEHOLDER /etc/nginx/ssl/DOMAIN_PLACEHOLDER/*.pem
sudo chmod 644 /etc/nginx/ssl/DOMAIN_PLACEHOLDER/fullchain.pem
sudo chmod 600 /etc/nginx/ssl/DOMAIN_PLACEHOLDER/privkey.pem
echo "✅ Certificates copied to nginx"

# 2. Reload nginx
sudo systemctl reload nginx
echo "✅ Nginx reloaded"

# 3. Regenerate Kafka SSL keystores (if Kafka exists)
if [ -d ~/kafka-deployment ]; then
    echo "Regenerating Kafka SSL keystores..."
    cd ~/kafka-deployment
    
    if [ -f ./generate_ssl_from_nginx.sh ]; then
        ./generate_ssl_from_nginx.sh
        echo "✅ Kafka keystores regenerated"
        
        # Restart Kafka with new certificates
        docker compose -f docker-compose-kafka.yml restart
        echo "✅ Kafka restarted with new certificates"
    fi
fi

echo "[$(date)] Certificate deployment completed"
DEPLOY_SCRIPT

# Replace placeholders
sed -i.bak "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" ~/deploy_certs.sh
sed -i.bak "s/USER_PLACEHOLDER/$USER/g" ~/deploy_certs.sh
rm ~/deploy_certs.sh.bak 2>/dev/null || true

chmod +x ~/deploy_certs.sh
echo "✅ Created ~/deploy_certs.sh"

echo -e "${YELLOW}Step 2: Configuring passwordless sudo${NC}"
echo "Creating sudoers configuration for certificate operations..."

sudo tee /etc/sudoers.d/acme-cert-deploy > /dev/null << EOF
# Allow acme certificate deployment without password
$USER ALL=(ALL) NOPASSWD: /bin/mkdir -p /etc/nginx/ssl/$DOMAIN
$USER ALL=(ALL) NOPASSWD: /bin/cp /home/$USER/.acme.sh/${DOMAIN}_ecc/*.cer /etc/nginx/ssl/$DOMAIN/*.pem
$USER ALL=(ALL) NOPASSWD: /bin/cp /home/$USER/.acme.sh/${DOMAIN}_ecc/*.key /etc/nginx/ssl/$DOMAIN/*.pem
$USER ALL=(ALL) NOPASSWD: /bin/chown $USER\:$USER /etc/nginx/ssl/$DOMAIN/*.pem
$USER ALL=(ALL) NOPASSWD: /bin/chmod [0-9][0-9][0-9] /etc/nginx/ssl/$DOMAIN/*.pem
$USER ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
$USER ALL=(ALL) NOPASSWD: /usr/bin/openssl pkcs12 *
$USER ALL=(ALL) NOPASSWD: /usr/bin/keytool *
EOF

# Test sudoers syntax
if sudo visudo -c -f /etc/sudoers.d/acme-cert-deploy; then
    echo "✅ Sudoers configuration created successfully"
else
    echo -e "${RED}Error: Sudoers syntax check failed${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 3: Registering reload hook with acme.sh${NC}"

if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo -e "${RED}Error: acme.sh not found. Run install-ssl.sh first.${NC}"
    exit 1
fi

~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" --ecc \
  --reloadcmd "$HOME/deploy_certs.sh"

echo "✅ Reload hook registered with acme.sh"

echo -e "${YELLOW}Step 4: Verifying configuration${NC}"

# Check cron job exists
if crontab -l 2>/dev/null | grep -q "acme.sh --cron"; then
    echo "✅ acme.sh cron job is configured"
else
    echo -e "${YELLOW}⚠️  Warning: acme.sh cron job not found${NC}"
    echo "Run: crontab -e"
    echo "Add: 0 0 * * * ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null"
fi

# Check reload hook
if cat ~/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.conf 2>/dev/null | grep -q "Le_ReloadCmd"; then
    echo "✅ Reload hook configured in acme.sh"
else
    echo -e "${RED}Error: Reload hook not found in acme.sh config${NC}"
fi

# Check certificate files
if [ -f "/etc/nginx/ssl/$DOMAIN/fullchain.pem" ] && [ -f "/etc/nginx/ssl/$DOMAIN/privkey.pem" ]; then
    echo "✅ Certificate files exist"
else
    echo -e "${YELLOW}⚠️  Warning: Certificate files not found${NC}"
fi

echo ""
echo -e "${GREEN}SSL Certificate Renewal Automation Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}What was configured:${NC}"
echo "✅ Deployment script: ~/deploy_certs.sh"
echo "✅ Passwordless sudo: /etc/sudoers.d/acme-cert-deploy"
echo "✅ acme.sh reload hook: Registered"
echo ""
echo -e "${YELLOW}How it works:${NC}"
echo "1. acme.sh checks for renewal daily (cron job)"
echo "2. When certificate renews, deploy_certs.sh runs automatically"
echo "3. Certificates copy to /etc/nginx/ssl/$DOMAIN/"
echo "4. nginx reloads with new certificates"
echo "5. Kafka keystores regenerate (if Kafka exists)"
echo "6. Services restart automatically"
echo ""
echo -e "${YELLOW}Renewal Schedule:${NC}"
echo "- Cron runs daily at configured time"
echo "- Renewal triggers ~60 days before expiry"
echo "- Check schedule: ~/.acme.sh/acme.sh --list"
echo ""
echo -e "${YELLOW}Testing:${NC}"
echo "# Test deployment script"
echo "~/deploy_certs.sh"
echo ""
echo "# Force renewal (WARNING: Rate limits apply)"
echo "~/.acme.sh/acme.sh --renew -d $DOMAIN --ecc --force"
echo ""
echo -e "${YELLOW}Monitoring:${NC}"
echo "# Check certificate expiry"
echo "openssl x509 -in /etc/nginx/ssl/$DOMAIN/fullchain.pem -noout -dates"
echo ""
echo "# View acme.sh logs"
echo "cat ~/.acme.sh/acme.sh.log"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "# Verify cron"
echo "crontab -l | grep acme"
echo ""
echo "# Check reload hook"
echo "cat ~/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.conf | grep ReloadCmd"
echo ""
echo "# Test sudo permissions"
echo "sudo systemctl reload nginx"

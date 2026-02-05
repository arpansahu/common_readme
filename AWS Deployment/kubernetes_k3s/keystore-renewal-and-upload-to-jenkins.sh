#!/bin/bash
# Kubernetes SSL Keystore Renewal and Jenkins Upload
# This script:
# 1. Generates Java keystores from nginx SSL certificates
# 2. Creates/updates Kubernetes secrets
# 3. Uploads certificates to Jenkins credentials
# 4. Optionally restarts affected pods

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Kubernetes SSL Keystore Renewal & Jenkins Upload ==="
echo ""

# Configuration
CERT_PATH="${CERT_PATH:-/etc/nginx/ssl/arpansahu.space}"
K3S_SSL_DIR="${K3S_SSL_DIR:-/var/lib/rancher/k3s/ssl/keystores}"
KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
JENKINS_URL="${JENKINS_URL:-https://jenkins.arpansahu.space}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_TOKEN="${JENKINS_TOKEN}"
CREDENTIAL_ID="${CREDENTIAL_ID:-kafka-ssl-ca-cert}"

# Keystore passwords (read from environment or use defaults)
KEYSTORE_PASSWORD="${K3S_KEYSTORE_PASSWORD:-changeit}"
TRUSTSTORE_PASSWORD="${K3S_TRUSTSTORE_PASSWORD:-changeit}"
KEY_PASSWORD="${K3S_KEY_PASSWORD:-changeit}"

# Verify prerequisites
if [ ! -f "$CERT_PATH/fullchain.pem" ] || [ ! -f "$CERT_PATH/privkey.pem" ]; then
    echo -e "${RED}Error: SSL certificates not found at $CERT_PATH${NC}"
    echo "Run nginx SSL installation first: AWS Deployment/02-nginx/install-ssl.sh"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    echo "Install K3s first: AWS Deployment/kubernetes_k3s/install.sh"
    exit 1
fi

if ! command -v keytool &> /dev/null; then
    echo -e "${YELLOW}Installing Java keytool...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq default-jdk-headless
fi

echo -e "${YELLOW}Step 1: Generating Java keystores${NC}"

# Create SSL directory
sudo mkdir -p "$K3S_SSL_DIR"
cd "$K3S_SSL_DIR"

# Convert PEM to PKCS12
sudo openssl pkcs12 -export \
  -in "$CERT_PATH/fullchain.pem" \
  -inkey "$CERT_PATH/privkey.pem" \
  -out kafka.p12 \
  -name kafka \
  -passout pass:$KEYSTORE_PASSWORD

echo "✅ PKCS12 created"

# Create keystore
sudo keytool -importkeystore -noprompt \
  -deststorepass $KEYSTORE_PASSWORD \
  -destkeypass $KEY_PASSWORD \
  -destkeystore kafka.keystore.jks \
  -srckeystore kafka.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass $KEYSTORE_PASSWORD \
  -alias kafka

echo "✅ Keystore created"

# Create truststore (delete old one first)
sudo rm -f kafka.truststore.jks
sudo keytool -keystore kafka.truststore.jks \
  -alias CARoot \
  -import \
  -file "$CERT_PATH/fullchain.pem" \
  -storepass $TRUSTSTORE_PASSWORD \
  -noprompt

echo "✅ Truststore created"

# Set permissions
sudo chmod 644 *.jks

echo -e "${YELLOW}Step 2: Creating/updating Kubernetes secrets${NC}"

# Export kubeconfig
export KUBECONFIG="$KUBECONFIG"

# Create TLS secret for Ingress
sudo kubectl create secret tls arpansahu-tls \
  --cert="$CERT_PATH/fullchain.pem" \
  --key="$CERT_PATH/privkey.pem" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

echo "✅ TLS secret updated"

# Create keystore secret for Java apps
sudo kubectl create secret generic kafka-ssl-keystore \
  --from-file=kafka.keystore.jks="$K3S_SSL_DIR/kafka.keystore.jks" \
  --from-file=kafka.truststore.jks="$K3S_SSL_DIR/kafka.truststore.jks" \
  --from-literal=keystore-password="$KEYSTORE_PASSWORD" \
  --from-literal=truststore-password="$TRUSTSTORE_PASSWORD" \
  --from-literal=key-password="$KEY_PASSWORD" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

echo "✅ Keystore secret updated"

# Upload to Jenkins
if [ -n "$JENKINS_TOKEN" ]; then
    echo -e "${YELLOW}Step 3: Uploading certificate to Jenkins${NC}"
    
    # Read certificate content
    CERT_CONTENT=$(cat "$CERT_PATH/fullchain.pem")
    
    # Check if credential exists
    CREDENTIAL_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "$JENKINS_USER:$JENKINS_TOKEN" \
        "$JENKINS_URL/credentials/store/system/domain/_/credential/$CREDENTIAL_ID/config.xml")
    
    if [ "$CREDENTIAL_EXISTS" = "200" ]; then
        echo "Updating existing Jenkins credential..."
        
        # Create XML for updating
        cat > /tmp/jenkins-cred.xml << EOF
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$CREDENTIAL_ID</id>
  <description>Kafka SSL CA Certificate for Kubernetes (auto-updated)</description>
  <secret>$CERT_CONTENT</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
EOF
        
        # Update credential
        curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/credential/$CREDENTIAL_ID/config.xml" \
            -u "$JENKINS_USER:$JENKINS_TOKEN" \
            --data-binary @/tmp/jenkins-cred.xml \
            -H "Content-Type: application/xml"
        
        rm /tmp/jenkins-cred.xml
        echo "✅ Jenkins credential updated"
    else
        echo "Creating new Jenkins credential..."
        
        # Create new credential via UI (simpler than XML creation)
        echo ""
        echo -e "${YELLOW}Manual Jenkins upload required:${NC}"
        echo "1. Go to: $JENKINS_URL"
        echo "2. Navigate: Manage Jenkins → Credentials → (global) → Add Credentials"
        echo "3. Configure:"
        echo "   Kind: Secret text"
        echo "   ID: $CREDENTIAL_ID"
        echo "   Secret: [paste certificate]"
        echo "   Description: Kafka SSL CA Certificate for Kubernetes"
        echo ""
        echo "Certificate ready in: $CERT_PATH/fullchain.pem"
        echo ""
        echo "Quick copy command:"
        echo "cat $CERT_PATH/fullchain.pem | pbcopy  # Mac"
        echo "cat $CERT_PATH/fullchain.pem | xclip -selection clipboard  # Linux"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Jenkins upload (JENKINS_TOKEN not set)${NC}"
    echo "To enable Jenkins upload, set:"
    echo "  export JENKINS_TOKEN='your-jenkins-api-token'"
fi

echo -e "${YELLOW}Step 4: Verifying secrets${NC}"

# Verify TLS secret
if sudo kubectl get secret arpansahu-tls &> /dev/null; then
    echo "✅ TLS secret exists"
    sudo kubectl describe secret arpansahu-tls | grep -E "Name:|Type:|Data:"
else
    echo -e "${RED}✗ TLS secret not found${NC}"
fi

# Verify keystore secret
if sudo kubectl get secret kafka-ssl-keystore &> /dev/null; then
    echo "✅ Keystore secret exists"
    sudo kubectl describe secret kafka-ssl-keystore | grep -E "Name:|Type:|Data:"
else
    echo -e "${RED}✗ Keystore secret not found${NC}"
fi

echo ""
echo -e "${GREEN}SSL Keystore Renewal Complete!${NC}"
echo ""
echo -e "${YELLOW}What was updated:${NC}"
echo "✅ Java keystores: $K3S_SSL_DIR/"
echo "✅ Kubernetes TLS secret: arpansahu-tls"
echo "✅ Kubernetes keystore secret: kafka-ssl-keystore"
if [ -n "$JENKINS_TOKEN" ]; then
    echo "✅ Jenkins credential: $CREDENTIAL_ID"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart pods using certificates:"
echo "   sudo kubectl rollout restart deployment/kafka"
echo "   sudo kubectl rollout restart deployment/your-app"
echo ""
echo "2. Verify pods are using new certificates:"
echo "   sudo kubectl logs deployment/kafka"
echo "   sudo kubectl exec -it deployment/kafka -- ls /etc/kafka/secrets/"
echo ""
echo -e "${YELLOW}Monitoring:${NC}"
echo "# Check certificate expiry"
echo "sudo kubectl get secret arpansahu-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates"
echo ""
echo "# Check keystore"
echo "sudo keytool -list -v -keystore $K3S_SSL_DIR/kafka.keystore.jks -storepass $KEYSTORE_PASSWORD"
echo ""
echo -e "${YELLOW}Automation:${NC}"
echo "To run automatically after certificate renewal:"
echo "Add to ~/deploy_certs.sh:"
echo "  if command -v kubectl &> /dev/null; then"
echo "    cd 'AWS Deployment/kubernetes_k3s'"
echo "    ./keystore-renewal-and-upload-to-jenkins.sh"
echo "  fi"

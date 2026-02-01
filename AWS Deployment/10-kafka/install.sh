#!/bin/bash
set -e

echo "=== Kafka + AKHQ Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${GREEN}Loading configuration from .env${NC}"
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env from .env.example"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed!${NC}"
    exit 1
fi

# Check if Java keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${YELLOW}Installing Java JDK for keytool...${NC}"
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk-headless
fi

echo -e "${YELLOW}Step 1: Creating SSL keystores from nginx certificates${NC}"
NGINX_SSL_DIR="/etc/nginx/ssl/arpansahu.space"
SSL_DIR="$SCRIPT_DIR/ssl"
mkdir -p "$SSL_DIR"

# Generate PKCS12 keystore (needs sudo to read nginx certs)
sudo openssl pkcs12 -export \
  -in "$NGINX_SSL_DIR/fullchain.pem" \
  -inkey "$NGINX_SSL_DIR/privkey.pem" \
  -out "$SSL_DIR/kafka.keystore.p12" \
  -name kafka \
  -password "pass:$SSL_KEYSTORE_PASSWORD"

# Fix permissions so user can read the file
sudo chown $USER:$USER "$SSL_DIR/kafka.keystore.p12"
chmod 640 "$SSL_DIR/kafka.keystore.p12"

# Convert PKCS12 to JKS keystore
keytool -importkeystore \
  -srckeystore "$SSL_DIR/kafka.keystore.p12" \
  -srcstoretype PKCS12 \
  -srcstorepass "$SSL_KEYSTORE_PASSWORD" \
  -destkeystore "$SSL_DIR/kafka.keystore.jks" \
  -deststoretype JKS \
  -deststorepass "$SSL_KEYSTORE_PASSWORD" \
  -destkeypass "$SSL_KEY_PASSWORD" \
  -noprompt

# Create truststore
sudo keytool -importcert \
  -file "$NGINX_SSL_DIR/fullchain.pem" \
  -keystore "$SSL_DIR/kafka.truststore.jks" \
  -storepass "$SSL_TRUSTSTORE_PASSWORD" \
  -alias kafka-cert \
  -noprompt

# Create credential files
echo "$SSL_KEYSTORE_PASSWORD" > "$SSL_DIR/keystore_creds"
echo "$SSL_KEY_PASSWORD" > "$SSL_DIR/key_creds"
echo "$SSL_TRUSTSTORE_PASSWORD" > "$SSL_DIR/truststore_creds"

# Set permissions
sudo chown -R 1000:1000 "$SSL_DIR"
chmod 640 "$SSL_DIR"/*.jks
chmod 640 "$SSL_DIR"/*_creds

echo -e "${GREEN}SSL keystores generated${NC}"

echo -e "${YELLOW}Step 2: Creating Kafka JAAS configuration${NC}"
cat > "$SCRIPT_DIR/kafka_jaas.conf" <<EOF
KafkaServer {
  org.apache.kafka.common.security.plain.PlainLoginModule required
  username="${KAFKA_ADMIN_USERNAME}"
  password="${KAFKA_ADMIN_PASSWORD}"
  user_${KAFKA_ADMIN_USERNAME}="${KAFKA_ADMIN_PASSWORD}"
  user_${KAFKA_USER_USERNAME}="${KAFKA_USER_PASSWORD}";
};
EOF

echo -e "${YELLOW}Step 3: Creating Docker network${NC}"
docker network create kafka-network 2>/dev/null || echo "Network already exists"

echo -e "${YELLOW}Step 4: Starting Kafka${NC}"
cd "$SCRIPT_DIR"
docker compose -f docker-compose-kafka.yml up -d

echo -e "${YELLOW}Waiting for Kafka to start (30 seconds)...${NC}"
sleep 30

echo -e "${YELLOW}Step 5: Starting AKHQ (Kafka UI)${NC}"
docker compose -f docker-compose-akhq.yml up -d

echo -e "${YELLOW}Waiting for AKHQ to start (10 seconds)...${NC}"
sleep 10

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kafka + AKHQ installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Kafka Information:"
echo "  - Broker: ${KAFKA_SERVER_IP}:${KAFKA_PORT}"
echo "  - Protocol: SASL_SSL"
echo "  - Mechanism: PLAIN"
echo "  - Admin User: ${KAFKA_ADMIN_USERNAME}"
echo ""
echo "AKHQ (Kafka UI):"
echo "  - Local: http://localhost:${AKHQ_PORT}"
echo "  - Admin User: ${AKHQ_ADMIN_USERNAME}"
echo ""
echo "Check status:"
echo "  docker logs kafka-kraft --tail 50"
echo "  docker logs akhq --tail 50"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure nginx: sudo ./add-nginx-config.sh"
echo "2. Access AKHQ: https://kafka.arpansahu.space"
echo "3. Configure router port forwarding if needed"

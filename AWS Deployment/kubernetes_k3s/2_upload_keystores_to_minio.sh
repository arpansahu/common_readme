#!/bin/bash
# Upload Kafka SSL Keystores to MinIO for Django Projects
# This script uploads SSL certificates and keystores to MinIO
# for Django projects to dynamically fetch and cache

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Upload Kafka Keystores to MinIO ==="
echo ""

# Configuration
CERT_PATH="${CERT_PATH:-/etc/nginx/ssl/arpansahu.space}"
K3S_SSL_DIR="${K3S_SSL_DIR:-/var/lib/rancher/k3s/ssl/keystores}"
MINIO_ALIAS="${MINIO_ALIAS:-minio}"
MINIO_BUCKET="${MINIO_BUCKET:-arpansahu-one-bucket}"
MINIO_KEYSTORE_PATH="${MINIO_KEYSTORE_PATH:-keystores/kafka}"

# Verify prerequisites
if ! command -v mc &> /dev/null; then
    echo -e "${RED}Error: MinIO client (mc) not found${NC}"
    echo "Install: https://min.io/docs/minio/linux/reference/minio-mc.html"
    echo ""
    echo "Quick install:"
    echo "  wget https://dl.min.io/client/mc/release/linux-amd64/mc"
    echo "  chmod +x mc"
    echo "  sudo mv mc /usr/local/bin/"
    echo ""
    echo "Configure alias:"
    echo "  mc alias set minio https://minioapi.arpansahu.space MINIO_ACCESS_KEY MINIO_SECRET_KEY"
    exit 1
fi

# Check if alias exists
if ! mc alias list | grep -q "^$MINIO_ALIAS"; then
    echo -e "${RED}Error: MinIO alias '$MINIO_ALIAS' not configured${NC}"
    echo "Configure with:"
    echo "  mc alias set $MINIO_ALIAS https://minioapi.arpansahu.space MINIO_ACCESS_KEY MINIO_SECRET_KEY"
    exit 1
fi

# Verify source files exist
if [ ! -f "$CERT_PATH/fullchain.pem" ]; then
    echo -e "${RED}Error: Certificate not found at $CERT_PATH/fullchain.pem${NC}"
    exit 1
fi

if [ ! -f "$K3S_SSL_DIR/kafka.keystore.jks" ]; then
    echo -e "${RED}Error: Keystore not found at $K3S_SSL_DIR/kafka.keystore.jks${NC}"
    echo "Run 1_renew_k3s_ssl_keystores.sh first"
    exit 1
fi

echo -e "${YELLOW}Step 1: Uploading SSL certificate${NC}"

# Upload fullchain.pem
sudo mc cp "$CERT_PATH/fullchain.pem" \
  "$MINIO_ALIAS/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/fullchain.pem"

echo "✅ Certificate uploaded: $MINIO_KEYSTORE_PATH/fullchain.pem"

echo -e "${YELLOW}Step 2: Uploading Java keystores${NC}"

# Upload keystore
sudo mc cp "$K3S_SSL_DIR/kafka.keystore.jks" \
  "$MINIO_ALIAS/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/kafka.keystore.jks"

echo "✅ Keystore uploaded: $MINIO_KEYSTORE_PATH/kafka.keystore.jks"

# Upload truststore
sudo mc cp "$K3S_SSL_DIR/kafka.truststore.jks" \
  "$MINIO_ALIAS/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/kafka.truststore.jks"

echo "✅ Truststore uploaded: $MINIO_KEYSTORE_PATH/kafka.truststore.jks"

echo -e "${YELLOW}Step 3: Setting public read permissions${NC}"

# Make files publicly readable (already covered by bucket policy)
mc anonymous set download "$MINIO_ALIAS/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH"

echo "✅ Public read access enabled"

echo -e "${YELLOW}Step 4: Verifying uploads${NC}"

# List uploaded files
echo ""
echo "Uploaded files:"
mc ls "$MINIO_ALIAS/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/"

echo ""
echo -e "${GREEN}Upload Complete!${NC}"
echo ""
echo -e "${YELLOW}Files available at:${NC}"
echo "📁 Certificate:  https://minioapi.arpansahu.space/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/fullchain.pem"
echo "📁 Keystore:     https://minioapi.arpansahu.space/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/kafka.keystore.jks"
echo "📁 Truststore:   https://minioapi.arpansahu.space/$MINIO_BUCKET/$MINIO_KEYSTORE_PATH/kafka.truststore.jks"
echo ""
echo -e "${YELLOW}Django Projects:${NC}"
echo "Add this utility to fetch certificates:"
echo ""
echo "# common_utils/kafka_ssl.py"
echo "import boto3"
echo "from functools import lru_cache"
echo ""
echo "@lru_cache(maxsize=1)"
echo "def get_kafka_ssl_cert():"
echo "    s3 = boto3.client('s3',"
echo "        endpoint_url='https://minioapi.arpansahu.space',"
echo "        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,"
echo "        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY"
echo "    )"
echo "    obj = s3.get_object("
echo "        Bucket='$MINIO_BUCKET',"
echo "        Key='$MINIO_KEYSTORE_PATH/fullchain.pem'"
echo "    )"
echo "    return obj['Body'].read().decode()"
echo ""
echo -e "${YELLOW}Automation:${NC}"
echo "Add to ~/deploy_certs.sh after Kafka keystore generation:"
echo "  cd 'AWS Deployment/kubernetes_k3s'"
echo "  ./2_upload_keystores_to_minio.sh"

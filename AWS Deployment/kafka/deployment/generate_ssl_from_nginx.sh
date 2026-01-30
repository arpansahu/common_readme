#!/bin/bash
# Script to generate Kafka SSL keystores from existing nginx certificates
# Run this on the server where certificates exist
# Reads configuration from .env file

set -e

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
else
    echo "Error: .env file not found!"
    exit 1
fi

CERT_PATH="/etc/nginx/ssl/arpansahu.space"
SSL_DIR="./ssl"
KEYSTORE_PASSWORD="${SSL_KEYSTORE_PASSWORD}"
TRUSTSTORE_PASSWORD="${SSL_TRUSTSTORE_PASSWORD}"
KEY_PASSWORD="${SSL_KEY_PASSWORD}"

echo "Creating SSL directory..."
mkdir -p $SSL_DIR

echo "Converting PEM to PKCS12..."
sudo openssl pkcs12 -export \
  -in $CERT_PATH/fullchain.pem \
  -inkey $CERT_PATH/privkey.pem \
  -out $SSL_DIR/kafka.p12 \
  -name kafka \
  -passout pass:$KEYSTORE_PASSWORD

echo "Creating Kafka keystore from PKCS12..."
sudo keytool -importkeystore \
  -deststorepass $KEYSTORE_PASSWORD \
  -destkeypass $KEY_PASSWORD \
  -destkeystore $SSL_DIR/kafka.keystore.jks \
  -srckeystore $SSL_DIR/kafka.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass $KEYSTORE_PASSWORD \
  -alias kafka

echo "Creating Kafka truststore..."
sudo keytool -keystore $SSL_DIR/kafka.truststore.jks \
  -alias CARoot \
  -import \
  -file $CERT_PATH/fullchain.pem \
  -storepass $TRUSTSTORE_PASSWORD \
  -noprompt

echo "Creating credential files..."
echo "$KEYSTORE_PASSWORD" > $SSL_DIR/keystore_creds
echo "$KEY_PASSWORD" > $SSL_DIR/key_creds
echo "$TRUSTSTORE_PASSWORD" > $SSL_DIR/truststore_creds

echo "Setting permissions..."
sudo chmod 644 $SSL_DIR/*.jks
sudo chmod 644 $SSL_DIR/*_creds

echo ""
echo "✅ SSL certificates generated successfully!"
echo "Files created in $SSL_DIR:"
ls -lh $SSL_DIR

echo ""
echo "Passwords used (save these):"
echo "  Keystore password: $KEYSTORE_PASSWORD"
echo "  Truststore password: $TRUSTSTORE_PASSWORD"
echo "  Key password: $KEY_PASSWORD"

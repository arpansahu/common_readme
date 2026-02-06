## Kafka Server (Docker + KRaft + SASL/SSL + TLS)

Apache Kafka is a distributed event streaming platform used for high-performance data pipelines, streaming analytics, and data integration. This guide explains a **secure, production-ready Kafka setup** using **KRaft mode** (no Zookeeper), **SASL/SSL authentication**, and **TLS encryption**.

---

## Installing Kafka with KRaft Mode (Docker Based)

### Step 1: Prerequisites

1. **Docker installed and running**

   ```sh
   docker --version
   ```

2. **Docker Compose installed**

   ```sh
   docker compose version
   ```

3. **Valid TLS certificates** for `arpansahu.space`
   - Located at: `/etc/nginx/ssl/arpansahu.space/`
   - Files: `fullchain.pem` and `privkey.pem`

4. **Domain configured**: `kafka-server.arpansahu.space` pointing to your server IP

---

### Step 2: Setup Directory Structure

```sh
mkdir -p ~/kafka-deployment/ssl
cd ~/kafka-deployment
```

---

### Step 3: Configuration Files

#### `.env` file

Create `.env` with your configuration:

```bash
# Kafka Configuration
KAFKA_NODE_ID=1
KAFKA_SERVER_IP=kafka-server.arpansahu.space
KAFKA_PORT=9092
KAFKA_CONTROLLER_PORT=9093
CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk

# Kafka SASL Authentication
KAFKA_ADMIN_USERNAME=admin
KAFKA_ADMIN_PASSWORD=your_admin_password
KAFKA_USER_USERNAME=your_username
KAFKA_USER_PASSWORD=your_user_password

# SSL Configuration (Keystore and Key password MUST be the same for PKCS12)
SSL_KEYSTORE_PASSWORD=your_ssl_password
SSL_TRUSTSTORE_PASSWORD=your_ssl_password
SSL_KEY_PASSWORD=your_ssl_password

# Replication Settings
KAFKA_REPLICATION_FACTOR=1
KAFKA_MIN_ISR=1
```

**⚠️ Important:** Change all passwords to secure values!

#### `docker-compose-kafka.yml`

Located in: `deployment/docker-compose-kafka.yml`

This file configures:
- **KRaft mode** (no Zookeeper dependency)
- **SASL_SSL** protocol with PLAIN mechanism
- **SSL/TLS** encryption using JKS keystores
- **Two users:** admin and regular user

---

### Step 4: Generate SSL Keystores from Nginx Certificates

Create `generate_ssl_from_nginx.sh`:

```bash
#!/bin/bash
set -e

# Load environment variables
source .env

NGINX_SSL_DIR="/etc/nginx/ssl/arpansahu.space"
OUTPUT_DIR="./ssl"

echo "🔐 Generating Kafka SSL keystores from nginx certificates..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate PKCS12 keystore
openssl pkcs12 -export \
  -in "$NGINX_SSL_DIR/fullchain.pem" \
  -inkey "$NGINX_SSL_DIR/privkey.pem" \
  -out "$OUTPUT_DIR/kafka.keystore.p12" \
  -name kafka \
  -password "pass:$SSL_KEYSTORE_PASSWORD"

# Convert PKCS12 to JKS keystore
keytool -importkeystore \
  -srckeystore "$OUTPUT_DIR/kafka.keystore.p12" \
  -srcstoretype PKCS12 \
  -srcstorepass "$SSL_KEYSTORE_PASSWORD" \
  -destkeystore "$OUTPUT_DIR/kafka.keystore.jks" \
  -deststoretype JKS \
  -deststorepass "$SSL_KEYSTORE_PASSWORD" \
  -destkeypass "$SSL_KEY_PASSWORD" \
  -noprompt

# Create truststore from certificate chain
keytool -importcert \
  -file "$NGINX_SSL_DIR/fullchain.pem" \
  -keystore "$OUTPUT_DIR/kafka.truststore.jks" \
  -storepass "$SSL_TRUSTSTORE_PASSWORD" \
  -alias kafka-cert \
  -noprompt

# Create credential files
echo "$SSL_KEYSTORE_PASSWORD" > "$OUTPUT_DIR/keystore_creds"
echo "$SSL_KEY_PASSWORD" > "$OUTPUT_DIR/key_creds"
echo "$SSL_TRUSTSTORE_PASSWORD" > "$OUTPUT_DIR/truststore_creds"

# Set proper permissions
sudo chown -R 1000:1000 "$OUTPUT_DIR"
chmod 640 "$OUTPUT_DIR"/*.jks
chmod 640 "$OUTPUT_DIR"/*_creds

echo "✅ SSL keystores generated successfully in $OUTPUT_DIR/"
```

Make it executable and run:

```sh
chmod +x generate_ssl_from_nginx.sh
./generate_ssl_from_nginx.sh
```

---

### Step 5: Create Docker Network

```sh
docker network create kafka-network
```

---

### Step 6: Start Kafka

```sh
cd ~/kafka-deployment
docker compose -f docker-compose-kafka.yml up -d
```

**Wait for Kafka to fully start (30-45 seconds):**

```sh
docker logs kafka-kraft --tail 50
```

Look for: `[KafkaServer id=1] started`

---

### Step 7: Verify Kafka is Running

```sh
docker ps | grep kafka-kraft
```

Expected output:
```
CONTAINER ID   IMAGE                             STATUS          PORTS
abc123def456   confluentinc/cp-kafka:7.8.0      Up 2 minutes    0.0.0.0:9092->9092/tcp
```

---

## Testing Kafka Connection

### From Python Client

Install kafka-python:

```sh
pip install kafka-python
```

Test connectivity:

```python
import ssl
from kafka import KafkaAdminClient

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = True
ssl_context.verify_mode = ssl.CERT_REQUIRED

admin_client = KafkaAdminClient(
    bootstrap_servers='kafka-server.arpansahu.space:9092',
    security_protocol='SASL_SSL',
    sasl_mechanism='PLAIN',
    sasl_plain_username='your_username',
    sasl_plain_password='your_user_password',
    ssl_context=ssl_context
)

# List topics
topics = admin_client.list_topics()
print(f"Available topics: {topics}")

admin_client.close()
```

### Test from Server Terminal

```sh
docker exec -it kafka-kraft kafka-topics --bootstrap-server localhost:9092 \
  --command-config /etc/kafka/client.properties \
  --list
```

---

## Security Features

### SASL Authentication

- **Mechanism:** PLAIN
- **Two users configured:**
  - Admin user: Full cluster access
  - Regular user: Topic access only

### SSL/TLS Encryption

- **Protocol:** SASL_SSL
- **Certificates:** Reused from nginx (Let's Encrypt)
- **Keystores:** JKS format (Java KeyStore)
- **Endpoint verification:** Disabled for self-signed compatibility

### Network Security

- **Docker network:** Isolated `kafka-network`
- **Port binding:** 9092 for external access
- **Internal communication:** Encrypted within Docker network

---

## Important Notes

### KRaft Mode (No Zookeeper)

- **Modern architecture:** Kafka 2.8+ eliminates Zookeeper dependency
- **Simpler deployment:** One less service to manage
- **Better scalability:** Faster metadata operations
- **Production ready:** KRaft is production-ready since Kafka 3.3

### Password Security

**⚠️ Critical:** The three SSL passwords must be **identical** for PKCS12 keystores:
- `SSL_KEYSTORE_PASSWORD`
- `SSL_TRUSTSTORE_PASSWORD`  
- `SSL_KEY_PASSWORD`

If they differ, Kafka will fail to start with:
```
Given final block not properly padded
```

### Domain Resolution

For external clients (Python, Java apps), add to `/etc/hosts`:

```
192.168.1.200  kafka-server.arpansahu.space
```

Replace `192.168.1.200` with your server's IP.

---

## Configuration Details

### Advertised Listeners

```properties
KAFKA_ADVERTISED_LISTENERS=SASL_SSL://kafka-server.arpansahu.space:9092
```

This tells Kafka clients where to connect. Must match your domain.

### SASL Configuration

Inline JAAS configuration in docker-compose:

```
KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=SASL_SSL:SASL_SSL,CONTROLLER:PLAINTEXT
KAFKA_SASL_ENABLED_MECHANISMS=PLAIN
```

### Log Retention

```
KAFKA_LOG_RETENTION_HOURS=168          # 7 days
KAFKA_LOG_RETENTION_BYTES=1073741824   # 1GB per partition
```

Adjust based on your storage capacity and data volume.

---

## Troubleshooting

### Issue: Kafka won't start

**Check logs:**
```sh
docker logs kafka-kraft --tail 100
```

**Common causes:**
1. SSL password mismatch
2. Missing SSL certificates
3. Port already in use
4. Network not created

### Issue: Connection refused from client

**Verify network connectivity:**
```sh
telnet kafka-server.arpansahu.space 9092
```

**Check DNS resolution:**
```sh
nslookup kafka-server.arpansahu.space
```

**Verify SSL certificates:**
```sh
openssl s_client -connect kafka-server.arpansahu.space:9092 -servername kafka-server.arpansahu.space
```

### Issue: Authentication failed

**Check credentials in .env match client configuration**

**Verify SASL configuration:**
```sh
docker exec kafka-kraft cat /etc/kafka/kafka_server_jaas.conf
```

### Issue: SSL handshake failed

**Regenerate keystores:**
```sh
rm -rf ~/kafka-deployment/ssl/*
./generate_ssl_from_nginx.sh
docker compose -f docker-compose-kafka.yml restart
```

---

## Maintenance

### View Kafka Logs

```sh
docker logs kafka-kraft -f
```

### Restart Kafka

```sh
cd ~/kafka-deployment
docker compose -f docker-compose-kafka.yml restart
```

### Stop Kafka

```sh
docker compose -f docker-compose-kafka.yml down
```

### Backup Kafka Data

```sh
docker exec kafka-kraft tar czf /tmp/kafka-backup.tar.gz /var/lib/kafka/data
docker cp kafka-kraft:/tmp/kafka-backup.tar.gz ~/backups/
```

### Update Kafka Configuration

1. Edit `.env` file
2. Restart Kafka:
   ```sh
   docker compose -f docker-compose-kafka.yml down
   docker compose -f docker-compose-kafka.yml up -d
   ```

---

## Monitoring

### Check Cluster Status

```sh
docker exec kafka-kraft kafka-metadata --bootstrap-server localhost:9092 \
  --command-config /etc/kafka/client.properties
```

### List Topics

```sh
docker exec kafka-kraft kafka-topics --bootstrap-server localhost:9092 \
  --command-config /etc/kafka/client.properties \
  --list
```

### Check Consumer Groups

```sh
docker exec kafka-kraft kafka-consumer-groups --bootstrap-server localhost:9092 \
  --command-config /etc/kafka/client.properties \
  --list
```

---

## Production Recommendations

1. **Use strong passwords** - Generate with `openssl rand -base64 32`
2. **Enable JMX monitoring** - Add JMX ports for metrics
3. **Configure log aggregation** - Ship logs to central logging system
4. **Set up alerting** - Monitor disk usage, lag, and errors
5. **Regular backups** - Backup Kafka data and configuration
6. **Update regularly** - Keep Kafka version up-to-date for security patches
7. **Resource limits** - Set Docker CPU and memory limits
8. **TLS certificate renewal** - **Fully automated**. See [SSL Automation](../ssl-automation/README.md) for details

---

## References

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [KRaft Mode](https://kafka.apache.org/documentation/#kraft)
- [Confluent Platform](https://docs.confluent.io/)
- [Kafka Security](https://kafka.apache.org/documentation/#security)

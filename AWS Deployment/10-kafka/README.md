# Apache Kafka with AKHQ UI - Production Deployment Guide

This guide provides a complete setup for Apache Kafka with AKHQ (Kafka HQ) web UI, configured with SASL_SSL authentication and integrated with your existing nginx SSL certificates.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Accessing AKHQ](#accessing-akhq)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Maintenance](#maintenance)

## 🎯 Overview

This deployment includes:

- **Apache Kafka 7.8.0** (Confluent Platform)
  - KRaft mode (no Zookeeper required)
  - SASL_SSL authentication with PLAIN mechanism
  - SSL encryption using existing nginx certificates
  - Single-node configuration (configurable for clustering)

- **AKHQ 0.25.1** (Kafka HQ)
  - Web-based Kafka management UI
  - BCrypt-secured form authentication
  - Role-based access control (Admin & Reader roles)
  - Real-time topic, consumer group, and message browsing

## 🏗️ Architecture

```
                                    ┌─────────────────┐
                                    │  nginx (443)    │
                                    │  SSL Termination│
                                    └────────┬────────┘
                                             │
                                             │ HTTPS
                                             │
                          ┌──────────────────┴──────────────────┐
                          │                                     │
                    ┌─────▼─────┐                         ┌────▼─────┐
                    │   AKHQ    │◄────────────────────────┤  Kafka   │
                    │ Port 8086 │    kafka-network        │ Broker   │
                    │ (UI/API)  │    (Docker bridge)      │ 9092/SSL │
                    └───────────┘                         └──────────┘
                          │                                     │
                          │                                     │
                    Form Auth                            SASL_SSL Auth
                    (BCrypt)                            (PLAIN mechanism)
```

**Network Configuration:**
- External: `https://kafka.arpansahu.space` (nginx reverse proxy)
- Internal: `kafka-kraft:9092` (Docker network communication)
- Docker Network: `kafka-network` (shared between containers)

**Authentication Flow:**
1. User → nginx (HTTPS) → AKHQ (Form login with BCrypt)
2. AKHQ → Kafka (SASL_SSL with username/password)

## ✅ Prerequisites

- Ubuntu 22.04 or later
- Docker and Docker Compose installed
- Nginx with SSL certificates at `/etc/nginx/ssl/arpansahu.space/`
  - `fullchain.pem` (certificate chain)
  - `privkey.pem` (private key)
- Domain: `kafka.arpansahu.space` pointing to your server

## 📦 Installation

### Step 1: Prepare Environment

Navigate to the kafka deployment directory:

```bash
cd "AWS Deployment/kafka"
```

Copy the example environment file and configure your credentials:

```bash
cp .env.example .env
nano .env
```

**Important Configuration Notes:**

1. **Kafka Passwords**: Set strong passwords for `KAFKA_ADMIN_PASSWORD` and `KAFKA_USER_PASSWORD`

2. **AKHQ Passwords**: Generate BCrypt hashes for your AKHQ passwords:

   ```bash
   # Using Python (bcrypt module required)
   python3 << 'EOF'
   import bcrypt
   password = "your_password_here"
   hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
   hash_str = hash.decode().replace('$2b$', '$2a$')
   print(f"BCrypt hash (for .env): {hash_str.replace('$', '$$')}")
   EOF
   ```

   Or using htpasswd:
   
   ```bash
   htpasswd -bnBC 12 "" your_password_here | tr -d ':\n' | sed 's/$2y/$2a/' | sed 's/\$/\$\$/g'
   ```

   **Critical**: In `.env` file, escape `$` characters as `$$` for YAML compatibility.

3. **SSL Passwords**: Use the same password for all three SSL variables (PKCS12 requirement)

4. **CLUSTER_ID**: Keep the generated ID or generate new one:
   ```bash
   docker run --rm confluentinc/cp-kafka:7.8.0 kafka-storage random-uuid
   ```

### Step 2: Run Installation Script

The installation script will:
- Generate SSL keystores from nginx certificates
- Create JAAS configuration for Kafka authentication
- Create Docker network
- Start Kafka and AKHQ containers

```bash
chmod +x install.sh
./install.sh
```

**What happens during installation:**

1. **SSL Keystore Generation**:
   - Converts nginx PEM certificates to PKCS12 format
   - Creates JKS keystores for Kafka
   - Generates credential files

2. **JAAS Configuration**:
   - Creates `/etc/kafka/kafka_jaas.conf` for broker authentication
   - Configures PLAIN SASL mechanism

3. **Docker Network**:
   - Creates `kafka-network` bridge network for container communication

4. **Container Startup**:
   - Starts Kafka broker with KRaft mode
   - Starts AKHQ connected to Kafka

### Step 3: Configure Nginx

Add the nginx reverse proxy configuration:

```bash
chmod +x add-nginx-config.sh
sudo ./add-nginx-config.sh
```

This creates:
- Server block for `kafka.arpansahu.space`
- HTTPS configuration with your SSL certificates
- Proxy to AKHQ on port 8086

## ⚙️ Configuration

### Kafka Configuration

**Key Settings in `.env`:**

| Variable | Description | Default |
|----------|-------------|---------|
| `KAFKA_NODE_ID` | Unique node identifier | 1 |
| `KAFKA_SERVER_IP` | Advertised hostname | kafka-server.arpansahu.space |
| `KAFKA_PORT` | Client connection port | 9092 |
| `KAFKA_CONTROLLER_PORT` | KRaft controller port | 9093 |
| `KAFKA_REPLICATION_FACTOR` | Topic replication factor | 1 |
| `KAFKA_MIN_ISR` | Minimum in-sync replicas | 1 |

**Security Configuration:**

- **Protocol**: SASL_SSL (encrypted + authenticated)
- **SASL Mechanism**: PLAIN (username/password)
- **SSL**: JKS keystores from nginx certificates
- **Client Auth**: Not required (server-side SSL only)

### AKHQ Configuration

**Authentication:**

AKHQ uses BCrypt-hashed passwords with form-based authentication:

- **Admin User**: Full access (topics, consumers, configs, ACLs)
- **Reader User**: Read-only access (topics, consumer groups)

**Roles and Permissions:**

| Role | Permissions |
|------|------------|
| `admin` | Full CRUD on topics, data, consumer groups, schemas, connectors, ACLs |
| `reader` | Read-only access to topics, data, consumer groups, schemas |

**Security Features:**

- Cookie-based session management
- JWT tokens for API authentication
- CSRF protection
- Secure password hashing (BCrypt, rounds=12)
- Login/logout endpoints with redirects

## 🌐 Accessing AKHQ

**Web Interface:**

```
URL: https://kafka.arpansahu.space
```

**Default Credentials (change in .env):**

- **Admin Login:**
  - Username: `arpansahu`
  - Password: Your configured `AKHQ_ADMIN_PASSWORD`

- **Reader Login:**
  - Username: `user`
  - Password: Your configured `AKHQ_USER_PASSWORD`

**Features Available:**

1. **Topics Management**
   - View/Create/Delete topics
   - Browse messages
   - Produce test messages
   - Configure topic settings

2. **Consumer Groups**
   - View consumer group status
   - Monitor lag
   - Reset offsets

3. **Cluster Information**
   - Broker details
   - Node configurations
   - Metrics and health

4. **Security**
   - View ACLs (Access Control Lists)
   - Manage permissions (if ACLs enabled)

## ✔️ Verification

### Check Container Status

```bash
cd "AWS Deployment/kafka"
docker ps --filter name='kafka-kraft|akhq'
```

**Expected Output:**
```
NAMES         STATUS
kafka-kraft   Up X minutes (healthy)
akhq          Up X minutes (healthy)
```

### Verify Kafka Broker

```bash
docker logs kafka-kraft --tail 20
```

**Look for:**
```
[KafkaRaftServer nodeId=1] Kafka Server started
```

### Verify AKHQ Connection

```bash
curl -sL https://kafka.arpansahu.space/ui | grep -o '<title>.*</title>'
```

**Expected Output:**
```
<title>AKHQ</title>
```

### Test Kafka Connection from AKHQ

1. Open https://kafka.arpansahu.space
2. Login with admin credentials
3. Navigate to "Cluster" → You should see cluster information
4. Navigate to "Topics" → Should load without errors

### Create Test Topic

**Via AKHQ UI:**
1. Go to "Topics" → "Create Topic"
2. Name: `test-topic`
3. Partitions: 3
4. Replication: 1
5. Click "Create"

**Via Command Line (inside Kafka container):**

```bash
docker exec -it kafka-kraft kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --command-config /etc/kafka/client.properties \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1
```

### Verify SSL Configuration

Check that Kafka is using SSL certificates:

```bash
docker exec kafka-kraft ls -la /etc/kafka/secrets/
```

**Expected files:**
- `kafka.keystore.jks`
- `kafka.truststore.jks`
- `keystore_creds`
- `key_creds`
- `truststore_creds`

## 🔧 Troubleshooting

### Container Issues

**Kafka container not starting:**

```bash
# Check logs
docker logs kafka-kraft --tail 50

# Common issues:
# 1. Port already in use (9092 or 9093)
sudo netstat -tlnp | grep -E '9092|9093'

# 2. Invalid CLUSTER_ID
# Generate new one and update .env
docker run --rm confluentinc/cp-kafka:7.8.0 kafka-storage random-uuid
```

**AKHQ shows "unhealthy" status:**

```bash
# Check AKHQ logs
docker logs akhq --tail 50

# Verify both containers are on same network
docker inspect kafka-kraft --format '{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}'
docker inspect akhq --format '{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}'

# Both should show: kafka-network
```

### Authentication Issues

**"Failed to create new KafkaAdminClient" in AKHQ:**

This means AKHQ cannot connect to Kafka. Check:

1. **Network connectivity:**
   ```bash
   docker exec akhq ping kafka-kraft
   ```

2. **Kafka SASL credentials in docker-compose-akhq.yml:**
   - Must match `KAFKA_USER_USERNAME` and `KAFKA_USER_PASSWORD` from `.env`

3. **SSL truststore path:**
   ```bash
   docker exec akhq ls -la /ssl/kafka.truststore.jks
   ```

**"Wrong username or password" when logging into AKHQ:**

1. **Verify BCrypt hashes are correct in docker-compose-akhq.yml:**
   ```bash
   grep "password:" docker-compose-akhq.yml
   ```

2. **Regenerate hashes if needed:**
   ```bash
   python3 << 'EOF'
   import bcrypt
   password = "your_password_here"
   hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
   print(hash.decode().replace('$2b$', '$2a$').replace('$', '$$'))
   EOF
   ```

3. **Update docker-compose-akhq.yml and restart:**
   ```bash
   docker compose -f docker-compose-akhq.yml down
   docker compose -f docker-compose-akhq.yml up -d
   ```

### SSL Issues

**"SSLHandshakeException" errors:**

```bash
# Verify SSL certificates are readable
sudo ls -la /etc/nginx/ssl/arpansahu.space/

# Check keystore permissions
ls -la ssl/

# Regenerate keystores if needed
./install.sh  # Re-run installation
```

### Network Issues

**Containers on different networks:**

```bash
# Remove and recreate with proper network
cd "AWS Deployment/kafka"
docker compose -f docker-compose-kafka.yml down
docker compose -f docker-compose-akhq.yml down
docker network rm kafka-network
docker network create kafka-network
docker compose -f docker-compose-kafka.yml up -d
docker compose -f docker-compose-akhq.yml up -d
```

### Nginx Issues

**502 Bad Gateway:**

```bash
# Check nginx is proxying to correct port
sudo grep -A 10 "kafka.arpansahu.space" /etc/nginx/sites-available/services

# Should show: proxy_pass http://localhost:8086;

# Test AKHQ is responding locally
curl http://localhost:8086
```

**SSL certificate errors:**

```bash
# Verify SSL cert paths in nginx config
sudo grep "ssl_certificate" /etc/nginx/sites-available/services

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## 🔒 Security

### Best Practices

1. **Password Management:**
   - Use strong, unique passwords for all accounts
   - Store credentials securely (not in version control)
   - Rotate passwords regularly

2. **Network Security:**
   - Keep port 9092 accessible only from trusted IPs
   - Use firewall rules to restrict access
   - HTTPS only for AKHQ (no HTTP)

3. **SSL/TLS:**
   - Keep SSL certificates up to date
   - Use strong cipher suites in nginx
   - Enable HSTS headers

4. **Access Control:**
   - Use AKHQ reader role for monitoring
   - Limit admin access to necessary users
   - Review audit logs regularly

5. **Container Security:**
   - Use `:ro` (read-only) volume mounts where possible
   - Run containers with `--restart unless-stopped`
   - Keep images updated

### Credential Files

**Never commit these files to git:**

- `.env` (contains real passwords)
- `ssl/*.jks` (SSL keystores)
- `ssl/*_creds` (credential files)
- `kafka_jaas.conf` (authentication config)

**Add to .gitignore:**
```
.env
ssl/
kafka_jaas.conf
```

## 🔄 Maintenance

### Updating Kafka

```bash
cd "AWS Deployment/kafka"

# Pull new image
docker pull confluentinc/cp-kafka:7.9.0  # Example version

# Update docker-compose-kafka.yml image tag
sed -i 's/confluentinc\/cp-kafka:7.8.0/confluentinc\/cp-kafka:7.9.0/g' docker-compose-kafka.yml

# Restart with new image
docker compose -f docker-compose-kafka.yml down
docker compose -f docker-compose-kafka.yml up -d
```

### Updating AKHQ

```bash
# Pull new image
docker pull tchiotludo/akhq:0.26.0  # Example version

# Update docker-compose-akhq.yml
sed -i 's/tchiotludo\/akhq:0.25.1/tchiotludo\/akhq:0.26.0/g' docker-compose-akhq.yml

# Restart
docker compose -f docker-compose-akhq.yml down
docker compose -f docker-compose-akhq.yml up -d
```

### Backup and Restore

**Backup Kafka data:**

```bash
# Kafka data is in Docker volume
docker run --rm -v kafka_kafka-data:/data -v $(pwd):/backup ubuntu tar czf /backup/kafka-backup-$(date +%Y%m%d).tar.gz /data
```

**Backup configuration:**

```bash
tar czf kafka-config-backup-$(date +%Y%m%d).tar.gz .env docker-compose-*.yml *.sh *.conf
```

### Monitoring

**View logs:**

```bash
# Kafka logs
docker logs -f kafka-kraft

# AKHQ logs
docker logs -f akhq

# Both with timestamps
docker logs -f --timestamps kafka-kraft
```

**Monitor resource usage:**

```bash
docker stats kafka-kraft akhq
```

**Check disk usage:**

```bash
docker system df
docker volume ls
```

### Restart Services

```bash
cd "AWS Deployment/kafka"

# Restart Kafka only
docker compose -f docker-compose-kafka.yml restart

# Restart AKHQ only
docker compose -f docker-compose-akhq.yml restart

# Restart both
docker compose -f docker-compose-kafka.yml restart && \
docker compose -f docker-compose-akhq.yml restart
```

### Clean Restart

```bash
cd "AWS Deployment/kafka"

# Stop all
docker compose -f docker-compose-kafka.yml down
docker compose -f docker-compose-akhq.yml down

# Remove volumes (WARNING: deletes all Kafka data)
docker volume rm kafka_kafka-data

# Start fresh
./install.sh
```

## 📚 Additional Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Platform Documentation](https://docs.confluent.io/)
- [AKHQ Documentation](https://akhq.io/)
- [KRaft Mode Guide](https://kafka.apache.org/documentation/#kraft)

## 🆘 Support

For issues specific to this deployment:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review container logs for error messages
3. Verify all prerequisites are met
4. Ensure `.env` configuration is correct

## 📝 Notes

- This deployment is configured for **single-node** operation. For production clustering:
  - Add multiple Kafka broker services with unique `KAFKA_NODE_ID`
  - Update `KAFKA_CONTROLLER_QUORUM_VOTERS` with all controller nodes
  - Increase `KAFKA_REPLICATION_FACTOR` and `KAFKA_MIN_ISR`

- **KRaft Mode** (no Zookeeper):
  - Simplified architecture
  - Better performance
  - Native Kafka metadata management
  - Recommended for new deployments

- **SASL_SSL Security**:
  - All client communication is encrypted
  - Username/password authentication required
  - SSL certificates from existing nginx setup

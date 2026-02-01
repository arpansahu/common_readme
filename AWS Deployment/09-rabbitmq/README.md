## RabbitMQ Server (Docker + Nginx + HTTPS)

RabbitMQ is a reliable and mature messaging and streaming broker. This setup provides RabbitMQ with management UI accessible via HTTPS.

---

## Test Files Overview

| Test File | Where to Run | Connection Type | Purpose |
|-----------|-------------|-----------------|---------|
| `test_rabbitmq_localhost.py` | **On Server** | localhost:5672 | Test RabbitMQ messaging on server without TLS |
| `test_rabbitmq_domain_https.sh` | **From Mac** | rabbitmq.arpansahu.space:443 | Test RabbitMQ Management API from Mac with HTTPS |

**Quick Test Commands:**
```bash
# On Server (localhost)
python3 test_rabbitmq_localhost.py

# From Mac (domain with HTTPS)
RABBITMQ_PASS=your_password ./test_rabbitmq_domain_https.sh
```

---

## Step-by-Step Installation Guide

### Step 1: Create Environment Configuration

First, create the environment configuration file that will store your RabbitMQ credentials.

**Create `.env.example` (Template file):**

```bash
# RabbitMQ Configuration
RABBITMQ_USER=your_username_here
RABBITMQ_PASS=your_secure_password_here
```

**Create your actual `.env` file:**

```bash
cd "AWS Deployment/Rabbitmq"
cp .env.example .env
nano .env
```

**Your `.env` file should look like this (with your actual credentials):**

```bash
# RabbitMQ Configuration
RABBITMQ_USER=admin
RABBITMQ_PASS=YourSecurePassword123
```

**⚠️ Important:** 
- Always use a strong password in production!
- Never commit your `.env` file to version control
- Keep the `.env.example` file as a template

---

### Step 2: Create Installation Script

Create the `install.sh` script that will automatically install RabbitMQ using the environment variables.

**Create `install.sh` file:**

```bash
#!/bin/bash
set -e

echo "=== RabbitMQ Installation Script ==="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
    echo -e "${GREEN}Loaded configuration from .env file${NC}"
else
    echo -e "${YELLOW}Warning: .env file not found. Using defaults.${NC}"
    echo -e "${YELLOW}Please copy .env.example to .env and configure it.${NC}"
fi

# Configuration with defaults
RABBITMQ_USER="${RABBITMQ_USER:-admin}"
RABBITMQ_PASS="${RABBITMQ_PASS:-changeme}"

echo -e "${YELLOW}Step 1: Fixing Docker IPv4/MTU Issues${NC}"
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "mtu": 1400
}
EOF

echo -e "${GREEN}Restarting Docker...${NC}"
sudo systemctl restart docker
sleep 3

echo -e "${YELLOW}Step 2: Creating Persistent Data Directory${NC}"
sudo mkdir -p /var/lib/rabbitmq
sudo chown -R 999:999 /var/lib/rabbitmq

echo -e "${YELLOW}Step 3: Running RabbitMQ Container${NC}"
docker run -d \
  --name rabbitmq \
  --restart unless-stopped \
  -p 127.0.0.1:5672:5672 \
  -p 127.0.0.1:15672:15672 \
  -e RABBITMQ_DEFAULT_USER="$RABBITMQ_USER" \
  -e RABBITMQ_DEFAULT_PASS="$RABBITMQ_PASS" \
  -v /var/lib/rabbitmq:/var/lib/rabbitmq \
  rabbitmq:3-management

echo -e "${YELLOW}Step 4: Waiting for RabbitMQ to start...${NC}"
sleep 10

echo -e "${YELLOW}Step 5: Verifying Installation${NC}"
docker ps | grep rabbitmq

echo -e "${GREEN}RabbitMQ installed successfully!${NC}"
echo -e "Management UI: http://localhost:15672"
echo -e "Username: $RABBITMQ_USER"
echo -e "Password: $RABBITMQ_PASS"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy nginx config: sudo cp $(dirname $0)/nginx.conf /etc/nginx/sites-available/rabbitmq"
echo "2. Enable site: sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/"
echo "3. Test nginx: sudo nginx -t"
echo "4. Reload nginx: sudo systemctl reload nginx"
```

**What this script does:**
- Loads environment variables from `.env` file
- Fixes Docker DNS and MTU issues (common RabbitMQ problem)
- Creates persistent data directory at `/var/lib/rabbitmq`
- Runs RabbitMQ container with management plugin
- Exposes AMQP (5672) and Management UI (15672) on localhost only
- Sets custom username and password from environment variables

**Make it executable and run:**

```bash
chmod +x install.sh
./install.sh
```

**Expected output:**
```
=== RabbitMQ Installation Script ===
Loaded configuration from .env file
Step 1: Fixing Docker IPv4/MTU Issues
Restarting Docker...
Step 2: Creating Persistent Data Directory
Step 3: Running RabbitMQ Container
Step 2: Waiting for RabbitMQ to start...
Step 3: Verifying Installation
rabbitmq
RabbitMQ installed successfully!
Management UI: http://localhost:15672
Username: admin
Password: YourSecurePassword123
```

---

### Step 3: Configure Nginx for HTTPS Access

Create the Nginx configuration to provide secure HTTPS access to RabbitMQ Management UI.

**Create `nginx.conf` file:**

```nginx
# RabbitMQ Management UI - HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name rabbitmq.arpansahu.space;
    return 301 https://$host$request_uri;
}

# RabbitMQ Management UI - HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name rabbitmq.arpansahu.space;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # Proxy to RabbitMQ Management UI
    location / {
        proxy_pass http://127.0.0.1:15672;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**What this configuration does:**
- Redirects all HTTP traffic to HTTPS (port 80 → 443)
- Serves RabbitMQ Management UI on https://rabbitmq.arpansahu.space
- Uses your wildcard SSL certificate for *.arpansahu.space
- Enables WebSocket support (required for real-time UI updates)
- Proxies requests to RabbitMQ container on localhost:15672

---

### Step 4: Apply Nginx Configuration

You have two options to apply the Nginx configuration:

#### Option 1: Automated (Recommended)

Create `add-nginx-conf.sh` script:

```bash
#!/bin/bash
set -e

echo "=== Adding RabbitMQ Nginx Configuration ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Backing up existing config (if any)${NC}"
if [ -f /etc/nginx/sites-available/rabbitmq ]; then
    sudo cp /etc/nginx/sites-available/rabbitmq \
         /etc/nginx/sites-available/rabbitmq.backup-$(date +%Y%m%d-%H%M%S)
    echo "Backup created"
else
    echo "No existing config found"
fi

echo -e "${YELLOW}Step 2: Copying nginx.conf to sites-available${NC}"
sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/rabbitmq

echo -e "${YELLOW}Step 3: Creating symbolic link to sites-enabled${NC}"
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/

echo -e "${YELLOW}Step 4: Testing nginx configuration${NC}"
sudo nginx -t

echo -e "${YELLOW}Step 5: Reloading nginx${NC}"
sudo systemctl reload nginx

echo -e "${YELLOW}Step 6: Verifying configuration${NC}"
sudo nginx -T | grep "server_name rabbitmq.arpansahu.space" || echo "Configuration not found in output"

echo -e "${GREEN}RabbitMQ Nginx configured successfully!${NC}"
echo -e "Access at: https://rabbitmq.arpansahu.space"
```

**Run the script:**

```bash
chmod +x add-nginx-conf.sh
sudo bash add-nginx-conf.sh
```

**Expected output:**
```
=== Adding RabbitMQ Nginx Configuration ===
Step 1: Backing up existing config (if any)
No existing config found
Step 2: Copying nginx.conf to sites-available
Step 3: Creating symbolic link to sites-enabled
Step 4: Testing nginx configuration
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
Step 5: Reloading nginx
Step 6: Verifying configuration
server_name rabbitmq.arpansahu.space;
RabbitMQ Nginx configured successfully!
Access at: https://rabbitmq.arpansahu.space
```

#### Option 2: Manual Configuration

```bash
# 1. Copy configuration to Nginx sites-available
sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq

# 2. Enable the site (create symbolic link)
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/

# 3. Test Nginx configuration
sudo nginx -t

# 4. Reload Nginx
sudo systemctl reload nginx
```

---

## Testing Your RabbitMQ Installation

### Test 1: Check Container Status

Verify that the RabbitMQ container is running:

```bash
# Check if container is running
docker ps | grep rabbitmq

# View container logs
docker logs rabbitmq

# Check RabbitMQ status
docker exec rabbitmq rabbitmqctl status | head -20
```

**Expected output:**
```
rabbitmq   rabbitmq:3-management   ...   Up X minutes   ...
```

---

### Test 2: Test Local Access

Test RabbitMQ Management UI locally:

```bash
# Test HTTP access
curl http://localhost:15672

# Should return HTML content of the login page
```

---

### Test 3: Access Management UI via Browser

Open your browser and navigate to:

**URL:** https://rabbitmq.arpansahu.space

**Login credentials:**
- Username: `${RABBITMQ_USER}` (from your .env file)
- Password: `${RABBITMQ_PASS}` (from your .env file)

You should see the RabbitMQ Management Dashboard with:
- Overview tab showing server status
- Connections, Channels, Exchanges, Queues tabs
- Admin section for user management

---

## Automated Connection Testing

We provide automated test scripts to verify RabbitMQ connectivity from different locations.

### Test Script 1: Server Connection Test (Python)

This script tests RabbitMQ connectivity from the server using Python pika.

**Create `test_rabbitmq_server.py` file:**

```python
#!/usr/bin/env python3
"""
RabbitMQ Server Connection Test
Tests RabbitMQ connectivity from the server using Python pika
"""

import pika
import sys

def test_rabbitmq():
    try:
        print("=== Testing RabbitMQ Connection from Server ===\n")
        
        # Connection parameters
        credentials = pika.PlainCredentials('${RABBITMQ_USER}', '${RABBITMQ_PASS}')
        parameters = pika.ConnectionParameters(
            host='127.0.0.1',
            port=5672,
            credentials=credentials
        )
        
        # Connect
        print("Connecting to RabbitMQ...")
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        print("✓ Connection successful\n")
        
        # Declare queue
        queue_name = 'test_queue'
        channel.queue_declare(queue=queue_name)
        print(f"✓ Queue declared: {queue_name}\n")
        
        # Send message
        message = 'Hello from Server!'
        channel.basic_publish(
            exchange='',
            routing_key=queue_name,
            body=message
        )
        print(f"✓ Message sent: {message}\n")
        
        # Get message
        method_frame, header_frame, body = channel.basic_get(queue=queue_name, auto_ack=True)
        if body:
            print(f"✓ Message received: {body.decode()}\n")
        
        # Clean up
        channel.queue_delete(queue=queue_name)
        connection.close()
        
        print("✓ All tests passed!")
        print("✓ RabbitMQ is working correctly\n")
        return 0
        
    except pika.exceptions.AMQPConnectionError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if RabbitMQ container is running: docker ps | grep rabbitmq")
        return 1
    except pika.exceptions.ProbableAuthenticationError as e:
        print(f"✗ Authentication Error: {e}")
        print("  Check your credentials in .env file")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_rabbitmq())
```

**Run on server:**

```bash
# Install pika if not already installed
pip3 install pika

# Run the test
python3 test_rabbitmq_server.py
```

**Expected output:**
```
=== Testing RabbitMQ Connection from Server ===

Connecting to RabbitMQ...
✓ Connection successful

✓ Queue declared: test_queue

✓ Message sent: Hello from Server!

✓ Message received: Hello from Server!

✓ All tests passed!
✓ RabbitMQ is working correctly
```

---

### Test Script 2: Mac Connection Test (Shell Script)

This script tests RabbitMQ Management API connectivity from your Mac.

**Create `test_rabbitmq_mac.sh` file:**

```bash
#!/bin/bash

# RabbitMQ Mac Connection Test
# Tests RabbitMQ Management API connectivity from your Mac

set -e

echo "=== Testing RabbitMQ Connection from Mac ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RABBITMQ_URL="https://rabbitmq.arpansahu.space"
RABBITMQ_USER="${RABBITMQ_USER:-arpansahu}"
RABBITMQ_PASS="${RABBITMQ_PASS:-changeme}"

# Test 1: Check if RabbitMQ is accessible
echo "${YELLOW}Test 1: Checking RabbitMQ accessibility...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/overview")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ RabbitMQ Management API is accessible${NC}"
else
    echo -e "${RED}✗ Failed to access RabbitMQ (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 2: Get RabbitMQ version and cluster info
echo "${YELLOW}Test 2: Getting RabbitMQ information...${NC}"
OVERVIEW=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/overview")

VERSION=$(echo "$OVERVIEW" | python3 -c "import sys, json; print(json.load(sys.stdin)['rabbitmq_version'])")
ERLANG=$(echo "$OVERVIEW" | python3 -c "import sys, json; print(json.load(sys.stdin)['erlang_version'])")
CLUSTER=$(echo "$OVERVIEW" | python3 -c "import sys, json; print(json.load(sys.stdin)['cluster_name'])")

echo -e "${GREEN}✓ RabbitMQ version: $VERSION${NC}"
echo -e "${GREEN}✓ Erlang version: $ERLANG${NC}"
echo -e "${GREEN}✓ Cluster name: $CLUSTER${NC}"
echo ""

# Test 3: Create a test queue
echo "${YELLOW}Test 3: Creating test queue...${NC}"
QUEUE_NAME="mac_test_queue_$(date +%s)"
curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
    -X PUT \
    -H "content-type:application/json" \
    -d '{"durable":true}' \
    "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME" > /dev/null

sleep 1

# Verify queue was created
QUEUE_INFO=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME")
QUEUE_EXISTS=$(echo "$QUEUE_INFO" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('name', ''))")

if [ "$QUEUE_EXISTS" = "$QUEUE_NAME" ]; then
    echo -e "${GREEN}✓ Queue created: $QUEUE_NAME${NC}"
else
    echo -e "${RED}✗ Failed to create queue${NC}"
    exit 1
fi
echo ""

# Test 4: Publish a message via API
echo "${YELLOW}Test 4: Publishing message to queue...${NC}"
curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
    -X POST \
    -H "content-type:application/json" \
    -d '{"properties":{},"routing_key":"'$QUEUE_NAME'","payload":"Hello from Mac!","payload_encoding":"string"}' \
    "$RABBITMQ_URL/api/exchanges/%2F/amq.default/publish" > /dev/null

sleep 1

# Check if message is in queue
QUEUE_MESSAGES=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME" | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('messages', 0))")

if [ "$QUEUE_MESSAGES" -gt 0 ]; then
    echo -e "${GREEN}✓ Message published successfully (messages in queue: $QUEUE_MESSAGES)${NC}"
else
    echo -e "${RED}✗ Message not found in queue${NC}"
fi
echo ""

# Test 5: Clean up - delete test queue
echo "${YELLOW}Test 5: Cleaning up test queue...${NC}"
curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
    -X DELETE \
    "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME" > /dev/null

echo -e "${GREEN}✓ Test queue deleted${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${GREEN}✓ RabbitMQ is working correctly${NC}"
echo -e "${GREEN}========================================${NC}"
```

**Run from your Mac:**

```bash
# Make script executable
chmod +x test_rabbitmq_mac.sh

# Set environment variables (optional)
export RABBITMQ_USER=arpansahu
export RABBITMQ_PASS=your_password

# Run the test
./test_rabbitmq_mac.sh
```

**Expected output:**
```
=== Testing RabbitMQ Connection from Mac ===

Test 1: Checking RabbitMQ accessibility...
✓ RabbitMQ Management API is accessible

Test 2: Getting RabbitMQ information...
✓ RabbitMQ version: 3.13.7
✓ Erlang version: 26.2.5.16
✓ Cluster name: rabbit@3a972e979746

Test 3: Creating test queue...
✓ Queue created: mac_test_queue_1234567890

Test 4: Publishing message to queue...
✓ Message published successfully (messages in queue: 1)

Test 5: Cleaning up test queue...
✓ Test queue deleted

========================================
✓ All tests passed!
✓ RabbitMQ is working correctly
========================================
```

---

## Important Notes on Connectivity

**AMQP Protocol (Port 5672):**
- Only accessible on `127.0.0.1` (localhost)
- Your Django/Celery applications on the same server can connect
- **Cannot be accessed from external machines** (including your Mac)

**Management UI (Port 15672):**
- Only accessible on `127.0.0.1` (localhost)
- External access via Nginx HTTPS proxy at `https://rabbitmq.arpansahu.space`

**Management REST API:**
- Accessible externally via `https://rabbitmq.arpansahu.space/api/*`
- Allows queue management, message publishing, monitoring
- Requires HTTP Basic Authentication

**Testing Summary:**
- ✅ **Docker Container**: Direct access to RabbitMQ via `rabbitmqctl`
- ✅ **Server**: AMQP protocol access via pika on `127.0.0.1:5672`
- ✅ **Mac**: Management REST API access via HTTPS

---

## Connection Details Summary

After successful installation, your RabbitMQ setup will have:

- **Container Name:** `rabbitmq`
- **Management UI:** `https://rabbitmq.arpansahu.space`
- **AMQP Port:** `127.0.0.1:5672` (localhost only)
- **Management Port:** `127.0.0.1:15672` (localhost only)
- **Username:** `${RABBITMQ_USER}` (from your .env file)
- **Password:** `${RABBITMQ_PASS}` (from your .env file)
- **Data Directory:** `/var/lib/rabbitmq`
- **Docker Image:** `rabbitmq:3-management`

---

## Using RabbitMQ in Your Applications

### Python Connection Example (pika)

Install the pika library:

```bash
pip install pika
```

**Producer (Send messages):**

```python
import pika

# Connection parameters
credentials = pika.PlainCredentials('${RABBITMQ_USER}', '${RABBITMQ_PASS}')
parameters = pika.ConnectionParameters(
    host='127.0.0.1',
    port=5672,
    credentials=credentials
)

# Connect
connection = pika.BlockingConnection(parameters)
channel = connection.channel()

# Declare queue
channel.queue_declare(queue='hello')

# Send message
channel.basic_publish(
    exchange='',
    routing_key='hello',
    body='Hello World!'
)

print(" [x] Sent 'Hello World!'")
connection.close()
```

**Consumer (Receive messages):**

```python
import pika

# Connection parameters
credentials = pika.PlainCredentials('${RABBITMQ_USER}', '${RABBITMQ_PASS}')
parameters = pika.ConnectionParameters(
    host='127.0.0.1',
    port=5672,
    credentials=credentials
)

# Connect
connection = pika.BlockingConnection(parameters)
channel = connection.channel()

# Declare queue
channel.queue_declare(queue='hello')

# Define callback
def callback(ch, method, properties, body):
    print(f" [x] Received {body}")

# Start consuming
channel.basic_consume(
    queue='hello',
    on_message_callback=callback,
    auto_ack=True
)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
```

---

### Django Celery Configuration

Install required packages:

```bash
pip install celery[redis]  # or celery[amqp] for RabbitMQ
```

**Django settings.py:**

```python
# Celery Configuration
CELERY_BROKER_URL = f'amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@127.0.0.1:5672//'
CELERY_RESULT_BACKEND = 'rpc://'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'
```

**celery.py (in your project directory):**

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')

app = Celery('your_project')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

**Start Celery worker:**

```bash
celery -A your_project worker -l info
```

---

## Troubleshooting

### Container Issues

If RabbitMQ container is not running:

```bash
# Check container logs
docker logs rabbitmq

# Check container status
docker ps -a | grep rabbitmq

# Restart container
docker restart rabbitmq

# Remove and reinstall
docker stop rabbitmq
docker rm rabbitmq
./install.sh
```

---

### Can't Access Management UI

If you cannot access https://rabbitmq.arpansahu.space:

```bash
# Check if container is running
docker ps | grep rabbitmq

# Check if port is listening
sudo ss -lntp | grep 15672

# Test local access
curl http://localhost:15672

# Check Nginx configuration
sudo nginx -T | grep "server_name rabbitmq.arpansahu.space"

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

---

### Login Failed

If you can't log in to the Management UI:

```bash
# Check current users
docker exec rabbitmq rabbitmqctl list_users

# Reset password
docker exec rabbitmq rabbitmqctl change_password ${RABBITMQ_USER} new_password

# Or create new admin user
docker exec rabbitmq rabbitmqctl add_user newuser newpassword
docker exec rabbitmq rabbitmqctl set_user_tags newuser administrator
docker exec rabbitmq rabbitmqctl set_permissions -p / newuser ".*" ".*" ".*"
```

---

### Connection Refused Errors

If applications can't connect to RabbitMQ:

```bash
# Check if AMQP port is listening
sudo ss -lntp | grep 5672

# Check RabbitMQ status
docker exec rabbitmq rabbitmqctl status

# Check RabbitMQ cluster status
docker exec rabbitmq rabbitmqctl cluster_status

# Test connection with rabbitmqadmin
docker exec rabbitmq rabbitmqadmin -u ${RABBITMQ_USER} -p ${RABBITMQ_PASS} list queues
```

---

### Docker DNS/MTU Issues

If RabbitMQ fails to start with network errors:

```bash
# Check Docker daemon.json
cat /etc/docker/daemon.json

# Should contain:
# {
#   "dns": ["8.8.8.8", "8.8.4.4"],
#   "mtu": 1400
# }

# If missing, run install.sh again or manually add it:
sudo nano /etc/docker/daemon.json
sudo systemctl restart docker
```

---

## Maintenance Operations

### View Real-time Logs

```bash
# Container logs
docker logs -f rabbitmq

# Nginx access logs
sudo tail -f /var/log/nginx/access.log | grep rabbitmq.arpansahu.space

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

---

### Backup RabbitMQ Data

```bash
# Backup data directory
sudo tar -czf rabbitmq-backup-$(date +%Y%m%d).tar.gz /var/lib/rabbitmq

# Backup definitions (users, vhosts, queues, exchanges)
docker exec rabbitmq rabbitmqctl export_definitions /tmp/definitions.json
docker cp rabbitmq:/tmp/definitions.json ./rabbitmq-definitions-$(date +%Y%m%d).json

# List backups
ls -lh rabbitmq-backup-*.tar.gz
ls -lh rabbitmq-definitions-*.json
```

---

### Restore RabbitMQ Data

```bash
# Stop RabbitMQ
docker stop rabbitmq
docker rm rabbitmq

# Restore data directory
sudo rm -rf /var/lib/rabbitmq
sudo tar -xzf rabbitmq-backup-YYYYMMDD.tar.gz -C /
sudo chown -R 999:999 /var/lib/rabbitmq

# Start RabbitMQ
./install.sh

# Import definitions
docker cp rabbitmq-definitions-YYYYMMDD.json rabbitmq:/tmp/definitions.json
docker exec rabbitmq rabbitmqctl import_definitions /tmp/definitions.json
```

---

### Update RabbitMQ

To update to the latest RabbitMQ version:

```bash
# Backup first!
sudo tar -czf rabbitmq-backup-$(date +%Y%m%d).tar.gz /var/lib/rabbitmq

# Pull latest image
docker pull rabbitmq:3-management

# Stop and remove old container
docker stop rabbitmq
docker rm rabbitmq

# Run installation again
./install.sh
```

---

### Monitor RabbitMQ

```bash
# Check node status
docker exec rabbitmq rabbitmqctl node_health_check

# List all queues
docker exec rabbitmq rabbitmqctl list_queues name messages consumers

# List all connections
docker exec rabbitmq rabbitmqctl list_connections name peer_host peer_port state

# List all exchanges
docker exec rabbitmq rabbitmqctl list_exchanges name type

# Check memory usage
docker exec rabbitmq rabbitmqctl status | grep memory
```

---

## Security Best Practices

1. **Strong Password:** Always use a strong, unique password in your `.env` file
2. **Localhost Binding:** AMQP and Management ports only bind to 127.0.0.1
3. **HTTPS Only:** External access only through Nginx with HTTPS
4. **Firewall Rules:** Ensure ports 5672 and 15672 are not exposed to the internet
5. **Environment Variables:** Never commit `.env` file to version control
6. **User Management:** Create separate users for different applications
7. **Virtual Hosts:** Use vhosts to isolate different applications
8. **Regular Backups:** Backup data and definitions regularly
9. **Updates:** Keep RabbitMQ and Docker updated
10. **SSL/TLS:** For production, consider enabling SSL on AMQP port 5672

---

## Quick Reference

### Important Files

- **Environment template:** [`.env.example`](./.env.example)
- **Environment config:** `.env` (create from .env.example)
- **Installation script:** [`install.sh`](./install.sh)
- **Nginx configuration:** [`nginx.conf`](./nginx.conf)
- **Nginx setup script:** [`add-nginx-conf.sh`](./add-nginx-conf.sh)
- **Test script (localhost):** [`test_rabbitmq_localhost.py`](./test_rabbitmq_localhost.py) - Run on server
- **Test script (domain HTTPS):** [`test_rabbitmq_domain_https.sh`](./test_rabbitmq_domain_https.sh) - Run from Mac

### Important Commands

```bash
# Install RabbitMQ
./install.sh

# Configure Nginx (automated)
sudo bash add-nginx-conf.sh

# Or configure Nginx (manual)
sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Access Management UI
# Browser: https://rabbitmq.arpansahu.space

# Test connections
python3 test_rabbitmq_localhost.py       # On server
RABBITMQ_PASS=password ./test_rabbitmq_domain_https.sh  # From Mac

# View logs
docker logs -f rabbitmq

# Check status
docker exec rabbitmq rabbitmqctl status

# List queues
docker exec rabbitmq rabbitmqctl list_queues

# Restart container
docker restart rabbitmq

# Backup data
sudo tar -czf rabbitmq-backup-$(date +%Y%m%d).tar.gz /var/lib/rabbitmq
```

---

## Architecture Diagram

```
[Your Application]
       ↓ AMQP (5672)
[RabbitMQ Container] ← localhost only
       ↓ Management UI (15672)
[Nginx Reverse Proxy] ← HTTPS (443)
       ↓
[https://rabbitmq.arpansahu.space] ← Accessible externally
```

**Security layers:**
1. AMQP port 5672 only accessible on localhost
2. Management port 15672 only accessible on localhost
3. External access only via Nginx with HTTPS
4. Authentication required for all connections

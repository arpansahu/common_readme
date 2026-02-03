## Redis Server (Docker + Nginx STREAM + TLS)

Redis is a high-performance in-memory data store. This setup provides secure Redis with TLS encryption via Nginx.

---

## Test Files Overview

| Test File | Where to Run | Connection Type | Purpose |
|-----------|-------------|-----------------|---------|
| `test_redis_localhost.py` | **On Server** | localhost:6380 | Test Redis on server without TLS |
| `test_redis_domain_tls.py` | **From Mac** | redis.arpansahu.space:9551 | Test Redis from Mac with TLS via domain |

**Quick Test Commands:**
```bash
# On Server (localhost)
python3 test_redis_localhost.py

# From Mac (domain with TLS)
python3 test_redis_domain_tls.py
```

**CLI Testing (redis-cli):**
```bash
# On Server (localhost) - Basic commands
redis-cli -h 127.0.0.1 -p 6380 -a ${REDIS_PASSWORD} ping
redis-cli -h 127.0.0.1 -p 6380 -a ${REDIS_PASSWORD} SET test "hello"
redis-cli -h 127.0.0.1 -p 6380 -a ${REDIS_PASSWORD} GET test

# From Mac (domain with TLS) - Requires redis-cli with TLS support
redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a ${REDIS_PASSWORD} ping
redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a ${REDIS_PASSWORD} INFO server
```

---

## Step-by-Step Installation Guide

### Step 1: Create Environment Configuration

First, create the environment configuration file that will store your Redis password and port.

**Create `.env.example` (Template file):**

```bash
# Redis Configuration
REDIS_PASSWORD=your_secure_password_here
REDIS_PORT=6380
```

**Create your actual `.env` file:**

```bash
cd "AWS Deployment/redis"
cp .env.example .env
nano .env
```

**Your `.env` file should look like this (with your actual password):**

```bash
# Redis Configuration
REDIS_PASSWORD=Kesar302redis
REDIS_PORT=6380
```

**⚠️ Important:** 
- Always change the default password in production!
- Never commit your `.env` file to version control
- Keep the `.env.example` file as a template

---

### Step 2: Create Installation Script

Create the `install.sh` script that will automatically install Redis using the environment variables.

**Create `install.sh` file:**

```bash
#!/bin/bash
set -e

echo "=== Redis Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
REDIS_PASSWORD="${REDIS_PASSWORD:-Kesar302redis}"
REDIS_PORT="${REDIS_PORT:-6380}"

echo -e "${YELLOW}Step 1: Running Redis Container${NC}"
docker run -d \
  --name redis-external \
  --restart unless-stopped \
  -p 127.0.0.1:${REDIS_PORT}:6379 \
  redis:7 \
  redis-server --requirepass "$REDIS_PASSWORD"

echo -e "${YELLOW}Step 2: Waiting for Redis to start...${NC}"
sleep 3

echo -e "${YELLOW}Step 3: Verifying Installation${NC}"
docker ps | grep redis-external

echo -e "${GREEN}Redis installed successfully!${NC}"
echo -e "Container: redis-external"
echo -e "Port: 127.0.0.1:${REDIS_PORT}"
echo -e "Password: $REDIS_PASSWORD"
echo ""
echo -e "${YELLOW}Test connection:${NC}"
echo "redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a $REDIS_PASSWORD ping"
echo ""
echo -e "${YELLOW}Next steps for HTTPS access:${NC}"
echo "1. Configure Nginx stream block in /etc/nginx/nginx.conf"
echo "2. See nginx-stream.conf for configuration"
echo "3. Test and reload: sudo nginx -t && sudo systemctl reload nginx"
```

**Make it executable and run:**

```bash
chmod +x install.sh
./install.sh
```

**Expected output:**
```
=== Redis Installation Script ===
Loaded configuration from .env file
Step 1: Running Redis Container
Step 2: Waiting for Redis to start...
Step 3: Verifying Installation
redis-external
Redis installed successfully!
Container: redis-external
Port: 127.0.0.1:6380
Password: Kesar302redis
```

---

### Step 3: Configure Nginx Stream for TLS Access

Redis uses TCP protocol, not HTTP, so we need to configure Nginx's stream module (Layer 4 proxy).

**Create `nginx-stream.conf` file:**

```nginx
# Add this to the stream {} block in /etc/nginx/nginx.conf

stream {
    # Redis upstream
    upstream redis_upstream {
        server 127.0.0.1:6380;
    }

    # Redis with TLS
    server {
        listen 9551 ssl;
        proxy_pass redis_upstream;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;

        # Connection settings
        proxy_connect_timeout 5s;
        proxy_timeout 300s;
        proxy_buffer_size 16k;
    }
}
```

**What this configuration does:**
- Listens on port 9551 with SSL/TLS encryption
- Proxies TCP connections to Redis on localhost:6380
- Uses your wildcard SSL certificate for *.arpansahu.space
- Allows external TLS connections to redis.arpansahu.space:9551

---

### Step 4: Apply Nginx Stream Configuration

You have two options to apply the stream configuration:

#### Option 1: Automated (Recommended)

Create `add-nginx-stream.sh` script:

```bash
#!/bin/bash
set -e

echo "=== Adding Redis Stream Block to Nginx ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Backing up nginx.conf${NC}"
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding stream block from nginx-stream.conf${NC}"
# Remove the comment line and add to nginx.conf
grep -v "^# Add this to" "$SCRIPT_DIR/nginx-stream.conf" | sudo tee -a /etc/nginx/nginx.conf > /dev/null

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
sudo nginx -t

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
sudo systemctl reload nginx

echo -e "${YELLOW}Step 5: Verifying port 9551${NC}"
ss -lntp | grep 9551 || echo "Port not yet visible (may need a moment)"

echo -e "${GREEN}Redis TLS stream configured successfully!${NC}"
echo -e "Test with: redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a PASSWORD ping"
```

**Run the script:**

```bash
chmod +x add-nginx-stream.sh
sudo bash add-nginx-stream.sh
```

**Expected output:**
```
=== Adding Redis Stream Block to Nginx ===
Step 1: Backing up nginx.conf
Step 2: Adding stream block from nginx-stream.conf
Step 3: Testing nginx configuration
nginx: configuration file /etc/nginx/nginx.conf test is successful
Step 4: Reloading nginx
Step 5: Verifying port 9551
LISTEN 0 511 0.0.0.0:9551 0.0.0.0:*
Redis TLS stream configured successfully!
```

#### Option 2: Manual Configuration

```bash
# 1. Backup nginx.conf
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# 2. Edit nginx.conf
sudo nano /etc/nginx/nginx.conf

# 3. Add the stream block from nginx-stream.conf at the END of the file
# (outside the http block, at the same level)

# 4. Test configuration
sudo nginx -t

# 5. Reload nginx
sudo systemctl reload nginx

# 6. Verify port is listening
sudo ss -lntp | grep 9551
```

---

---

## Testing Your Redis Installation

After installation and Nginx configuration, test Redis connectivity using multiple methods:

### Test 1: From Docker Container

Test Redis directly inside the container:

```bash
# Simple ping test
docker exec redis-external redis-cli -a ${REDIS_PASSWORD} ping

# Set and get a value
docker exec redis-external redis-cli -a ${REDIS_PASSWORD} SET mykey "Hello Redis"
docker exec redis-external redis-cli -a ${REDIS_PASSWORD} GET mykey
```

**Expected output:**
```
PONG
OK
"Hello Redis"
```

---

### Test 2: From Server (Local)

Test Redis from the server itself using redis-cli:

```bash
# Install redis-tools if not already installed
sudo apt install -y redis-tools

# Test connection
redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a ${REDIS_PASSWORD} ping

# Set and get a value
redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a ${REDIS_PASSWORD} SET testkey "Hello from Server"
redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a ${REDIS_PASSWORD} GET testkey
```

**Expected output:**
```
PONG
OK
"Hello from Server"
```

---

### Test 3: From Your Mac (TLS Connection)

Test Redis from your local machine using TLS through Nginx:

```bash
# Install redis if not already installed
brew install redis

# Test connection via TLS (through nginx stream on port 9551)
redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a ${REDIS_PASSWORD} ping

# Set and get a value
redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a ${REDIS_PASSWORD} SET mackey "Hello from Mac"
redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a ${REDIS_PASSWORD} GET mackey
```

**Expected output:**
```
PONG
OK
"Hello from Mac"
```

**Note:** The `--insecure` flag skips certificate verification. For production, you should verify certificates properly.

---

## Connection Details Summary

After successful installation, your Redis setup will have:

- **Container Name:** `redis-external`
- **Local Connection:** `127.0.0.1:${REDIS_PORT}` (localhost only)
- **TLS Connection:** `redis.arpansahu.space:9551` (accessible externally)
- **Password:** `${REDIS_PASSWORD}` (from your .env file)
- **Data Directory:** `~/redis/data` (if you add volumes)

---

## Using Redis in Your Applications

### Python Connection Example

Install the Redis Python client:

```bash
pip install redis
```

**Local connection (from server):**

```python
import redis

# Local connection
r = redis.Redis(
    host='127.0.0.1',
    port=${REDIS_PORT},
    password='${REDIS_PASSWORD}',
    decode_responses=True
)

# Test connection
r.set('test', 'hello')
print(r.get('test'))  # Output: hello
```

**TLS connection (from anywhere):**

```python
import redis

# TLS connection
r = redis.Redis(
    host='redis.arpansahu.space',
    port=9551,
    password='${REDIS_PASSWORD}',
    ssl=True,
    ssl_cert_reqs='required',
    decode_responses=True
)

# Test connection
r.set('test', 'hello')
print(r.get('test'))  # Output: hello
```

---

### Router Port Forwarding Configuration

**⚠️ Required for external access (from outside your home network)**

If you want to access Redis from outside your local network (e.g., from mobile data, other locations), you need to configure port forwarding on your router.

**Steps for Airtel Router:**

1. **Login to router admin panel:**
   - Open browser and go to: `http://192.168.1.1`
   - Enter admin credentials

2. **Navigate to Port Forwarding:**
   - Go to `NAT` → `Port Forwarding` tab
   - Click "Add new rule"

3. **Configure port forwarding rule:**
   - **Service Name:** User Define
   - **External Start Port:** 9551
   - **External End Port:** 9551
   - **Internal Start Port:** 9551
   - **Internal End Port:** 9551
   - **Server IP Address:** 192.168.1.200 (your server's local IP)
   - **Protocol:** TCP (or TCP/UDP)

4. **Activate the rule:**
   - Click save/apply
   - The rule should appear in the port forwarding list with status "Active"

**Verify port forwarding:**
```bash
# From external network (mobile data or different location)
redis-cli -h redis.arpansahu.space -p 9551 --tls -a your_password PING
```

**Note:** Port forwarding is NOT required if you only access Redis from devices on the same local network (192.168.1.x).

---

### Django Configuration

Add Redis as Django cache backend in `settings.py`:

```python
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'rediss://redis.arpansahu.space:9551/0',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'PASSWORD': '${REDIS_PASSWORD}',
        }
    }
}
```

**Install django-redis:**

```bash
pip install django-redis
```

**Use in your Django views:**

```python
from django.core.cache import cache

# Set a value
cache.set('my_key', 'my_value', timeout=300)

# Get a value
value = cache.get('my_key')
```

---

## Troubleshooting

### Container Issues

If Redis container is not running properly:

```bash
# Check container logs
docker logs redis-external

# Restart container
docker restart redis-external

# Remove and reinstall
docker stop redis-external
docker rm redis-external
./install.sh
```

---

### Connection Test Failed

If you cannot connect to Redis:

**For local connection:**

```bash
# Check if container is running
docker ps | grep redis-external

# Check if port is listening
sudo ss -lntp | grep ${REDIS_PORT}

# Test connection
redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a ${REDIS_PASSWORD} ping
```

**For TLS connection:**

```bash
# Check if nginx is listening on port 9551
sudo ss -lntp | grep 9551

# Check nginx stream configuration
sudo nginx -T | grep -A 20 "stream {"

# Test with redis-cli
redis-cli -h redis.arpansahu.space -p 9551 -a ${REDIS_PASSWORD} --tls --insecure ping
```

---

### Nginx Configuration Issues

If Nginx fails to start or reload:

```bash
# Test nginx configuration
sudo nginx -t

# Check nginx error logs
sudo tail -f /var/log/nginx/error.log

# Verify stream block exists
sudo grep -A 20 "stream {" /etc/nginx/nginx.conf

# Restore from backup if needed
sudo cp /etc/nginx/nginx.conf.backup-YYYYMMDD-HHMMSS /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl reload nginx
```

---

## Maintenance Operations

### View Real-time Logs

```bash
docker logs -f redis-external
```

---

### Backup Redis Data

If you have persistence enabled (with volumes):

```bash
# Create backup
tar -czf redis-backup-$(date +%Y%m%d).tar.gz ~/redis/data

# List backups
ls -lh redis-backup-*.tar.gz
```

---

### Update Redis

To update to the latest Redis version:

```bash
# Pull latest Redis image
docker pull redis:7

# Stop and remove old container
docker stop redis-external
docker rm redis-external

# Run installation again
./install.sh
```

---

## Security Best Practices

1. **Strong Password:** Always use a strong, unique password in your `.env` file
2. **Localhost Binding:** Redis container only binds to 127.0.0.1 (not accessible directly from internet)
3. **TLS Encryption:** External access only through Nginx with TLS encryption
4. **Firewall Rules:** Ensure port 6380 is not exposed to the internet, only port 9551 through Nginx
5. **Environment Variables:** Never commit `.env` file to version control
6. **Regular Updates:** Keep Redis and Nginx updated to latest stable versions

---

## Quick Reference

### Important Files

- **Environment template:** [`.env.example`](./.env.example)
- **Environment config:** `.env` (create from .env.example)
- **Installation script:** [`install.sh`](./install.sh)
- **Nginx stream config:** [`nginx-stream.conf`](./nginx-stream.conf)
- **Nginx setup script:** [`add-nginx-stream.sh`](./add-nginx-stream.sh)
- **Test script (localhost):** [`test_redis_localhost.py`](./test_redis_localhost.py) - Run on server
- **Test script (domain TLS):** [`test_redis_domain_tls.py`](./test_redis_domain_tls.py) - Run from Mac

### Important Commands

```bash
# Install Redis
./install.sh

# Configure Nginx stream
sudo bash add-nginx-stream.sh

# Test connections
python3 test_redis_localhost.py          # On server
python3 test_redis_domain_tls.py         # From Mac

# Test with redis-cli (manual)
redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a ${REDIS_PASSWORD} ping
redis-cli -h redis.arpansahu.space -p 9551 --tls --insecure -a ${REDIS_PASSWORD} ping

# View logs
docker logs -f redis-external

# Restart container
docker restart redis-external

# Check nginx stream
sudo nginx -T | grep -A 20 "stream {"
```

---

## Architecture Diagram

```
[Your Application]
       ↓
[redis.arpansahu.space:9551] ← TLS encrypted
       ↓
[Nginx Stream Proxy] ← SSL termination
       ↓
[127.0.0.1:6380] ← Redis Container (localhost only)
```

**Security layers:**
1. Redis only accessible on localhost
2. Nginx provides TLS encryption for external access
3. Password authentication required for all connections

---

## Django Integration with Redis TLS

### Environment Variables

```env
# Redis with TLS (rediss:// scheme)
REDIS_CLOUD_URL=rediss://:your_redis_password@redis.arpansahu.space:9551
```

### Django Settings (settings.py)

#### Cache Configuration

```python
import ssl
import os

REDIS_CLOUD_URL = os.getenv('REDIS_CLOUD_URL')

# Django Cache with Redis TLS
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_CLOUD_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'ssl_cert_reqs': ssl.CERT_REQUIRED  # Verify Let's Encrypt cert
            }
        }
    }
}
```

#### Celery Configuration

```python
# Celery broker and result backend
CELERY_BROKER_URL = REDIS_CLOUD_URL
CELERY_RESULT_BACKEND = REDIS_CLOUD_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'

# Celery SSL Configuration
CELERY_REDIS_BACKEND_USE_SSL = {
    'ssl_cert_reqs': ssl.CERT_REQUIRED  # Verify SSL certificates
}
CELERY_BROKER_USE_SSL = {
    'ssl_cert_reqs': ssl.CERT_REQUIRED  # Verify SSL certificates
}
```

### Celery App (celery.py)

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')

app = Celery('your_project')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
```

### Requirements

```txt
django-redis>=5.2.0
redis>=4.5.0
celery>=5.2.0
```

### Verification

```bash
# Test Django cache
python manage.py shell
>>> from django.core.cache import cache
>>> cache.set('test_key', 'test_value', 300)
>>> cache.get('test_key')
'test_value'

# Expected Celery worker logs
[INFO/MainProcess] Connected to rediss://:**@redis.arpansahu.space:9551//
[INFO/MainProcess] celery@your_project ready.
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `[SSL: CERTIFICATE_VERIFY_FAILED]` | Wrong SSL verification setting | Use `ssl.CERT_REQUIRED` - Let's Encrypt certs are trusted |
| Connection timeout | Wrong port or host | Use port 9551, ensure nginx stream proxy is running |
| Authentication failed | Wrong password | Check REDIS_CLOUD_URL password matches Redis setup |
| Connection refused | Redis not running | Check: `docker ps \| grep redis` |

### SSL Certificate Verification

**Important:** Use `ssl.CERT_REQUIRED` (secure) instead of `ssl.CERT_NONE` (insecure).

Let's Encrypt certificates at `/etc/nginx/ssl/arpansahu.space/` are automatically trusted by Python's SSL library. No need to disable certificate verification.

```python
# ✅ CORRECT - Secure with certificate verification
'ssl_cert_reqs': ssl.CERT_REQUIRED

# ❌ WRONG - Insecure, don't use in production
'ssl_cert_reqs': ssl.CERT_NONE
```

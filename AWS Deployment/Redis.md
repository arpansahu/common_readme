## Redis Server (Docker + Nginx STREAM + TLS)

Redis is a high-performance in-memory data store widely used for caching, queues, pub/sub, and real-time workloads. In production, Redis **should not be exposed directly** and must be secured properly.

This guide explains a **secure, production-ready Redis setup** using **Docker**, **Nginx TCP stream**, and **TLS**.

---

## Installing Redis and Setting Up Authentication (Docker Based)

### Step 1: Prerequisites

1. **Docker installed and running**

   ```sh
   docker --version
   ```

2. **Nginx installed with stream module enabled**

   ```sh
   nginx -V 2>&1 | grep stream
   ```

3. **Valid TLS certificates** for `arpansahu.space`

---

### Step 2: Run Redis Using Docker (Secure by Default)

We intentionally **do NOT install Redis via apt** to avoid system conflicts and port issues.

1. **Start Redis container**

   ```sh
   docker run -d \
     --name redis-external \
     --restart unless-stopped \
     -p 127.0.0.1:6380:6379 \
     -v ~/redis/data:/data \
     redis:7 \
     redis-server \
       --requirepass Kesar302redis \
       --appendonly yes \
       --save 900 1 \
       --save 300 10 \
       --save 60 10000
   ```

   **Key points:**

   * Redis runs **inside Docker**
   * Redis listens only on **localhost (127.0.0.1)**
   * Redis requires authentication
   * **Dual persistence enabled:**
     * AOF (Append-Only File) - logs every write for maximum durability
     * RDB snapshots at 3 intervals (15min, 5min, 1min)
   * Data stored in `~/redis/data` for easy backup/access
   * Redis is **NOT publicly exposed**

2. **Verify Redis container**

   ```sh
   docker ps | grep redis-external
   ```

3. **Verify port binding**

   ```sh
   sudo ss -lntp | grep 6380
   ```

   Expected: `127.0.0.1:6380` listening

---

## Nginx Stream Configuration (TLS Proxy)

### Why Use Nginx Stream for Redis?

- Adds TLS encryption to Redis connections
- Single wildcard certificate
- Centralized access control
- Redis doesn't need native TLS configuration

### Configuration

Edit `/etc/nginx/nginx.conf` and add to the `stream {}` block:

```nginx
stream {
    # Redis upstream
    upstream redis_upstream {
        server 127.0.0.1:6380;
    }

    server {
        listen 9551 ssl;
        proxy_pass redis_upstream;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
        ssl_dhparam         /etc/nginx/ssl/dhparam.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_tickets off;

        proxy_timeout 1h;
        proxy_connect_timeout 5s;
    }
}
```

Reload Nginx:

```sh
sudo nginx -t
sudo systemctl reload nginx
```

---

## Firewall Configuration

Allow only the **Nginx Redis port**:

```sh
sudo ufw allow 9551/tcp
sudo ufw reload
```

> **Never open ports 6379 or 6380 publicly**

---

## Connecting to Redis

### 1. From External Client (TLS-capable)

```sh
redis-cli -h arpansahu.space -p 9551 -a Kesar302redis --tls --cacert /etc/ssl/cert.pem ping
```

Expected:

```
PONG
```

### 2. From the Server Itself (Recommended)

Use Docker-based CLI (host `redis-cli` may be broken):

```sh
docker run -it --rm redis:7 redis-cli -h 127.0.0.1 -p 6380 -a Kesar302redis ping
```

---

## Django Integration

Install dependencies:

```sh
pip install redis
```

In `settings.py`:

```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'rediss://arpansahu.space:9551',  # Note: rediss:// for TLS
        'OPTIONS': {
            'PASSWORD': 'Kesar302redis',
            'ssl_cert_reqs': None,  # For self-signed certs
        }
    }
}
```

Test:

```python
from django.core.cache import cache
cache.set('test_key', 'test_value', 60)
print(cache.get('test_key'))  # Should print: test_value
```

---

## Redis Commander (Web UI)

See [redis_commander/README.md](redis_commander/README.md) for setting up a web-based Redis management interface.

Access: https://redis.arpansahu.space

---

## Important Security Notes

* Redis is **NOT installed via apt**
* Redis is **NOT bound to 0.0.0.0**
* Redis is **NOT exposed directly**
* Redis does **NOT handle TLS itself**
* TLS is handled by **Nginx STREAM**
* Port `9551` is the **only public Redis entry point**

---

## Why We Do NOT Use the Old Method Anymore

| Old Setup                  | New Setup        |
| -------------------------- | ---------------- |
| `apt install redis-server` | Docker Redis     |
| `bind 0.0.0.0`             | `127.0.0.1` only |
| No TLS                     | TLS via Nginx    |
| Public 6379                | Private Redis    |
| High attack risk           | Secure           |

---

## Advanced Configuration

### Redis with Memory Limits

If you need to limit Redis memory usage (recommended for production):

```sh
docker run -d \
  --name redis-external \
  --restart unless-stopped \
  -p 127.0.0.1:6380:6379 \
  -v ~/redis/data:/data \
  --memory="512m" \
  redis:7 \
  redis-server \
    --requirepass Kesar302redis \
    --appendonly yes \
    --save 900 1 \
    --save 300 10 \
    --save 60 10000 \
    --maxmemory 256mb \
    --maxmemory-policy allkeys-lru
```

**Memory settings explained:**
- `--memory="512m"` - Docker container memory limit
- `--maxmemory 256mb` - Redis internal memory limit
- `--maxmemory-policy allkeys-lru` - Evict least recently used keys when memory is full



---

## Troubleshooting

### Connection Refused

Check if Redis container is running:

```sh
docker ps | grep redis-external
docker logs redis-external
```

### Authentication Failed

Verify password in connection string matches the `requirepass` value.

### TLS Handshake Failed

Ensure certificates are valid:

```sh
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates
```

---

## Final Redis Access Summary

```bash
# External (TLS)
redis-cli -h arpansahu.space -p 9551 -a Kesar302redis --tls --cacert /etc/ssl/cert.pem ping

# Internal (Docker CLI)
docker run -it --rm redis:7 redis-cli -h 127.0.0.1 -p 6380 -a Kesar302redis ping
```

---

## Benefits of This Setup

✔ Faster
✔ Safer
✔ Easier recovery
✔ No system conflicts
✔ Production-grade
✔ TLS encrypted
✔ Isolated in Docker
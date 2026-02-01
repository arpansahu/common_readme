# Redis Commander - Web-Based Redis Management UI

Redis Commander is a web-based management tool that provides an intuitive interface to interact with Redis databases. This guide covers installation via npm + PM2 with nginx reverse proxy and HTTPS.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Nginx Setup](#nginx-setup)
- [Verification](#verification)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Security](#security)

## 🎯 Overview

This deployment provides:
- **Redis Commander** installed via npm
- **PM2** for process management and auto-restart
- **Nginx** reverse proxy with HTTPS
- **Built-in HTTP authentication** (no separate htpasswd needed)
- **WebSocket support** for real-time updates

**Access:** `https://redis.arpansahu.space`

## ✨ Features

Redis Commander provides:
- **Visual Key Browser**: Browse keys with tree view
- **Key Management**: View, edit, delete keys
- **Multiple Data Types**: Support for strings, lists, sets, hashes, sorted sets
- **TTL Management**: View and set key expiration
- **Command Console**: Execute Redis commands directly
- **Real-time Updates**: WebSocket-based live updates
- **Multiple Connections**: Connect to multiple Redis instances
- **Import/Export**: Backup and restore data

## ✅ Prerequisites

### Required

- **Ubuntu 22.04** or later
- **Redis Server** installed and running
  ```bash
  redis-cli -h 127.0.0.1 -p 6380 -a your_password ping
  # Should return: PONG
  ```

- **Node.js** (v16 or later) and npm
  ```bash
  # Install Node.js 20.x
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  ```

- **Nginx** with SSL certificates at `/etc/nginx/ssl/arpansahu.space/`

### Verify Prerequisites

```bash
# Check Redis
redis-cli -h 127.0.0.1 -p 6380 -a your_password ping

# Check Node.js
node --version  # Should be v16+
npm --version

# Check Nginx
nginx -v
ls -la /etc/nginx/ssl/arpansahu.space/
```

## 🏗️ Architecture

### System Architecture

```
┌──────────────────────────────────────────┐
│  Internet (HTTPS)                        │
│  https://redis.arpansahu.space           │
└────────────────┬─────────────────────────┘
                 │
                 │ Port 443 (HTTPS)
                 │
         ┌───────▼────────┐
         │  Nginx (443)   │
         │  SSL + Proxy   │
         └───────┬────────┘
                 │
                 │ HTTP (localhost)
                 │
    ┌────────────▼──────────────┐
    │  Redis Commander (8082)   │
    │  Node.js + PM2            │
    │  HTTP Auth enabled        │
    └────────────┬──────────────┘
                 │
                 │ Redis Protocol
                 │
         ┌───────▼────────┐
         │  Redis (6380)  │
         │  Localhost     │
         └────────────────┘
```

### Security Layers

1. **HTTPS Encryption**: All traffic encrypted via SSL/TLS
2. **HTTP Basic Auth**: Built-in authentication in Redis Commander
3. **Localhost Binding**: Redis Commander only accessible locally
4. **Redis Password**: Redis requires authentication
5. **No Public Exposure**: Redis never exposed to internet

### Process Management

```
PM2 Daemon
    └─ redis-commander
        ├─ Auto-restart on crash
        ├─ Auto-start on boot
        ├─ Log rotation
        └─ Resource monitoring
```

## 📦 Installation

### Step 1: Prepare Environment

Navigate to the Redis Commander deployment directory:

```bash
cd "AWS Deployment/redis_commander"
```

Copy the example environment file and configure:

```bash
cp .env.example .env
nano .env
```

**Configure `.env`:**

```bash
# Redis Connection
REDIS_HOST=127.0.0.1
REDIS_PORT=6380
REDIS_PASSWORD=your_actual_redis_password

# Redis Commander Port
REDIS_COMMANDER_PORT=8082

# HTTP Authentication (built-in)
HTTP_AUTH_USERNAME=arpansahu
HTTP_AUTH_PASSWORD=your_strong_password_here

# Domain
DOMAIN=redis.arpansahu.space
```

**Important Notes:**

1. **REDIS_PASSWORD**: Must match your Redis server password
2. **HTTP_AUTH_PASSWORD**: This protects Redis Commander UI
3. **PORT 8082**: Ensure this port is free (check with `ss -lntp | grep 8082`)

### Step 2: Run Installation Script

The installation script will:
- Install redis-commander via npm (if not present)
- Install PM2 process manager (if not present)
- Test Redis connection
- Start Redis Commander with PM2
- Configure PM2 startup script

```bash
chmod +x install.sh
./install.sh
```

**Expected Output:**

```
========================================
Redis Commander Installation
========================================

✓ Loaded configuration from .env
Node.js version: v20.20.0
NPM version: 10.9.2
✓ PM2 already installed
✓ Redis Commander already installed
✓ Redis connection successful
Starting Redis Commander with PM2...
✓ Redis Commander started
✓ Redis Commander is online
Saving PM2 process list...
✓ PM2 startup configured

========================================
Installation Complete!
========================================

┌─────┬───────────────────┬─────────────┬─────────┬─────────┬──────────┐
│ id  │ name              │ namespace   │ version │ mode    │ status   │
├─────┼───────────────────┼─────────────┼─────────┼─────────┼──────────┤
│ 0   │ redis-commander   │ default     │ N/A     │ fork    │ online   │
└─────┴───────────────────┴─────────────┴─────────┴─────────┴──────────┘

Redis Commander is running at:
  http://127.0.0.1:8082

Next steps:
  1. Run: sudo ./add-nginx-config.sh
  2. Access via: https://redis.arpansahu.space
```

### Step 3: Verify Local Access

Test Redis Commander is running locally:

```bash
# Check process
pm2 list

# Check port is listening
ss -lntp | grep 8082

# Test HTTP access (with auth)
curl -u "arpansahu:your_password" http://127.0.0.1:8082
```

Expected: HTML response with Redis Commander UI

## ⚙️ Configuration

### Redis Commander CLI Options

The PM2 process uses these arguments:

| Option | Value | Description |
|--------|-------|-------------|
| `--redis-host` | 127.0.0.1 | Redis server hostname |
| `--redis-port` | 6380 | Redis server port |
| `--redis-password` | password | Redis authentication |
| `--port` | 8082 | Redis Commander listen port |
| `--http-auth-username` | arpansahu | UI username |
| `--http-auth-password` | password | UI password |

### Additional Options

For multiple Redis instances:

```bash
pm2 start redis-commander \
    --name redis-commander \
    -- \
    --redis-host "redis1:127.0.0.1:6380:0:password,redis2:127.0.0.1:6381:0:password2"
```

For specific Redis database:

```bash
--redis-db 0  # Use database 0
```

For read-only mode:

```bash
--read-only true
```

### Environment Variables

Redis Commander also supports environment variables:

```bash
export REDIS_HOSTS=local:127.0.0.1:6380:0:password
export HTTP_USER=arpansahu
export HTTP_PASSWORD=your_password
export PORT=8082

pm2 start redis-commander --name redis-commander
```

## 🌐 Nginx Setup

### Step 1: Configure Nginx

Run the nginx configuration script:

```bash
chmod +x add-nginx-config.sh
sudo ./add-nginx-config.sh
```

**What it does:**

1. ✅ Validates nginx and SSL certificates
2. ✅ Checks Redis Commander is running
3. ✅ Detects and removes existing configuration
4. ✅ Adds server blocks for HTTP → HTTPS redirect
5. ✅ Configures HTTPS with WebSocket support
6. ✅ Tests and reloads nginx

**Expected Output:**

```
========================================
Redis Commander Nginx Configuration
========================================

✓ Configuration added
✓ Nginx configuration test passed
✓ Nginx reloaded successfully

========================================
Configuration Complete!
========================================

Redis Commander is now accessible at:
https://redis.arpansahu.space
```

### Step 2: Verify Nginx Configuration

```bash
# Check syntax
sudo nginx -t

# View configuration
sudo grep -A 20 "Redis Commander" /etc/nginx/sites-available/services

# Check nginx is listening
sudo ss -lntp | grep :443
```

### Manual Nginx Configuration

If you prefer manual setup, add this to `/etc/nginx/sites-available/services`:

```nginx
# Redis Commander
server {
    listen 80;
    listen [::]:80;
    server_name redis.arpansahu.space;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name redis.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (important for real-time updates)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

Then:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## ✔️ Verification

### Check All Components

```bash
# 1. Redis is running
redis-cli -h 127.0.0.1 -p 6380 -a your_password ping
# Expected: PONG

# 2. PM2 status
pm2 status
# Expected: redis-commander | online

# 3. Redis Commander port
ss -lntp | grep 8082
# Expected: LISTEN 127.0.0.1:8082

# 4. Nginx status
sudo systemctl status nginx
# Expected: active (running)

# 5. HTTPS access
curl -I https://redis.arpansahu.space
# Expected: HTTP/2 200
```

### Test Local Access

```bash
# With authentication
curl -u "arpansahu:your_password" http://127.0.0.1:8082

# Check authentication is required
curl http://127.0.0.1:8082
# Expected: 401 Unauthorized
```

### Test Web Access

1. **Open Browser**: Navigate to `https://redis.arpansahu.space`

2. **Login Prompt**: You should see HTTP Basic Auth dialog
   - Username: `arpansahu`
   - Password: Your configured password

3. **Redis Commander UI**: After login, you should see:
   - Redis connection status (green = connected)
   - Key browser on the left
   - Command console at bottom
   - Database selector (db0, db1, etc.)

4. **Test Functionality**:
   - Browse existing keys
   - Create a test key: `test:key` with value `hello`
   - View the key
   - Delete the key

### Verify PM2 Auto-Start

```bash
# Check PM2 is configured for startup
pm2 startup

# Should show: "PM2 startup script already configured"

# Verify process is saved
ls ~/.pm2/dump.pm2
# File should exist

# Test by simulating reboot
pm2 kill
pm2 resurrect
# redis-commander should come back online
```

## 🔧 Management

### PM2 Commands

**View Status:**
```bash
pm2 status
pm2 info redis-commander
```

**View Logs:**
```bash
# Real-time logs
pm2 logs redis-commander

# Last 100 lines
pm2 logs redis-commander --lines 100

# Error logs only
pm2 logs redis-commander --err

# Log files location
ls ~/.pm2/logs/redis-commander-*.log
```

**Restart:**
```bash
# Restart process
pm2 restart redis-commander

# Restart with new environment
pm2 restart redis-commander --update-env
```

**Stop/Start:**
```bash
# Stop
pm2 stop redis-commander

# Start
pm2 start redis-commander

# Start with different config
pm2 start redis-commander -- --port 9000
```

**Delete Process:**
```bash
pm2 delete redis-commander
pm2 save
```

**Monitoring:**
```bash
# Real-time monitoring
pm2 monit

# Web-based dashboard
pm2 plus
```

### Update Redis Commander

```bash
# Stop current process
pm2 stop redis-commander

# Update globally
sudo npm update -g redis-commander

# Check new version
redis-commander --version

# Restart
pm2 restart redis-commander
```

### Change Configuration

To update Redis connection or port:

```bash
# Update .env file
nano .env

# Delete and recreate process
pm2 delete redis-commander
./install.sh
```

Or manually:

```bash
pm2 delete redis-commander

pm2 start redis-commander \
    --name redis-commander \
    -- \
    --redis-host 127.0.0.1 \
    --redis-port 6381 \
    --redis-password new_password \
    --port 8082 \
    --http-auth-username arpansahu \
    --http-auth-password new_ui_password

pm2 save
```

## 🔍 Troubleshooting

### Issue 1: Redis Commander Won't Start

**Symptoms**: PM2 shows status as "stopped" or "errored"

**Diagnosis:**
```bash
pm2 logs redis-commander
```

**Common Causes & Solutions:**

1. **Redis connection failed**
   ```
   Error: connect ECONNREFUSED 127.0.0.1:6380
   ```
   
   Fix:
   ```bash
   # Verify Redis is running
   redis-cli -h 127.0.0.1 -p 6380 -a password ping
   
   # Start Redis if needed
   sudo systemctl start redis-server
   ```

2. **Wrong Redis password**
   ```
   Error: NOAUTH Authentication required
   ```
   
   Fix: Update `.env` with correct password and reinstall

3. **Port already in use**
   ```
   Error: listen EADDRINUSE: address already in use :::8082
   ```
   
   Fix:
   ```bash
   # Find what's using the port
   sudo ss -lntp | grep 8082
   
   # Kill the process or use different port
   pm2 delete redis-commander
   pm2 start redis-commander -- --port 9000
   ```

### Issue 2: Cannot Access via Browser

**Symptoms**: HTTPS timeout or connection refused

**Diagnosis:**
```bash
# Test locally first
curl -u "arpansahu:password" http://127.0.0.1:8082

# Test HTTPS
curl -I https://redis.arpansahu.space
```

**Solutions:**

1. **Nginx not running**
   ```bash
   sudo systemctl status nginx
   sudo systemctl start nginx
   ```

2. **Nginx configuration error**
   ```bash
   sudo nginx -t
   # Fix any errors shown
   sudo systemctl reload nginx
   ```

3. **DNS not resolving**
   ```bash
   nslookup redis.arpansahu.space
   # Should return your server IP
   ```

4. **Firewall blocking**
   ```bash
   sudo ufw status
   sudo ufw allow 443/tcp
   ```

### Issue 3: Authentication Fails

**Symptoms**: Browser shows "401 Unauthorized" repeatedly

**Causes:**

1. **Wrong credentials in browser**
   - Clear browser cache and cookies
   - Use correct username/password from `.env`

2. **Credentials not passed to Redis Commander**
   ```bash
   pm2 info redis-commander
   # Check script args include --http-auth-username and --http-auth-password
   ```
   
   Fix:
   ```bash
   pm2 delete redis-commander
   ./install.sh  # Recreate with proper auth
   ```

3. **Special characters in password**
   - Wrap password in quotes in `.env`
   - Avoid characters like `$`, `` ` ``, `\` in passwords

### Issue 4: PM2 Not Persisting After Reboot

**Symptoms**: Redis Commander not running after server restart

**Fix:**

```bash
# Configure PM2 startup
pm2 startup

# Copy and run the command it outputs, example:
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u arpansahu --hp /home/arpansahu

# Save current process list
pm2 save

# Test by killing and resurrecting
pm2 kill
pm2 resurrect
```

### Issue 5: High Memory Usage

**Symptoms**: Redis Commander using excessive RAM

**Diagnosis:**
```bash
pm2 monit
# Check memory usage
```

**Solutions:**

1. **Restart periodically** (via cron):
   ```bash
   # Add to crontab
   0 3 * * * /usr/bin/pm2 restart redis-commander
   ```

2. **Limit memory** in PM2:
   ```bash
   pm2 start redis-commander --max-memory-restart 200M
   ```

### Issue 6: WebSocket Connection Failed

**Symptoms**: UI loads but doesn't update in real-time

**Fix in nginx config:**

```nginx
location / {
    proxy_pass http://127.0.0.1:8082;
    proxy_http_version 1.1;
    
    # These are critical for WebSocket
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

Then:
```bash
sudo systemctl reload nginx
```

## 🔒 Security

### Best Practices

1. **Use Strong Passwords**
   ```bash
   # Generate secure password
   openssl rand -base64 32
   ```

2. **Keep Software Updated**
   ```bash
   # Update Redis Commander
   sudo npm update -g redis-commander
   
   # Update Node.js
   sudo apt update && sudo apt upgrade nodejs
   
   # Update PM2
   sudo npm update -g pm2
   ```

3. **Monitor Access Logs**
   ```bash
   # Nginx access logs
   sudo tail -f /var/log/nginx/access.log | grep redis
   
   # PM2 logs
   pm2 logs redis-commander
   ```

4. **Restrict by IP** (Optional)
   
   Add to nginx server block:
   ```nginx
   location / {
       allow 192.168.1.0/24;  # Local network
       allow YOUR_OFFICE_IP;   # Office IP
       deny all;
       
       proxy_pass http://127.0.0.1:8082;
       ...
   }
   ```

5. **Use Read-Only Mode** (for monitoring only)
   ```bash
   pm2 start redis-commander -- --read-only true
   ```

### What NOT to Do

❌ **Don't expose Redis Commander port directly**
```bash
# BAD: Binding to all interfaces
pm2 start redis-commander -- --address 0.0.0.0
```

❌ **Don't disable HTTP authentication**
```bash
# BAD: No auth
pm2 start redis-commander  # without --http-auth-*
```

❌ **Don't use weak passwords**
```bash
# BAD: Weak passwords
HTTP_AUTH_PASSWORD=admin
HTTP_AUTH_PASSWORD=12345678
```

❌ **Don't expose Redis to internet**
```nginx
# BAD: Redis accessible externally
listen 0.0.0.0:6380;
```

### Security Checklist

✅ Redis Commander only on 127.0.0.1  
✅ HTTP authentication enabled  
✅ HTTPS encryption via nginx  
✅ Strong passwords configured  
✅ Redis never exposed publicly  
✅ PM2 logs rotated  
✅ Regular updates applied  
✅ Access logs monitored  

## 📚 Additional Resources

- [Redis Commander GitHub](https://github.com/joeferner/redis-commander)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [Redis Documentation](https://redis.io/documentation)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

## 🆘 Support

For issues:

1. Check [Troubleshooting](#troubleshooting) section
2. Review PM2 logs: `pm2 logs redis-commander`
3. Check nginx error logs: `sudo tail -f /var/log/nginx/error.log`
4. Verify all services are running:
   ```bash
   pm2 status
   sudo systemctl status nginx
   sudo systemctl status redis-server
   ```

## 📝 Summary

**Deployment Components:**

✅ Redis Commander (npm package)  
✅ PM2 process manager  
✅ Nginx reverse proxy with HTTPS  
✅ Built-in HTTP authentication  
✅ Auto-restart and boot persistence  

**Access Information:**

- **URL**: https://redis.arpansahu.space
- **Username**: From `.env` (HTTP_AUTH_USERNAME)
- **Password**: From `.env` (HTTP_AUTH_PASSWORD)
- **Internal**: http://127.0.0.1:8082

**Key Files:**

- Configuration: `AWS Deployment/redis_commander/.env`
- Install script: `AWS Deployment/redis_commander/install.sh`
- Nginx script: `AWS Deployment/redis_commander/add-nginx-config.sh`
- PM2 logs: `~/.pm2/logs/redis-commander-*.log`
- Nginx config: `/etc/nginx/sites-available/services`

**Useful Commands:**

```bash
# Status
pm2 status

# Logs
pm2 logs redis-commander

# Restart
pm2 restart redis-commander

# Access
https://redis.arpansahu.space
```

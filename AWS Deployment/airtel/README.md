# Airtel Router Admin Panel - HTTPS Access Setup

Complete guide for accessing your Airtel router admin panel securely via HTTPS using nginx reverse proxy, including port forwarding configuration for remote access.

## 📋 Table of Contents

- [Overview](#overview)
- [Why This Setup](#why-this-setup)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Part 1: Router Configuration](#part-1-router-configuration)
- [Part 2: Port Forwarding](#part-2-port-forwarding)
- [Part 3: Nginx Setup](#part-3-nginx-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Security](#security)

## 🎯 Overview

This setup provides:
- **HTTPS Access**: Secure encrypted access to router admin panel
- **Custom Domain**: Easy-to-remember URL (`https://airtel.arpansahu.space`)
- **Remote Access**: Access router from anywhere via internet
- **Professional Setup**: No need to remember IP addresses and ports

**Access Methods:**
- Local Network: `https://airtel.arpansahu.space` (via server's nginx)
- Direct Local: `http://192.168.1.1:81` (bypassing nginx)
- Remote: `https://airtel.arpansahu.space` (requires port forwarding)

## 🤔 Why This Setup

### Benefits

1. **Ease of Access**
   - Memorable URL instead of `http://192.168.1.1:81`
   - Works from any device on your network
   - Bookmarkable and shareable

2. **Security**
   - HTTPS encryption for all admin panel access
   - SSL certificate validation
   - Secure remote access without exposing router directly

3. **Centralized Management**
   - Single nginx configuration for all services
   - Consistent SSL certificate usage
   - Professional infrastructure setup

4. **Remote Management**
   - Configure router settings from anywhere
   - Manage port forwarding rules remotely
   - Troubleshoot network issues without being on-site

### Use Cases

- **Remote Network Management**: Change router settings while traveling
- **Port Forwarding Setup**: Configure game servers, applications remotely
- **Troubleshooting**: Check router status, restart services from anywhere
- **Guest WiFi Management**: Update guest network settings remotely
- **Parental Controls**: Modify access rules for devices

## ✅ Prerequisites

Before starting, ensure you have:

### Required

- **Airtel Router** with admin web interface (port 81)
- **Ubuntu Server** (22.04 or later) on local network
- **Nginx** installed with SSL certificates at `/etc/nginx/ssl/arpansahu.space/`
- **Domain Name**: `airtel.arpansahu.space` with DNS pointing to your public IP
- **Router Admin Credentials**: Username and password for router login

### Optional (for Remote Access)

- **Static Public IP** or Dynamic DNS service
- **Domain DNS Management** access (Namecheap, Cloudflare, etc.)
- **Router Port Forwarding** capability

## 🏗️ Architecture

### Network Topology

```
Internet (Public IP: 122.176.93.72)
    ↓
    ↓ Port 443 forwarded to 192.168.1.200:443
    ↓
┌───────────────────────────────────────┐
│  Home Network (192.168.1.0/24)        │
│                                       │
│  ┌─────────────────┐                 │
│  │ Airtel Router   │                 │
│  │ 192.168.1.1:81  │ ← Local access  │
│  └────────┬────────┘                 │
│           │                           │
│           │ LAN                       │
│           │                           │
│  ┌────────▼──────────┐               │
│  │ Ubuntu Server      │               │
│  │ 192.168.1.200:443  │               │
│  │                    │               │
│  │  ┌──────────────┐  │               │
│  │  │   Nginx      │  │               │
│  │  │ Reverse Proxy│  │               │
│  │  └──────────────┘  │               │
│  └────────────────────┘               │
└───────────────────────────────────────┘
```

### Access Flow

**Local Access (same network):**
```
Your Device → https://airtel.arpansahu.space → Nginx (192.168.1.200:443) → Router (192.168.1.1:81)
```

**Remote Access (internet):**
```
Your Device → DNS → Public IP (122.176.93.72:443) → Router Port Forward → Nginx (192.168.1.200:443) → Router (192.168.1.1:81)
```

### Why Port Forwarding is Needed

Port forwarding is required for **remote access** (accessing from outside your home network). Here's why:

1. **NAT Barrier**: Your home network is behind NAT (Network Address Translation)
2. **Single Public IP**: All home devices share one public IP
3. **Port Mapping**: Router needs to know which internal device receives external traffic
4. **Without Port Forward**: External requests to your public IP are dropped
5. **With Port Forward**: Router redirects port 443 traffic to your server (192.168.1.200:443)

**What Port Forwarding Does:**
```
External Request: https://airtel.arpansahu.space (resolves to 122.176.93.72:443)
                           ↓
Router Receives: Traffic on public IP port 443
                           ↓
Port Forward Rule: 443 → 192.168.1.200:443
                           ↓
Nginx Receives: Request on 192.168.1.200:443
                           ↓
Nginx Proxies: To router admin at 192.168.1.1:81
```

**Without port forwarding**, remote HTTPS requests would reach your public IP but the router wouldn't know to send them to your server.

## 📝 Part 1: Router Configuration

### Step 1: Change Router Admin Port

**Why**: Free port 80 for nginx and avoid conflicts

1. **Access Router Locally**
   ```
   http://192.168.1.1
   ```

2. **Login** with admin credentials:
   - Default username: `admin`
   - Password: Usually on router label or `admin`/`password`

3. **Navigate to Admin Settings**
   
   Common paths:
   - Advanced → Web Management
   - System → Remote Management  
   - Administration → Management
   - Settings → Admin Panel

4. **Change Admin UI Port**
   
   ```
   Current: Port 80
   Change to: Port 81
   ```

5. **Save and Reboot Router** (if required)

6. **Verify New Access**
   ```bash
   # Test from local machine
   curl -I http://192.168.1.1:81
   ```

   Expected: HTTP 200 OK or redirect to login page

### Step 2: Note Router Credentials

Document your router admin credentials:

```bash
# Create .env file (not committed to git)
cd "AWS Deployment/airtel"
cp .env.example .env
nano .env
```

Update with your actual credentials:
```bash
ROUTER_USERNAME=admin
ROUTER_PASSWORD=your_actual_password
```

## 🔀 Part 2: Port Forwarding

Port forwarding is **mandatory for remote access** but **optional if you only need local network access**.

### Understanding Port Forwarding

**Scenario Without Port Forward:**
- You're at a coffee shop
- You browse to `https://airtel.arpansahu.space`
- DNS resolves to your public IP: `122.176.93.72`
- Request reaches your router on port 443
- **Router doesn't know where to send it** → Connection timeout

**Scenario With Port Forward:**
- You're at a coffee shop
- You browse to `https://airtel.arpansahu.space`
- DNS resolves to `122.176.93.72`
- Request reaches router on port 443
- **Router forwards to `192.168.1.200:443`** (your server)
- Nginx receives request and proxies to router admin
- ✅ Router admin panel loads

### Step 1: Determine Your Public IP

```bash
# Check current public IP
curl -s ifconfig.me
```

Example output: `122.176.93.72`

This is the IP address the internet uses to reach your home network.

### Step 2: Access Router Port Forwarding Settings

1. **Login to Router Admin Panel**
   ```
   http://192.168.1.1:81
   ```

2. **Navigate to Port Forwarding**
   
   Common menu locations:
   - **Airtel**: Advanced → NAT → Port Forwarding
   - **TP-Link**: Advanced → NAT Forwarding → Virtual Servers
   - **D-Link**: Advanced → Port Forwarding
   - **Netgear**: Advanced → Advanced Setup → Port Forwarding

### Step 3: Add Port Forwarding Rules

You need to forward **HTTPS (443)** and **HTTP (80)** ports:

#### Rule 1: HTTPS (Port 443) - Primary

| Parameter | Value |
|-----------|-------|
| Service Name | nginx-https or airtel-admin-https |
| External Port | 443 |
| Internal Port | 443 |
| Internal IP | 192.168.1.200 |
| Protocol | TCP |
| Status | Enabled |

**Why port 443**: All HTTPS traffic (including `https://airtel.arpansahu.space`) uses port 443.

#### Rule 2: HTTP (Port 80) - Redirect

| Parameter | Value |
|-----------|-------|
| Service Name | nginx-http or airtel-admin-http |
| External Port | 80 |
| Internal Port | 80 |
| Protocol | TCP |
| Internal IP | 192.168.1.200 |
| Status | Enabled |

**Why port 80**: Redirects HTTP to HTTPS automatically (handled by nginx).

### Step 4: Save and Apply

1. Click "Add" or "Save"
2. Apply configuration
3. Reboot router if prompted

### Step 5: Verify Port Forwarding

**From External Network (Mobile Data or Different WiFi):**

```bash
# Test HTTPS (should work)
curl -I https://airtel.arpansahu.space

# Test HTTP (should redirect to HTTPS)
curl -I http://airtel.arpansahu.space
```

**Expected Results:**

```
# HTTPS Response
HTTP/2 200
server: nginx
...

# HTTP Response  
HTTP/1.1 301 Moved Permanently
Location: https://airtel.arpansahu.space/
...
```

### Common Port Forwarding Issues

**Problem**: Port forwarding not working

**Causes & Solutions:**

1. **ISP Blocks Port 80/443**
   - Check: Contact ISP or test with `telnet YOUR_PUBLIC_IP 443`
   - Solution: Use non-standard ports (8443) or VPN

2. **Dynamic Public IP Changed**
   - Check: `curl ifconfig.me` and compare with DNS
   - Solution: Set up Dynamic DNS (DDNS)

3. **Double NAT** (Router behind another router)
   - Check: Modem/ONT in router mode
   - Solution: Set modem to bridge mode or forward on both devices

4. **Firewall Blocking**
   - Check: Server firewall rules
   - Solution: `sudo ufw allow 443/tcp && sudo ufw allow 80/tcp`

5. **Wrong Internal IP**
   - Check: Server IP with `ip addr show`
   - Solution: Update port forward rule with correct IP

### Security Considerations for Port Forwarding

⚠️ **Important Security Notes:**

1. **Only Forward Necessary Ports**
   - Forward ports 80 and 443 only
   - Do NOT forward router's port 81 directly to internet

2. **Why Not Forward Router Directly**
   ```
   ❌ BAD: External 81 → Router 192.168.1.1:81
      Exposes router admin directly to internet
      No SSL encryption
      Vulnerable to brute force attacks
   
   ✅ GOOD: External 443 → Nginx 192.168.1.200:443 → Router 192.168.1.1:81
      SSL encrypted
      Protected by nginx
      Rate limiting possible
   ```

3. **Use Strong Router Password**
   - Never use default passwords
   - Use complex passwords (12+ characters)
   - Change regularly

4. **Monitor Access Logs**
   ```bash
   sudo tail -f /var/log/nginx/access.log | grep airtel
   ```

5. **Consider VPN Alternative**
   - Set up WireGuard/OpenVPN on server
   - Access entire home network securely
   - No need to expose individual services

## 🚀 Part 3: Nginx Setup

### Step 1: Copy Configuration Files

```bash
# On local machine
cd "/Users/arpansahu/projects/common_readme/AWS Deployment/airtel"

# Copy to server
scp add-nginx-config.sh nginx-config.conf .env.example arpansahu@192.168.1.200:'AWS Deployment/airtel/'
```

### Step 2: Run Installation Script

```bash
# SSH to server
ssh arpansahu@192.168.1.200

# Navigate to airtel directory
cd 'AWS Deployment/airtel'

# Make script executable
chmod +x add-nginx-config.sh

# Run as root
sudo ./add-nginx-config.sh
```

**What the script does:**

1. ✅ Validates nginx installation
2. ✅ Checks SSL certificates exist
3. ✅ Detects existing configuration
4. ✅ Adds Airtel router server block to `/etc/nginx/sites-available/services`
5. ✅ Tests nginx configuration
6. ✅ Reloads nginx service

**Expected Output:**

```
========================================
Airtel Router Nginx Configuration
========================================

✓ Configuration added
✓ Nginx configuration test passed
✓ Nginx reloaded successfully

========================================
Configuration Complete!
========================================

Airtel Router Admin Panel is now accessible at:
https://airtel.arpansahu.space
```

### Step 3: Verify Nginx Configuration

```bash
# Check syntax
sudo nginx -t

# View configuration
sudo grep -A 20 "Airtel Router" /etc/nginx/sites-available/services

# Check nginx is listening on 443
sudo netstat -tlnp | grep :443
```

## ✔️ Verification

### Local Network Tests

**Test 1: Check nginx is running**
```bash
sudo systemctl status nginx
```

Expected: `active (running)`

**Test 2: Test HTTP to HTTPS redirect**
```bash
curl -I http://airtel.arpansahu.space
```

Expected:
```
HTTP/1.1 301 Moved Permanently
Location: https://airtel.arpansahu.space/
```

**Test 3: Test HTTPS access**
```bash
curl -I https://airtel.arpansahu.space
```

Expected:
```
HTTP/2 200
server: nginx
```

**Test 4: Access via browser**

Open browser and navigate to:
```
https://airtel.arpansahu.space
```

You should see the Airtel router login page with:
- ✅ HTTPS lock icon in address bar
- ✅ Valid SSL certificate
- ✅ Router login form

### Remote Access Tests

**From Mobile Data or Different Network:**

1. **Disconnect from home WiFi**
2. **Use mobile data** or different network
3. **Browse to**: `https://airtel.arpansahu.space`

Expected: Router login page loads

**Command Line Test:**
```bash
# From external network
curl -I https://airtel.arpansahu.space

# Should return HTTP 200 or 302 (redirect to login)
```

### DNS Verification

```bash
# Check DNS resolution
nslookup airtel.arpansahu.space

# Should return your public IP
# Example: 122.176.93.72
```

### Router Access Test

1. **Login to Router**
   - URL: `https://airtel.arpansahu.space`
   - Username: `admin`
   - Password: Your router password

2. **Verify Features Work**
   - Navigate through router settings
   - Check WiFi settings load
   - Test configuration changes
   - Verify port forwarding page loads

## 🔧 Troubleshooting

### Issue 1: Cannot Access Locally

**Symptoms**: `https://airtel.arpansahu.space` doesn't work on local network

**Diagnosis:**
```bash
# Check nginx is running
sudo systemctl status nginx

# Check nginx is listening
sudo netstat -tlnp | grep :443

# Check configuration
sudo nginx -t

# Test router direct access
curl -I http://192.168.1.1:81
```

**Solutions:**

1. **Nginx not running**
   ```bash
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```

2. **Configuration error**
   ```bash
   sudo nginx -t
   # Fix any errors shown
   sudo systemctl reload nginx
   ```

3. **Router port wrong**
   - Verify router admin is on port 81
   - Update nginx config if different port

4. **DNS not resolving locally**
   ```bash
   # Add to /etc/hosts temporarily
   echo "192.168.1.200 airtel.arpansahu.space" | sudo tee -a /etc/hosts
   ```

### Issue 2: Cannot Access Remotely

**Symptoms**: Works locally but not from external network

**Diagnosis:**
```bash
# Test from mobile data
curl -I https://airtel.arpansahu.space

# Check public IP
curl ifconfig.me

# Verify DNS points to public IP
nslookup airtel.arpansahu.space
```

**Solutions:**

1. **Port forwarding not configured**
   - Review [Part 2: Port Forwarding](#part-2-port-forwarding)
   - Verify rules are enabled
   - Reboot router

2. **DNS points to wrong IP**
   - Update DNS A record to your public IP
   - Wait for DNS propagation (5-60 minutes)

3. **ISP blocks port 443**
   ```bash
   # Test if port is open
   telnet YOUR_PUBLIC_IP 443
   ```
   - If timeout, contact ISP
   - Alternative: Use non-standard port (8443)

4. **Firewall blocking**
   ```bash
   # Allow HTTPS on server
   sudo ufw allow 443/tcp
   sudo ufw status
   ```

5. **Dynamic IP changed**
   - Check if public IP changed: `curl ifconfig.me`
   - Update DNS or set up DDNS

### Issue 3: SSL Certificate Errors

**Symptoms**: Browser shows "Not Secure" or certificate warning

**Solutions:**

1. **Certificate expired**
   ```bash
   # Check certificate expiry
   sudo openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates
   
   # Renew with certbot
   sudo certbot renew
   ```

2. **Wrong certificate path**
   ```bash
   # Verify paths in nginx config
   sudo grep ssl_certificate /etc/nginx/sites-available/services
   
   # Verify files exist
   ls -la /etc/nginx/ssl/arpansahu.space/
   ```

3. **Certificate doesn't cover subdomain**
   - Ensure certificate is wildcard or includes `airtel.arpansahu.space`
   - Reissue certificate if needed

### Issue 4: Router Login Fails

**Symptoms**: Page loads but login doesn't work

**Solutions:**

1. **Cookie issues**
   - Try different browser
   - Clear cookies
   - Check if router uses IP-based sessions

2. **Proxy headers missing**
   Update nginx config:
   ```nginx
   location / {
       proxy_pass http://192.168.1.1:81;
       proxy_set_header Host $http_host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
       proxy_set_header Referer http://192.168.1.1:81;
   }
   ```

3. **Direct access to verify credentials**
   ```
   http://192.168.1.1:81
   ```
   - If login works directly, issue is nginx configuration
   - If fails, credentials are wrong

### Issue 5: Page Elements Don't Load

**Symptoms**: Login page loads but CSS/JS missing

**Solutions:**

Add to nginx location block:
```nginx
location / {
    proxy_pass http://192.168.1.1:81;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Fix for static assets
    proxy_redirect http://192.168.1.1:81/ /;
    proxy_redirect http://192.168.1.1/ /;
    
    # Disable proxy buffering for real-time updates
    proxy_buffering off;
}
```

Then reload nginx:
```bash
sudo systemctl reload nginx
```

## 🔒 Security

### Best Practices

1. **Use Strong Router Password**
   ```
   ❌ Bad: admin, password, 12345678
   ✅ Good: Random 16+ character password with symbols
   ```

2. **Enable HTTPS Only**
   - Never allow unencrypted access
   - HTTP should always redirect to HTTPS
   - Verify with: `curl -I http://airtel.arpansahu.space`

3. **Restrict Access by IP (Optional)**
   
   If you only access from known IPs:
   ```nginx
   location / {
       allow 192.168.1.0/24;   # Local network
       allow YOUR_OFFICE_IP;    # Office IP
       deny all;
       
       proxy_pass http://192.168.1.1:81;
       ...
   }
   ```

4. **Monitor Access Logs**
   ```bash
   # Watch real-time access
   sudo tail -f /var/log/nginx/access.log | grep airtel
   
   # Check for suspicious activity
   sudo grep airtel /var/log/nginx/access.log | grep -v "200\|301\|302"
   ```

5. **Rate Limiting**
   
   Prevent brute force attacks:
   ```nginx
   # In /etc/nginx/nginx.conf (http block)
   limit_req_zone $binary_remote_addr zone=router:10m rate=10r/m;
   
   # In server block for airtel
   location / {
       limit_req zone=router burst=5;
       proxy_pass http://192.168.1.1:81;
       ...
   }
   ```

6. **Regular Updates**
   ```bash
   # Keep router firmware updated
   # Check router admin panel for updates
   
   # Keep server updated
   sudo apt update && sudo apt upgrade
   ```

### Alternative: VPN Access

For maximum security, consider **VPN instead of direct port forwarding**:

**Advantages:**
- No exposed ports to internet
- Encrypted tunnel for all traffic
- Access entire home network securely
- Protection against DDoS

**Setup:**
```bash
# Install WireGuard
sudo apt install wireguard

# Configure VPN server
# (See WireGuard documentation)
```

**With VPN:**
```
Your Device → VPN Tunnel → Home Network → http://192.168.1.1:81
```

No need for nginx or port forwarding for router access.

### What NOT to Do

❌ **Don't expose router admin port directly to internet**
```
External Port 81 → Router 192.168.1.1:81
```
This is extremely dangerous!

❌ **Don't use HTTP only** (without HTTPS redirect)

❌ **Don't use default router passwords**

❌ **Don't forward unnecessary ports**

❌ **Don't disable router firewall**

## 📚 Additional Resources

- [Nginx Proxy Configuration](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Let's Encrypt SSL](https://letsencrypt.org/)
- [Port Forwarding Guide](https://portforward.com/)
- [Dynamic DNS Services](https://www.noip.com/)

## 🆘 Support

If you encounter issues:

1. Check [Troubleshooting](#troubleshooting) section
2. Verify all prerequisites are met
3. Test each component individually:
   - Router direct access: `http://192.168.1.1:81`
   - Nginx listening: `sudo netstat -tlnp | grep :443`
   - DNS resolution: `nslookup airtel.arpansahu.space`
   - Port forwarding: Test from external network

## 📝 Summary

**What You've Accomplished:**

✅ Airtel router admin accessible via HTTPS  
✅ Custom domain: `https://airtel.arpansahu.space`  
✅ SSL encrypted access  
✅ Port forwarding configured for remote access  
✅ Nginx reverse proxy protecting router  
✅ Professional infrastructure setup  

**Access URLs:**

- **Local**: `https://airtel.arpansahu.space` (same network)
- **Remote**: `https://airtel.arpansahu.space` (from anywhere)
- **Direct**: `http://192.168.1.1:81` (local only, no SSL)

**Key Files:**

- Nginx Config: `/etc/nginx/sites-available/services` (Airtel server block)
- SSL Certificates: `/etc/nginx/ssl/arpansahu.space/`
- Setup Script: `AWS Deployment/airtel/add-nginx-config.sh`

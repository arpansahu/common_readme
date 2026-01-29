## Router Admin Panel via Nginx

This guide explains how to access your router admin panel through Nginx reverse proxy with a custom subdomain and HTTPS. This is useful for easy access without remembering IP addresses and port numbers.

### Prerequisites

Before configuring router admin access, ensure you have:

1. Ubuntu Server 22.04 LTS
2. Nginx with SSL certificates configured
3. Domain name (example: airtel.arpansahu.space)
4. Wildcard SSL certificate already issued
5. Router admin port changed from 80 to avoid conflicts
6. Root or sudo access

### Architecture Overview

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │
        └─ airtel.arpansahu.space
             │
             └─ Router Admin (192.168.1.1:81)
```

Key Principles:
- Router admin accessed via memorable subdomain
- HTTPS encryption for secure access
- No need to remember router IP and port
- Access from anywhere (with proper security)

### Why This Setup

**Benefits:**
- Easy to remember URL (https://airtel.arpansahu.space)
- HTTPS encryption for admin panel
- Centralized access management
- Works from anywhere with internet
- Professional setup

**Use Cases:**
- Remote router configuration
- Port forwarding management
- Network troubleshooting
- Quick access to router settings
- No need for VPN just for router access

### Part 1: Change Router Admin Port

This step is critical to free port 80 for Nginx.

#### For Airtel Routers

1. Access router locally

    ```
    http://192.168.1.1
    ```

    Login with router credentials (usually on router label).

2. Navigate to admin settings

    Path varies by model:
    - Advanced → Web Management
    - System → Remote Management
    - Administration → Management

3. Change admin UI port

    Change from:
    ```
    Port 80 → Port 81
    ```

4. Save and apply configuration

5. Verify new access URL

    ```
    http://192.168.1.1:81
    ```

    Router admin should now be accessible on port 81.

#### For Other Router Brands

**TP-Link:**
- System Tools → Administration
- Change Management Port: 80 → 81

**D-Link:**
- Tools → Admin
- Change HTTP Port: 80 → 81

**Netgear:**
- Advanced → Administration → Router Update
- Change Router Interface Port: 80 → 81

**Generic Process:**
- Find Web Management or Administration settings
- Locate HTTP Port or Admin Port setting
- Change from 80 to 81 (or any free port)
- Save and reboot router

### Part 2: Configure DNS

1. Add DNS A record

    For arpansahu.space domain in Namecheap:

    | Record Type | Host | Value | TTL |
    | ----------- | ---- | ----- | --- |
    | A | airtel | YOUR_STATIC_IP | 300 |

    Note: If using wildcard (*) record, this step is already covered.

2. Verify DNS propagation

    ```bash
    nslookup airtel.arpansahu.space
    ```

    Should return your static IP.

### Part 3: Configure Nginx Reverse Proxy

1. Edit Nginx services configuration

    ```bash
    sudo nano /etc/nginx/sites-available/services
    ```

2. Add router admin server block

    ```nginx
    # Router Admin Panel - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name airtel.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # Router Admin Panel - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name airtel.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
            proxy_pass http://192.168.1.1:81;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Disable buffering for responsive UI
            proxy_buffering off;
            proxy_request_buffering off;

            # Increase timeouts for slow router response
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }
    ```

3. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

    Expected output: syntax is ok, test is successful

4. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Part 4: Security Hardening (Critical)

⚠️ **Never expose router admin without protection**

Choose ONE of these security methods:

#### Option A: IP Whitelist (Recommended)

Restrict access to specific IP addresses only.

Update Nginx server block:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name airtel.arpansahu.space;

    ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

    # IP Whitelist
    allow YOUR_HOME_IP;
    allow YOUR_OFFICE_IP;
    allow YOUR_MOBILE_IP;
    deny all;

    location / {
        proxy_pass http://192.168.1.1:81;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Option B: HTTP Basic Authentication

Add password protection layer.

1. Create password file

    ```bash
    sudo apt install apache2-utils
    sudo htpasswd -c /etc/nginx/.htpasswd admin
    ```

    Enter strong password when prompted.

2. Update Nginx configuration

    ```nginx
    location / {
        auth_basic "Router Admin Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://192.168.1.1:81;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    ```

#### Option C: VPN-Only Access (Most Secure)

Best practice: Don't expose router admin to internet at all.

1. Set up VPN (Tailscale or WireGuard)

2. Remove router admin from public Nginx config

3. Access router via VPN only

    ```
    http://192.168.1.1:81
    ```

    or

    ```
    https://airtel.arpansahu.space (via VPN)
    ```

### Testing Router Admin Access

1. Test HTTPS access

    ```bash
    curl -I https://airtel.arpansahu.space
    ```

2. Access via browser

    Go to: https://airtel.arpansahu.space

3. Login with router credentials

    Use your router admin username and password.

4. Verify functionality

    - Check router status
    - View connected devices
    - Test configuration changes

### Common Router Admin Tasks

#### Port Forwarding Management

1. Access router admin

    https://airtel.arpansahu.space

2. Navigate to port forwarding

    Advanced → NAT → Port Forwarding

3. Add or modify rules

    | Service | External Port | Internal IP | Internal Port | Protocol |
    | ------- | ------------- | ----------- | ------------- | -------- |
    | HTTP | 80 | 192.168.1.100 | 80 | TCP |
    | HTTPS | 443 | 192.168.1.100 | 443 | TCP |

4. Save and apply

#### DHCP Reservation Management

1. Navigate to DHCP settings

    Network → DHCP → Static Lease

2. Add reservation

    - MAC Address: Device MAC
    - IP Address: 192.168.1.xxx
    - Description: Device name

3. Save configuration

#### Firewall Rules

1. Navigate to firewall

    Security → Firewall → Custom Rules

2. Add rules as needed

3. Apply configuration

### Common Issues and Fixes

1. Router admin not accessible

    Cause: Router firmware blocks reverse proxy

    Fix:

    Some routers check Host header. Try:

    ```nginx
    proxy_set_header Host 192.168.1.1:81;
    ```

    Instead of:

    ```nginx
    proxy_set_header Host $host;
    ```

2. Login page shows but cannot authenticate

    Cause: Session cookies not forwarding correctly

    Fix:

    Add to Nginx location block:

    ```nginx
    proxy_cookie_domain 192.168.1.1 airtel.arpansahu.space;
    proxy_cookie_path / /;
    ```

3. Blank page or infinite redirect

    Cause: Router expects specific URL structure

    Fix:

    Access directly via IP temporarily:

    ```
    http://192.168.1.1:81
    ```

    Some routers don't work well with reverse proxy.

4. SSL certificate error

    Cause: Wrong certificate path

    Fix:

    Verify certificate exists:

    ```bash
    openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates
    ```

5. 502 Bad Gateway

    Cause: Router not responding on port 81

    Fix:

    Verify router is accessible:

    ```bash
    curl -I http://192.168.1.1:81
    ```

### Security Best Practices

1. Always use strong router admin password

    - Minimum 16 characters
    - Mix of uppercase, lowercase, numbers, symbols
    - Not reused from other services

2. Implement IP whitelist

    Only allow access from known IPs.

3. Enable router firewall

    Block all unnecessary inbound connections.

4. Disable remote management in router

    Only allow local network access to router.
    Access remotely via Nginx proxy.

5. Keep router firmware updated

    Check for updates monthly:
    - Router Admin → System → Firmware Update

6. Monitor access logs

    ```bash
    sudo tail -f /var/log/nginx/access.log | grep airtel
    ```

7. Use VPN when possible

    Best security: Access router only via VPN.

### Alternative: VPN-Only Setup

Instead of exposing router admin to internet, use VPN:

1. Install Tailscale

    ```bash
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up
    ```

2. Access router via VPN

    ```
    http://192.168.1.1:81
    ```

3. No Nginx configuration needed

4. Much more secure

### Monitoring and Maintenance

1. Check Nginx access logs

    ```bash
    sudo grep airtel /var/log/nginx/access.log | tail -20
    ```

2. Monitor failed login attempts

    Check router admin logs for:
    - Failed authentication
    - Unusual access patterns
    - Unknown IP addresses

3. Regular security audits

    - Review IP whitelist monthly
    - Check for unauthorized access
    - Update router firmware
    - Rotate admin passwords quarterly

### Final Verification Checklist

Run these commands to verify setup:

```bash
# Check DNS resolution
nslookup airtel.arpansahu.space

# Check local router access
curl -I http://192.168.1.1:81

# Check Nginx configuration
sudo nginx -t

# Check HTTPS access
curl -I https://airtel.arpansahu.space

# Verify SSL certificate
openssl s_client -connect airtel.arpansahu.space:443 -servername airtel.arpansahu.space
```

Then test in browser:
- Access: https://airtel.arpansahu.space
- Verify HTTPS lock icon
- Login with router credentials
- Test basic functionality
- Check port forwarding page loads

### What This Setup Provides

After following this guide, you will have:

1. Easy-to-remember router admin URL
2. HTTPS encryption for admin panel
3. Remote access to router settings
4. Centralized access management
5. No need to remember IP:port combination
6. Professional domain-based access
7. Secure access (with proper protections)

### Important Security Warnings

⚠️ **DO NOT:**
- Expose router admin without IP whitelist or VPN
- Use default router admin passwords
- Allow unlimited login attempts
- Forget to update router firmware
- Share router admin credentials

⚠️ **ALWAYS:**
- Use strong passwords
- Enable IP whitelisting
- Monitor access logs
- Keep firmware updated
- Use VPN when possible

### Recommended Setup

For maximum security, use this approach:

1. Set up Tailscale VPN
2. Access router only via VPN
3. No public Nginx exposure
4. Or use IP whitelist if VPN not feasible

### Architecture Summary

```
Internet
   │
   └─ Nginx (HTTPS + IP Whitelist)
        │
        └─ Router Admin (192.168.1.1:81)
             │
             ├─ Port Forwarding Management
             ├─ DHCP Configuration
             ├─ Firewall Rules
             └─ Network Settings
```

### Next Steps

After setting up router admin access:

1. Test from different devices
2. Implement IP whitelist
3. Document router configuration
4. Set up monitoring
5. Regular security audits

My router admin: https://airtel.arpansahu.space (IP whitelisted)

For other services, see main documentation index.

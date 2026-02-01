### Part 4: Network Configuration

This section covers network setup for home server with static IP from ISP.

#### 1. Static IP from Internet Service Provider

For production home server setup, obtain a static IP from your ISP. This eliminates dynamic DNS complications and provides stable access.

**Benefits of Static IP:**
- No dynamic DNS required
- Consistent domain resolution
- More reliable for production
- Easier certificate management
- Professional setup

**Cost:** Usually $5-15/month additional to broadband plan

Contact your ISP to purchase static IP service.

#### 2. Domain Name Setup

Purchase domain from Namecheap for easy SSL certificate automation.

**Why Namecheap:**
- Excellent API for automation
- Works perfectly with acme.sh
- Affordable pricing (~$10-15/year)
- Easy DNS management
- Good support

1. Purchase domain

    Visit: https://www.namecheap.com

2. Configure DNS A records

    Point domain to your static IP:

    | Record Type | Host | Value | TTL |
    | ----------- | ---- | ----- | --- |
    | A | @ | YOUR_STATIC_IP | 300 |
    | A | * | YOUR_STATIC_IP | 300 |

    The wildcard (*) record covers all subdomains.

3. Enable Namecheap API

    - Login to Namecheap
    - Go to: Profile → Tools → API Access
    - Enable API Access
    - Whitelist your server's static IP
    - Note down API Key and Username

#### 3. Router Port Forwarding

Configure your router to forward traffic to home server.

1. Access router admin panel

    For Airtel routers, default is usually:
    ```
    http://192.168.1.1
    ```

2. Change router admin port (important)

    - Navigate to: Advanced → Web Management
    - Change admin port from 80 to 81
    - This frees port 80 for Nginx
    - Router admin will be accessible at: http://192.168.1.1:81

3. Set static DHCP reservation for server

    - Navigate to: Network → DHCP
    - Find your server's MAC address
    - Reserve IP: 192.168.1.200
    - This ensures server always gets same local IP

4. Configure port forwarding

    Navigate to: Advanced → NAT → Port Forwarding

    Add these rules:

    | Service | External Port | Internal IP | Internal Port | Protocol |
    | ------- | ------------- | ----------- | ------------- | -------- |
    | HTTP | 80 | 192.168.1.200 | 80 | TCP |
    | HTTPS | 443 | 192.168.1.200 | 443 | TCP |
    | SSH | 22 | 192.168.1.200 | 22 | TCP |

    **Security Note:** Only forward SSH (port 22) if you need external SSH access. Consider using VPN instead.

5. Save and apply configuration

#### 4. Server Network Configuration

1. Set static local IP on server

    Find network interface:

    ```bash
    ip addr show
    ```

2. Edit netplan configuration

    ```bash
    sudo nano /etc/netplan/00-installer-config.yaml
    ```

3. Configure static IP

    ```yaml
    network:
      version: 2
      renderer: networkd
      ethernets:
        enp0s3:  # Your interface name (use from ip addr show)
          dhcp4: no
          addresses:
            - 192.168.1.200/24  # Same as DHCP reservation in router
          routes:
            - to: default
              via: 192.168.1.1  # Your router IP
          nameservers:
            addresses:
              - 8.8.8.8
              - 8.8.4.4
    ```

4. Apply network configuration

    ```bash
    sudo netplan apply
    ```

5. Verify network connectivity

    ```bash
    ping -c 4 8.8.8.8
    ping -c 4 google.com
    ```

#### 5. Firewall Configuration

1. Install UFW (if not already installed)

    ```bash
    sudo apt install ufw
    ```

2. Configure firewall rules

    ```bash
    # Allow SSH
    sudo ufw allow 22/tcp

    # Allow HTTP/HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp

    # Enable firewall
    sudo ufw enable

    # Check status
    sudo ufw status verbose
    ```

3. Install Fail2Ban for SSH protection

    ```bash
    sudo apt install fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    ```

#### 6. Verify Network Setup

Run verification commands:

```bash
# Check static IP
ip addr show

# Check default route
ip route show

# Check DNS resolution
nslookup google.com

# Check internet connectivity
ping -c 4 8.8.8.8

# Check domain resolves to your IP
nslookup yourdomain.com

# Check ports are listening
sudo ss -tulnp | grep -E ':(80|443|22)'

# Check firewall status
sudo ufw status
```

Expected results:
- Server has static IP 192.168.1.200
- Can ping internet
- Domain resolves to your static IP
- Ports 80, 443, 22 are allowed in firewall
- Fail2Ban is active

#### 7. Optional: Router Admin Access via Nginx

You can access your router admin panel via subdomain for convenience.

This is already covered in router_admin_nginx.md (if you want to set this up).

**Security Warning:** Only do this with proper IP whitelisting or VPN access.

### SSL Certificate Setup

SSL certificate setup with acme.sh is covered in detail in:
- [Nginx HTTPS Setup Guide](nginx_https.md)

That guide includes:
- acme.sh installation
- Namecheap API configuration
- Wildcard certificate issuance
- Automatic renewal setup
- Nginx SSL configuration

Follow that guide after completing network setup.


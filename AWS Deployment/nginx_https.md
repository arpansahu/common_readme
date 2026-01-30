## Nginx HTTPS

This guide explains how to configure HTTPS for Nginx using wildcard SSL certificates with automatic renewal. This is the actual, production-tested setup using acme.sh with DNS-01 challenge for Namecheap.

### Prerequisites

Before configuring HTTPS, ensure you have:

1. Nginx already installed and configured (see nginx.md)
2. Domain name with DNS configured
3. Namecheap account with API access enabled
4. Root or sudo access
5. Basic Nginx configuration working

### Architecture Overview

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │
        └─ Backend Services (HTTP, localhost)
             ├─ Jenkins (8080)
             ├─ Portainer (9998)
             ├─ PgAdmin (5050)
             └─ Other Services
```

Key Principles:
- Nginx owns all TLS/SSL certificates
- Single wildcard certificate for all subdomains
- Automatic renewal via cron
- No Traefik, no Certbot complications
- Clean, debuggable setup

### Why acme.sh

We use acme.sh instead of Certbot or acme-dns for these reasons:

1. Native DNS-01 automation
2. Works perfectly with Namecheap
3. Simple cron-based auto-renewal
4. No systemd services required
5. No port 80/443 dependency
6. Cleaner than Certbot for wildcard certificates
7. Direct integration with 50+ DNS providers

### Certificate Coverage

The wildcard certificate covers:

```
arpansahu.space
*.arpansahu.space
```

This means all subdomains (jenkins.arpansahu.space, portainer.arpansahu.space, etc.) use the same certificate.

### Installing acme.sh

1. Download and install acme.sh

    ```bash
    curl https://get.acme.sh | sh
    ```

2. Reload shell configuration

    ```bash
    source ~/.bashrc
    ```

3. Set Let's Encrypt as default CA

    ```bash
    acme.sh --set-default-ca --server letsencrypt
    ```

4. Verify installation

    ```bash
    acme.sh --version
    ```

### Configuring Namecheap API Access

1. Enable Namecheap API access

    - Login to Namecheap
    - Go to: Profile → Tools → API Access
    - Enable API Access
    - Whitelist your server's public IP

2. Get API credentials

    - API Key: Found in API Access section
    - Username: Your Namecheap username
    - Source IP: Your server's public IP

3. Export environment variables

    ```bash
    export NAMECHEAP_API_KEY="YOUR_API_KEY"
    export NAMECHEAP_USERNAME="YOUR_USERNAME"
    export NAMECHEAP_SOURCEIP="YOUR_PUBLIC_IP"
    ```

4. Make credentials persistent (optional)

    Add to ~/.bashrc:

    ```bash
    echo 'export NAMECHEAP_API_KEY="YOUR_API_KEY"' >> ~/.bashrc
    echo 'export NAMECHEAP_USERNAME="YOUR_USERNAME"' >> ~/.bashrc
    echo 'export NAMECHEAP_SOURCEIP="YOUR_PUBLIC_IP"' >> ~/.bashrc
    source ~/.bashrc
    ```

### Issuing Wildcard Certificate

1. Issue certificate with DNS-01 challenge

    ```bash
    acme.sh --issue \
      --dns dns_namecheap \
      -d arpansahu.space \
      -d '*.arpansahu.space'
    ```

    This will:
    - Automatically create DNS TXT records
    - Validate domain ownership
    - Issue wildcard certificate
    - Store certificate in ~/.acme.sh/arpansahu.space_ecc/

2. Wait for DNS propagation

    The process may take 1-2 minutes as DNS records propagate.

3. Verify certificate

    ```bash
    openssl x509 -in ~/.acme.sh/arpansahu.space_ecc/fullchain.cer \
      -noout -subject -ext subjectAltName
    ```

    Expected output:
    ```
    subject=CN = arpansahu.space
    X509v3 Subject Alternative Name:
        DNS:arpansahu.space, DNS:*.arpansahu.space
    ```

### Installing Certificate for Nginx

1. Create SSL directory

    ```bash
    sudo mkdir -p /etc/nginx/ssl/arpansahu.space
    ```

2. Install certificate with automatic reload

    ```bash
    acme.sh --install-cert -d arpansahu.space \
      --key-file       /etc/nginx/ssl/arpansahu.space/privkey.pem \
      --fullchain-file /etc/nginx/ssl/arpansahu.space/fullchain.pem \
      --reloadcmd     "sudo systemctl reload nginx"
    ```

    This creates a hook that automatically reloads Nginx when certificate renews.

3. Set proper permissions

    ```bash
    sudo chmod 644 /etc/nginx/ssl/arpansahu.space/fullchain.pem
    sudo chmod 600 /etc/nginx/ssl/arpansahu.space/privkey.pem
    ```

4. Verify certificate files

    ```bash
    ls -la /etc/nginx/ssl/arpansahu.space/
    ```

### Configuring Nginx for HTTPS

1. Update Nginx TLS protocols

    Edit /etc/nginx/nginx.conf:

    ```bash
    sudo vi /etc/nginx/nginx.conf
    ```

    Find and update:

    ```nginx
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ```

2. Update service configuration

    Edit /etc/nginx/sites-available/services:

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

3. Add HTTPS server blocks (golden template)

    ```nginx
    # HTTP → HTTPS redirect
    server {
        listen 80;
        listen [::]:80;

        server_name jenkins.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # HTTPS reverse proxy
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        server_name jenkins.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;

        location / {
            proxy_pass http://127.0.0.1:8080;

            proxy_http_version 1.1;

            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
    ```

4. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

5. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Configuring Multiple Services

Repeat the server block pattern for each service:

1. Example: Portainer

    ```nginx
    # HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name portainer.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name portainer.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
            proxy_pass https://127.0.0.1:9443;
            proxy_ssl_verify off;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
        }
    }
    ```

    Note: Portainer uses its own HTTPS on port 9443, so we proxy to https:// instead of http://.

2. Example: PgAdmin

    ```nginx
    # HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name pgadmin.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name pgadmin.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
            proxy_pass http://127.0.0.1:5050;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
        }
    }
    ```

### Automatic Certificate Renewal

acme.sh automatically installs a cron job for certificate renewal.

1. Verify cron job

    ```bash
    crontab -l
    ```

    Expected output:
    ```
    0 0 * * * "/home/USERNAME/.acme.sh"/acme.sh --cron --home "/home/USERNAME/.acme.sh" > /dev/null
    ```

2. Test renewal (dry run)

    ```bash
    acme.sh --renew -d arpansahu.space --force --dry-run
    ```

3. Renewal flow

    - Certificate checks daily
    - Renews automatically 60 days before expiry
    - Updates files in /etc/nginx/ssl/arpansahu.space/
    - Nginx reloads automatically via hook
    - Zero manual intervention required

### Verifying HTTPS Setup

1. Check certificate validity

    ```bash
    openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem \
      -noout -dates -subject -ext subjectAltName
    ```

2. Test HTTPS locally

    ```bash
    curl -I https://jenkins.arpansahu.space
    ```

3. Check TLS ownership

    ```bash
    sudo ss -lntp | grep :443
    ```

    Expected: Only nginx should be listening on port 443.

4. Online SSL test

    Use: https://www.ssllabs.com/ssltest/

    Test your domain to verify SSL configuration quality.

### Important Notes About Traefik

If you're using k3s or Docker Swarm, be aware:

1. k3s installs Traefik by default

    Traefik will hijack port 443 and serve its own certificates.

2. Disable Traefik in k3s

    ```bash
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
    ```

3. Why Nginx, not Traefik

    - Nginx already handles HTTPS
    - Avoids port 443 conflicts
    - Simpler architecture
    - Single certificate management point
    - No certificate conflicts

### Common Issues and Fixes

1. Port 443 already in use

    Cause: Traefik or another service using port 443

    Fix:

    ```bash
    sudo ss -lntp | grep :443
    # Stop conflicting service
    # For k3s: reinstall with --disable=traefik
    ```

2. Certificate not found

    Cause: Certificate not installed to Nginx directory

    Fix:

    ```bash
    acme.sh --install-cert -d arpansahu.space \
      --key-file       /etc/nginx/ssl/arpansahu.space/privkey.pem \
      --fullchain-file /etc/nginx/ssl/arpansahu.space/fullchain.pem \
      --reloadcmd     "sudo systemctl reload nginx"
    ```

3. DNS-01 challenge fails

    Cause: Namecheap API not enabled or wrong credentials

    Fix:

    - Verify API is enabled in Namecheap
    - Check IP is whitelisted
    - Verify environment variables:
      ```bash
      echo $NAMECHEAP_API_KEY
      echo $NAMECHEAP_USERNAME
      echo $NAMECHEAP_SOURCEIP
      ```

4. Certificate not renewing

    Cause: Cron job missing or hook failed

    Fix:

    ```bash
    crontab -l  # Verify cron exists
    acme.sh --renew -d arpansahu.space --force
    ```

5. Nginx fails to reload

    Cause: Syntax error in configuration

    Fix:

    ```bash
    sudo nginx -t
    # Fix reported errors
    sudo systemctl reload nginx
    ```

### Security Best Practices

1. Use strong TLS protocols

    ```nginx
    ssl_protocols TLSv1.2 TLSv1.3;
    ```

2. Disable weak ciphers

    ```nginx
    ssl_prefer_server_ciphers off;
    ```

3. Enable HTTP/2

    ```nginx
    listen 443 ssl http2;
    ```

4. Add security headers

    ```nginx
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    ```

5. Hide Nginx version

    ```nginx
    server_tokens off;
    ```

### Certificate Management

1. List all certificates

    ```bash
    acme.sh --list
    ```

2. View certificate info

    ```bash
    acme.sh --info -d arpansahu.space
    ```

3. Force renewal

    ```bash
    acme.sh --renew -d arpansahu.space --force
    ```

4. Revoke certificate

    ```bash
    acme.sh --revoke -d arpansahu.space
    ```

5. Remove certificate

    ```bash
    acme.sh --remove -d arpansahu.space
    ```

### Final Verification Checklist

Run these commands to verify HTTPS is working:

```bash
# Check certificate validity
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates

# Check TLS ownership (should only show nginx)
sudo ss -lntp | grep :443

# Test Nginx configuration
sudo nginx -t

# Test HTTPS locally
curl -I https://jenkins.arpansahu.space

# Verify cron job
crontab -l | grep acme
```

### What This Setup Provides

After following this guide, you will have:

1. Wildcard SSL certificate covering all subdomains
2. Automatic certificate renewal (zero maintenance)
3. HTTPS for all services via single certificate
4. TLS 1.2 and 1.3 support
5. HTTP to HTTPS automatic redirection
6. Clean, debuggable configuration
7. No Traefik/Certbot complications
8. Production-ready SSL/TLS setup
9. Nginx as single point of TLS termination
10. 60-day advance renewal notifications

### Architecture Summary

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │ [Wildcard Certificate]
        │
        ├─ jenkins.arpansahu.space → localhost:8080
        ├─ portainer.arpansahu.space → localhost:9443
        ├─ pgadmin.arpansahu.space → localhost:5050
        └─ *.arpansahu.space → various localhost ports
```

### Key Rules to Remember

1. Nginx owns ALL TLS certificates
2. One wildcard certificate for all subdomains
3. acme.sh handles renewal automatically
4. Always proxy to localhost for security
5. Traefik must be disabled in k3s
6. Test config before reload: `sudo nginx -t`
7. Certificate location: /etc/nginx/ssl/arpansahu.space/
8. Renewal happens 60 days before expiry

### Example Service Ports

| Service      | Domain                          | Backend                |
| ------------ | ------------------------------- | ---------------------- |
| Jenkins      | jenkins.arpansahu.space         | http://127.0.0.1:8080  |
| Portainer    | portainer.arpansahu.space       | https://127.0.0.1:9443 |
| PgAdmin      | pgadmin.arpansahu.space         | http://127.0.0.1:5050  |
| RabbitMQ     | rabbitmq.arpansahu.space        | http://127.0.0.1:15672 |
| Kafka AKHQ   | kafka.arpansahu.space           | http://127.0.0.1:8086  |
| PostgreSQL   | postgres.arpansahu.space        | tcp://127.0.0.1:5432   |

Note: Portainer is the only service that uses HTTPS backend (9443).

### Next Steps

After completing HTTPS setup:

1. Test all services via HTTPS
2. Enable HTTP Strict Transport Security (HSTS)
3. Add security headers
4. Configure rate limiting
5. Set up monitoring for certificate expiry
6. Regular security audits

For Kubernetes setup, see: [Kubernetes with Portainer Setup](kubernetes_with_portainer/deployment.md)

# SSL Certificate Automation

Complete automation system for SSL certificate renewal and distribution across all services (Nginx, Kafka, Kubernetes, MinIO).

## Overview

When SSL certificates are renewed by acme.sh, the `deploy_certs.sh` script automatically:
1. ✅ Updates Nginx SSL certificates
2. ✅ Reloads Nginx
3. ✅ Regenerates Kafka keystores
4. ✅ Restarts Kafka
5. ✅ Updates Kubernetes secrets (arpansahu-tls, kafka-ssl-keystore)
6. ✅ Uploads keystores to MinIO for Django projects

## Quick Setup

```bash
# 1. Copy automation script to server
scp deploy_certs.sh arpansahu@arpansahu.space:~/
ssh arpansahu@arpansahu.space 'chmod +x ~/deploy_certs.sh'

# 2. Configure sudoers for passwordless automation
scp sudoers-k3s-ssl-automation arpansahu@arpansahu.space:/tmp/
ssh arpansahu@arpansahu.space 'sudo visudo -c -f /tmp/sudoers-k3s-ssl-automation && sudo mv /tmp/sudoers-k3s-ssl-automation /etc/sudoers.d/k3s-ssl-automation && sudo chown root:root /etc/sudoers.d/k3s-ssl-automation && sudo chmod 440 /etc/sudoers.d/k3s-ssl-automation'

# 3. Configure acme.sh to use deploy hook
ssh arpansahu@arpansahu.space
~/.acme.sh/acme.sh --install-cert -d arpansahu.space \
  --ecc \
  --cert-file /tmp/cert.pem \
  --key-file /tmp/key.pem \
  --fullchain-file /tmp/fullchain.pem \
  --reloadcmd "~/deploy_certs.sh"

# 4. Test the automation
ssh arpansahu@arpansahu.space '~/deploy_certs.sh'
```

---

## Files

### [`deploy_certs.sh`](./deploy_certs.sh)

Main automation script triggered by acme.sh after SSL renewal.

**Location on server:** `~/deploy_certs.sh`

**Triggered by:** acme.sh renewal (automatic) or manual execution

**What it does:**
1. Copies certificates from acme.sh to nginx
2. Reloads nginx
3. Regenerates Kafka SSL keystores
4. Restarts Kafka container
5. Updates K3s certificates and secrets
6. Uploads keystores to MinIO

### [`sudoers-k3s-ssl-automation`](./sudoers-k3s-ssl-automation)

Sudoers configuration for passwordless automation.

**Location on server:** `/etc/sudoers.d/k3s-ssl-automation`

**Permissions required:**
- kubectl operations
- File operations in /etc/nginx/ssl/
- Keystore generation (keytool, openssl)
- K3s certificate management

---

## SSL Certificate Flow

```
┌─────────────────┐
│   acme.sh       │  Renews SSL certificates (Let's Encrypt)
│   Cron Job      │  Schedule: March 4, 2026 (90 days)
└────────┬────────┘
         │
         ├─→ Executes: ~/deploy_certs.sh
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│                  deploy_certs.sh                        │
└─────────────────────────────────────────────────────────┘
         │
         ├─→ 1. Nginx SSL
         │   ├─ Copy: ~/.acme.sh/arpansahu.space_ecc/fullchain.cer
         │   │         → /etc/nginx/ssl/arpansahu.space/fullchain.pem
         │   ├─ Copy: ~/.acme.sh/arpansahu.space_ecc/arpansahu.space.key
         │   │         → /etc/nginx/ssl/arpansahu.space/privkey.pem
         │   └─ Reload: sudo systemctl reload nginx
         │
         ├─→ 2. Kafka SSL
         │   ├─ Script: ~/kafka-deployment/generate_ssl_from_nginx.sh
         │   ├─ Generate: kafka.keystore.jks, kafka.truststore.jks
         │   └─ Restart: docker compose -f docker-compose-kafka.yml restart
         │
         ├─→ 3. Kubernetes SSL
         │   ├─ Script: ~/k3s_scripts/1_renew_k3s_ssl_keystores.sh
         │   ├─ Generate: /var/lib/rancher/k3s/ssl/keystores/*.jks
         │   ├─ Secret: kubectl create secret tls arpansahu-tls
         │   └─ Secret: kubectl create secret generic kafka-ssl-keystore
         │
         └─→ 4. MinIO Upload
             ├─ Script: ~/k3s_scripts/2_upload_keystores_to_minio.sh
             ├─ Upload: fullchain.pem → s3://arpansahu-one-bucket/keystores/private/kafka/
             ├─ Upload: kafka.keystore.jks → MinIO
             └─ Upload: kafka.truststore.jks → MinIO
```

---

## Certificate Locations

### Source Certificates (Let's Encrypt)
```bash
~/.acme.sh/arpansahu.space_ecc/
├── fullchain.cer           # Full certificate chain
├── arpansahu.space.key     # Private key
├── arpansahu.space.cer     # Certificate only
└── ca.cer                  # CA certificate
```

### Nginx
```bash
/etc/nginx/ssl/arpansahu.space/
├── fullchain.pem    # Full certificate chain (public)
└── privkey.pem      # Private key (protected)
```

### Kafka (Docker)
```bash
~/kafka-deployment/ssl/
├── kafka.keystore.jks       # Java keystore
├── kafka.truststore.jks     # Trust store
├── keystore_creds           # Password file
└── truststore_creds         # Password file
```

### Kubernetes (K3s)
```bash
/var/lib/rancher/k3s/ssl/keystores/
├── kafka.keystore.jks       # Java keystore
├── kafka.truststore.jks     # Trust store
└── kafka.p12                # PKCS12 format

# Kubernetes Secrets
kubectl get secret arpansahu-tls          # TLS secret for Ingress
kubectl get secret kafka-ssl-keystore     # Keystore secret for Kafka pods
```

### MinIO (S3-compatible storage)
```bash
s3://arpansahu-one-bucket/keystores/private/kafka/
├── fullchain.pem            # SSL certificate (Django projects)
├── kafka.keystore.jks       # Java keystore
└── kafka.truststore.jks     # Trust store
```

**Access:** Private (requires authentication)

---

## Renewal Schedule

### Automatic Renewal

**acme.sh cron job:**
```bash
# Check daily at 10:45 AM
45 10 * * * ~/.acme.sh/acme.sh --cron --home ~/.acme.sh

# Actual renewal: 90 days from issue date
# Current certificate: Feb 3 - May 4, 2026
# Next renewal: March 4, 2026
```

### Verify Cron Job

```bash
# Check cron schedule
crontab -l | grep acme

# Check last renewal
~/.acme.sh/acme.sh --list

# Check certificate expiry
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates
```

### Manual Renewal

```bash
# Force renewal (testing)
~/.acme.sh/acme.sh --renew -d arpansahu.space --ecc --force

# Test deployment without renewal
~/deploy_certs.sh
```

---

## Service-Specific Details

### 1. Nginx SSL

**Certificates:**
- Location: `/etc/nginx/ssl/arpansahu.space/`
- Files: `fullchain.pem`, `privkey.pem`
- Used by: All HTTPS services (nginx reverse proxy)

**Reload command:**
```bash
sudo systemctl reload nginx
```

**Configuration:**
```nginx
# /etc/nginx/sites-enabled/services
ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
```

**Documentation:** [nginx SSL Setup](../02-nginx/README.md)

### 2. Kafka SSL

**Keystores:**
- Location: `~/kafka-deployment/ssl/`
- Files: `kafka.keystore.jks`, `kafka.truststore.jks`
- Used by: Kafka broker, AKHQ UI

**Generation script:**
```bash
cd ~/kafka-deployment
./generate_ssl_from_nginx.sh
```

**Restart command:**
```bash
docker compose -f docker-compose-kafka.yml restart
```

**Configuration:**
```properties
# server.properties
ssl.keystore.location=/opt/kafka/ssl/kafka.keystore.jks
ssl.keystore.password=Gandu302@kafkasslpass
ssl.truststore.location=/opt/kafka/ssl/kafka.truststore.jks
ssl.truststore.password=Gandu302@kafkasslpass
```

**Documentation:** [Kafka SSL Setup](../kafka/Kafka.md)

### 3. Kubernetes SSL

**Keystores:**
- Location: `/var/lib/rancher/k3s/ssl/keystores/`
- Files: `kafka.keystore.jks`, `kafka.truststore.jks`, `kafka.p12`
- Used by: K3s pods, Ingress TLS

**Generation script:**
```bash
cd ~/k3s_scripts
./1_renew_k3s_ssl_keystores.sh
```

**Kubernetes Secrets:**
```bash
# TLS secret for Ingress
kubectl get secret arpansahu-tls -o yaml

# Keystore secret for Kafka pods
kubectl get secret kafka-ssl-keystore -o yaml
```

**Mount in pods:**
```yaml
volumes:
- name: kafka-ssl
  secret:
    secretName: kafka-ssl-keystore
volumeMounts:
- name: kafka-ssl
  mountPath: /etc/kafka/ssl
  readOnly: true
```

**Documentation:** [K3s SSL Management](../kubernetes_k3s/README.md)

### 4. MinIO Storage

**Keystores:**
- Bucket: `arpansahu-one-bucket`
- Path: `keystores/private/kafka/`
- Files: `fullchain.pem`, `kafka.keystore.jks`, `kafka.truststore.jks`
- Used by: Django projects (dynamic fetch)

**Upload script:**
```bash
cd ~/k3s_scripts
./2_upload_keystores_to_minio.sh
```

**Access:**
- Endpoint: `https://minioapi.arpansahu.space`
- Authentication: Required (AWS credentials)
- Bucket Policy: Private (no public access)

**Django integration:**
```python
import boto3
from django.conf import settings

s3 = boto3.client('s3',
    endpoint_url=settings.AWS_S3_ENDPOINT_URL,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
)

# Download certificate
s3.download_file(
    Bucket='arpansahu-one-bucket',
    Key='keystores/private/kafka/fullchain.pem',
    Filename='/tmp/kafka-cert.pem'
)
```

**Documentation:** [Django Integration](../kubernetes_k3s/DJANGO_INTEGRATION.md)

---

## Troubleshooting

### Check Automation Status

```bash
# Test deploy script
ssh arpansahu@arpansahu.space '~/deploy_certs.sh'

# Check each component
ssh arpansahu@arpansahu.space 'sudo nginx -t && sudo systemctl status nginx'
ssh arpansahu@arpansahu.space 'docker ps | grep kafka'
ssh arpansahu@arpansahu.space 'kubectl get secrets'
ssh arpansahu@arpansahu.space 'mc ls minio/arpansahu-one-bucket/keystores/private/kafka/'
```

### Common Issues

#### 1. Sudo Password Required

**Symptom:** Script asks for password
**Solution:** Check sudoers file is installed correctly

```bash
ssh arpansahu@arpansahu.space 'sudo cat /etc/sudoers.d/k3s-ssl-automation'
# Should show NOPASSWD entries
```

#### 2. Nginx Reload Failed

**Symptom:** Nginx fails to reload
**Solution:** Check nginx configuration

```bash
ssh arpansahu@arpansahu.space 'sudo nginx -t'
ssh arpansahu@arpansahu.space 'sudo journalctl -u nginx -n 50'
```

#### 3. Kafka Connection Failed

**Symptom:** Kafka doesn't accept SSL connections
**Solution:** Verify keystores were regenerated

```bash
ssh arpansahu@arpansahu.space 'ls -lh ~/kafka-deployment/ssl/'
ssh arpansahu@arpansahu.space 'docker logs kafka-kraft | tail -50'
```

#### 4. K3s Secret Not Updated

**Symptom:** Kubernetes pods use old certificates
**Solution:** Manually update secrets

```bash
ssh arpansahu@arpansahu.space 'cd ~/k3s_scripts && ./1_renew_k3s_ssl_keystores.sh'
```

#### 5. MinIO Upload Failed

**Symptom:** Keystores not available in MinIO
**Solution:** Check MinIO credentials

```bash
ssh arpansahu@arpansahu.space 'mc ls minio/arpansahu-one-bucket/'
ssh arpansahu@arpansahu.space 'cd ~/k3s_scripts && ./2_upload_keystores_to_minio.sh'
```

### Verification Commands

```bash
# Check certificate expiry
openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -dates

# Check nginx is using new cert
echo | openssl s_client -connect arpansahu.space:443 2>/dev/null | openssl x509 -noout -dates

# Check Kafka keystore
keytool -list -v -keystore ~/kafka-deployment/ssl/kafka.keystore.jks -storepass Gandu302@kafkasslpass

# Check K3s secret
kubectl get secret arpansahu-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates

# Check MinIO file timestamps
mc ls minio/arpansahu-one-bucket/keystores/private/kafka/
```

---

## Manual Intervention

### Update Individual Services

If automation fails for a specific service, update manually:

#### Nginx Only
```bash
sudo cp ~/.acme.sh/arpansahu.space_ecc/fullchain.cer /etc/nginx/ssl/arpansahu.space/fullchain.pem
sudo cp ~/.acme.sh/arpansahu.space_ecc/arpansahu.space.key /etc/nginx/ssl/arpansahu.space/privkey.pem
sudo systemctl reload nginx
```

#### Kafka Only
```bash
cd ~/kafka-deployment
./generate_ssl_from_nginx.sh
docker compose -f docker-compose-kafka.yml restart
```

#### K3s Only
```bash
cd ~/k3s_scripts
./1_renew_k3s_ssl_keystores.sh
```

#### MinIO Only
```bash
cd ~/k3s_scripts
./2_upload_keystores_to_minio.sh
```

---

## Security Considerations

### Passwordless Sudo

The automation requires specific sudo commands to run without password. This is configured in `/etc/sudoers.d/k3s-ssl-automation` with **minimal permissions**:

**What's allowed:**
- ✅ kubectl operations (K3s secret management)
- ✅ Copy files from /etc/nginx/ssl/ (read-only source)
- ✅ File permissions (chmod on temp files)
- ✅ Keystore tools (keytool, openssl)

**What's NOT allowed:**
- ❌ Arbitrary commands
- ❌ System modifications
- ❌ User management
- ❌ Package installation (except specific tools)

### MinIO Private Storage

Keystores uploaded to MinIO are stored in **private path** (`keystores/private/kafka/`) requiring authentication:

```bash
# Public access blocked (403 Forbidden)
curl https://minioapi.arpansahu.space/arpansahu-one-bucket/keystores/private/kafka/fullchain.pem
# HTTP 403

# Authenticated access required (boto3 S3 client)
```

### File Permissions

```bash
# Nginx certificates
-rw-r--r--  fullchain.pem  (public, read-only)
-rw-------  privkey.pem    (private key, owner-only)

# Kafka keystores
-rw-r--r--  kafka.keystore.jks
-rw-r--r--  kafka.truststore.jks

# K3s keystores
-rw-r--r--  kafka.keystore.jks
-rw-r--r--  kafka.truststore.jks
```

---

## Monitoring

### Certificate Expiry Alerts

Set up monitoring for certificate expiry:

```bash
# Create monitoring script
cat > ~/check_cert_expiry.sh << 'EOF'
#!/bin/bash
DAYS_LEFT=$(openssl x509 -in /etc/nginx/ssl/arpansahu.space/fullchain.pem -noout -enddate | sed 's/.*=//;s/ GMT//' | xargs -I {} date -d "{}" +%s | awk '{print int(($1 - systime()) / 86400)}')

if [ $DAYS_LEFT -lt 30 ]; then
    echo "⚠️ SSL certificate expires in $DAYS_LEFT days"
    # Add notification logic here (email, webhook, etc.)
else
    echo "✅ SSL certificate valid for $DAYS_LEFT days"
fi
EOF
chmod +x ~/check_cert_expiry.sh

# Add to cron (daily check)
(crontab -l 2>/dev/null; echo "0 9 * * * ~/check_cert_expiry.sh") | crontab -
```

### Automation Logs

View automation execution history:

```bash
# acme.sh logs
~/.acme.sh/acme.sh.log

# Nginx reload logs
sudo journalctl -u nginx -n 100

# Kafka restart logs
docker logs kafka-kraft --tail 100

# K3s events
kubectl get events --sort-by='.lastTimestamp' | grep -i secret
```

---

## Migration Guide

If you have existing services with manual SSL management, migrate to automated system:

### Step 1: Backup Current Certificates

```bash
# Backup nginx
sudo cp -r /etc/nginx/ssl/arpansahu.space /etc/nginx/ssl/arpansahu.space.backup.$(date +%F)

# Backup Kafka
cp -r ~/kafka-deployment/ssl ~/kafka-deployment/ssl.backup.$(date +%F)

# Backup K3s
sudo cp -r /var/lib/rancher/k3s/ssl/keystores /var/lib/rancher/k3s/ssl/keystores.backup.$(date +%F)
```

### Step 2: Install Automation

```bash
# Copy and configure deploy_certs.sh
scp ssl-automation/deploy_certs.sh arpansahu@arpansahu.space:~/
ssh arpansahu@arpansahu.space 'chmod +x ~/deploy_certs.sh'

# Install sudoers configuration
scp ssl-automation/sudoers-k3s-ssl-automation arpansahu@arpansahu.space:/tmp/
ssh arpansahu@arpansahu.space 'sudo visudo -c -f /tmp/sudoers-k3s-ssl-automation && sudo mv /tmp/sudoers-k3s-ssl-automation /etc/sudoers.d/k3s-ssl-automation && sudo chown root:root /etc/sudoers.d/k3s-ssl-automation && sudo chmod 440 /etc/sudoers.d/k3s-ssl-automation'
```

### Step 3: Configure acme.sh Hook

```bash
ssh arpansahu@arpansahu.space
~/.acme.sh/acme.sh --install-cert -d arpansahu.space \
  --ecc \
  --cert-file /tmp/cert.pem \
  --key-file /tmp/key.pem \
  --fullchain-file /tmp/fullchain.pem \
  --reloadcmd "~/deploy_certs.sh"
```

### Step 4: Test Automation

```bash
# Test without renewal
ssh arpansahu@arpansahu.space '~/deploy_certs.sh'

# Verify all services updated
curl -I https://arpansahu.space
openssl s_client -connect kafka-server.arpansahu.space:9092 < /dev/null
kubectl get secret arpansahu-tls
mc ls minio/arpansahu-one-bucket/keystores/private/kafka/
```

### Step 5: Remove Manual Processes

Once automation is verified, remove manual certificate update procedures from documentation and cron jobs.

---

## Related Documentation

- [Nginx SSL Setup](../02-nginx/README.md)
- [Kafka SSL Configuration](../kafka/Kafka.md)
- [K3s SSL Management](../kubernetes_k3s/README.md)
- [MinIO Configuration](../08-minio/README.md)
- [Django Integration](../kubernetes_k3s/DJANGO_INTEGRATION.md)

---

## Support

If automation fails or requires updates:

1. Check logs: `~/deploy_certs.sh 2>&1 | tee ~/ssl-deployment.log`
2. Verify sudoers: `sudo visudo -c -f /etc/sudoers.d/k3s-ssl-automation`
3. Test components individually (see Manual Intervention section)
4. Review service-specific documentation

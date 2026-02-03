# MinIO - S3-Compatible Object Storage

MinIO is a high-performance, S3-compatible object storage solution perfect for storing static files, media uploads, backups, and any blob data.

## 🚀 Quick Start

### Complete Installation (Recommended)

```bash
cd "AWS Deployment/Minio"
./install.sh && ./add-nginx-config.sh
```

This will:
- Load environment variables from `.env`
- Create data directory
- Start MinIO container
- Configure nginx for both Console and API
- Reload nginx

---

## 📋 Prerequisites

- Docker installed
- Nginx installed
- Domain/subdomain configured:
  - `minio.arpansahu.space` → 192.168.1.200 (Console)
  - `minioapi.arpansahu.space` → 192.168.1.200 (API)
- SSL certificates in `/etc/letsencrypt/live/arpansahu.space/`
- `.env` file (see Configuration)

---

## ⚙️ Configuration

### Environment Variables

Create `.env` from `.env.example`:

```bash
cp .env.example .env
```

Contents:

```env
# MinIO Root Credentials
MINIO_ROOT_USER=arpansahu
MINIO_ROOT_PASSWORD=Gandu302@minio

# Port Configuration
MINIO_PORT=9000          # S3 API port (localhost only)
MINIO_CONSOLE_PORT=9002  # Console web UI port (localhost only)

# AWS/Django Access Keys (create these in MinIO console after installation)
AWS_ACCESS_KEY_ID=django_user
AWS_SECRET_ACCESS_KEY=Gandu302@djangominio
AWS_STORAGE_BUCKET_NAME=arpansahu-one-bucket
```

> **Note:** The AWS credentials are for application access. Create these access keys via MinIO Console after installation.

---

## 📦 Installation

### Option 1: Automated Install (Recommended)

```bash
./install.sh
```

This script:
1. Loads variables from `.env`
2. Creates `~/minio/data` directory
3. Removes old container (if exists)
4. Starts new MinIO container
5. Exposes Console on port 9002 and API on port 9000 (localhost only)

### Option 2: Manual Install

```bash
# Load environment variables
source .env

# Create data directory
mkdir -p ~/minio/data

# Run MinIO
docker run -d \
  --name minio \
  --restart unless-stopped \
  -p 127.0.0.1:${MINIO_PORT}:9000 \
  -p 127.0.0.1:${MINIO_CONSOLE_PORT}:9001 \
  -e "MINIO_ROOT_USER=${MINIO_ROOT_USER}" \
  -e "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" \
  -v ~/minio/data:/data \
  quay.io/minio/minio:latest \
  server /data --console-address ":9001"
```

---

## 🌐 Nginx Configuration

### Automated Setup

```bash
./add-nginx-config.sh
```

This configures:
- **Console (Web UI):** minio.arpansahu.space → localhost:9002
- **S3 API:** minioapi.arpansahu.space → localhost:9000

### Key Features

- SSL termination with Let's Encrypt certificates
- `client_max_body_size 500M` for large file uploads
- Proper WebSocket support for Console
- Security headers configured

---

## 🌍 Router Configuration (External Access)

To access MinIO from outside your local network:

### Port Forwarding Setup

1. **Access Router Admin Panel:**
   - URL: http://192.168.1.1 (or https://airtel.arpansahu.space/cgi-bin/login_advance.cgi)
   - Username: `admin`
   - Password: `Gandmara302@`

2. **Configure Port Forwarding:**
   - Navigate to: **Advanced Settings** → **NAT** → **Virtual Server**
   
3. **Add HTTPS Rule (443):**
   | Field | Value |
   |-------|-------|
   | Service Name | MinIO HTTPS |
   | External Port | 443 |
   | Internal Port | 443 |
   | Internal IP | 192.168.1.200 |
   | Protocol | TCP |
   | Status | Enabled |

4. **Save and Apply**

> **Note:** Both `minio.arpansahu.space` and `minioapi.arpansahu.space` use port 443 (HTTPS), so only one port forwarding rule is needed.

---

## 🔐 Access Details

| Component | URL | Port (localhost) |
|-----------|-----|------------------|
| Console (Web UI) | https://minio.arpansahu.space | 9002 |
| S3 API | https://minioapi.arpansahu.space | 9000 |

**Root Credentials:**
- Username: `arpansahu`
- Password: `Gandu302@minio`

---

## 📁 Initial Setup - Create Bucket & Access Keys

### 1. Login to Console

Visit https://minio.arpansahu.space and login with root credentials.

### 2. Create Buckets

For Django applications, you typically need **separate buckets** for different types of content:

#### Option 1: Single Bucket (Simple Setup)
1. Navigate to **Buckets** → **Create Bucket**
2. **Bucket Name:** `arpansahu-one-bucket`
3. **Versioning:** Enable (recommended for backup/recovery)
4. **Access Policy:** Private (default)
5. Click **Create Bucket**

#### Option 2: Multiple Buckets (Recommended for Production)

Create separate buckets for different access patterns:

**A. Static Files Bucket (Public Read)**
- **Name:** `arpansahu-static`
- **Purpose:** CSS, JS, fonts, images
- **Policy:** Public (download-only)
- **Why:** Static files need to be publicly accessible by browsers

**B. Media Files Bucket (Private)**
- **Name:** `arpansahu-media`
- **Purpose:** User uploads, documents, avatars
- **Policy:** Private (access via Django only)
- **Why:** User content should be access-controlled

**C. Backups Bucket (Private)**
- **Name:** `arpansahu-backups`
- **Purpose:** Database backups, snapshots
- **Policy:** Private (admin access only)
- **Why:** Sensitive data, no public access

### 3. Set Bucket Policies

#### Using MinIO Console (GUI)

1. Navigate to **Buckets** → Select bucket → **Access Policy**
2. Choose policy type:

| Policy Type | Description | Use Case |
|-------------|-------------|----------|
| **Private** | No anonymous access | Media uploads, user files, backups |
| **Public** | Full anonymous read/write | ❌ **Never use** - security risk |
| **Download** | Anonymous read-only | ✅ Static files (CSS, JS, images) |
| **Upload** | Anonymous write-only | Rare use case |
| **Custom** | JSON policy rules | Fine-grained control |

#### Using MinIO Client (mc)

```bash
# Private (default) - no anonymous access
mc anonymous set none myminio/arpansahu-media

# Public download-only - for static files
mc anonymous set download myminio/arpansahu-static

# Check current policy
mc anonymous get myminio/arpansahu-static
```

#### Custom JSON Policy (Advanced)

For fine-grained control, create a custom policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::arpansahu-static/*"]
    }
  ]
}
```

Apply via Console: **Buckets** → Select bucket → **Access Policy** → **Add Custom Policy**

#### Path-Based Policy (Single Bucket with Multiple Access Levels)

For **one bucket** with different paths having different access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::arpansahu-one-bucket/static/*"]
    }
  ]
}
```

This policy makes:
- `static/*` → **Public read** (anyone can access)
- `media/*` → **Private** (requires authentication)
- `protected/*` → **Private** (requires authentication + ownership check in Django)
- Everything else → **Private**

**Folder Structure Option 1: Simple**
```
arpansahu-one-bucket/
├── static/              # PUBLIC (anonymous read via bucket policy)
│   ├── css/
│   ├── js/
│   └── images/
├── media/               # PRIVATE (presigned URLs for authenticated users)
│   ├── avatars/
│   └── uploads/
└── protected/           # PROTECTED (presigned URLs + ownership check)
    ├── invoices/
    └── private-docs/
```

**Folder Structure Option 2: Multi-Project with Portfolio Prefix** ⭐ **Recommended**

For hosting multiple Django projects in one bucket:

```
your-bucket-name/
└── portfolio/           # PUBLIC (anonymous read via bucket policy)
    ├── django_starter/
    │   └── static/
    │       ├── css/
    │       ├── js/
    │       └── admin/
    ├── borcelle_crm/
    │   └── static/
    ├── chew_and_cheer/
    │   └── static/
    └── arpansahu_dot_me/
        └── static/
```

**Set public access for portfolio prefix using mc:**

```bash
# Install MinIO client first (if not installed)
# See "Install MinIO Client" section below

# Set up alias (one-time)
mc alias set myminio http://localhost:9000 your_minio_root_user your_minio_root_password

# Set public read access for portfolio/* prefix
mc anonymous set public myminio/your-bucket-name/portfolio/

# Verify the policy
mc anonymous get myminio/your-bucket-name/portfolio/
# Should return: Access permission for `your-bucket-name/portfolio/` is `public`
```

**Why use portfolio/ prefix?**
- ✅ All projects share one bucket (cost-effective)
- ✅ Clear organization and separation
- ✅ Single bucket policy for all static files
- ✅ Easy to add new projects
- ✅ Consistent URL structure: `minioapi.arpansahu.space/your-bucket-name/portfolio/project-name/static/...`

### 4. Create Access Keys for Applications

1. Navigate to **Access Keys** → **Create access key**
2. Fill in details:
   - **Access Key:** `django_user`
   - **Secret Key:** `Gandu302@djangominio`
   - **Policy:** `readwrite` (or custom policy)
3. Click **Create**
4. Save the credentials - they won't be shown again

> **Security Note:** Never use root credentials in applications. Always create separate access keys with minimal required permissions.

---

---

## 🐍 Django Integration

### Install Required Packages

```bash
pip install django-storages boto3
```

### Django Settings

#### Option 1: Single Bucket (Simple)

```python
# settings.py

# MinIO/S3 Configuration
AWS_S3_ENDPOINT_URL = "https://minioapi.arpansahu.space"
AWS_S3_VERIFY = True
AWS_ACCESS_KEY_ID = "django_user"
AWS_SECRET_ACCESS_KEY = "Gandu302@djangominio"
AWS_STORAGE_BUCKET_NAME = "arpansahu-one-bucket"  # Single bucket for everything
AWS_S3_ADDRESSING_STYLE = "path"
AWS_DEFAULT_ACL = None
AWS_S3_OBJECT_PARAMETERS = {
    'CacheControl': 'max-age=86400',
}

# Storage Backends (Django 4.2+)
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
    },
    "staticfiles": {
        "BACKEND": "storages.backends.s3boto3.S3StaticStorage",
    },
}
```

> **Note:** With single bucket, set bucket policy to **Private**. Django will handle access control via presigned URLs.

#### Option 2: Multiple Buckets (Recommended)

```python
# settings.py

# MinIO/S3 Configuration
AWS_S3_ENDPOINT_URL = "https://minioapi.arpansahu.space"
AWS_S3_VERIFY = True
AWS_ACCESS_KEY_ID = "django_user"
AWS_SECRET_ACCESS_KEY = "Gandu302@djangominio"
AWS_S3_ADDRESSING_STYLE = "path"
AWS_DEFAULT_ACL = None

# Static Files Bucket (Public Read)
AWS_STATIC_BUCKET_NAME = "arpansahu-static"
AWS_S3_CUSTOM_DOMAIN = f"{AWS_S3_ENDPOINT_URL.replace('https://', '')}/{AWS_STATIC_BUCKET_NAME}"

# Media Files Bucket (Private)
AWS_MEDIA_BUCKET_NAME = "arpansahu-media"

# Custom Storage Classes
from storages.backends.s3boto3 import S3Boto3Storage

class StaticStorage(S3Boto3Storage):
    bucket_name = AWS_STATIC_BUCKET_NAME
    default_acl = 'public-read'  # Static files are publicly accessible
    querystring_auth = False  # No signed URLs needed

class MediaStorage(S3Boto3Storage):
    bucket_name = AWS_MEDIA_BUCKET_NAME
    default_acl = 'private'  # Media files require authentication
    file_overwrite = False  # Don't overwrite files with same name
    querystring_auth = True  # Use presigned URLs for temporary access
    querystring_expire = 3600  # URLs expire in 1 hour

# Storage Backends
STORAGES = {
    "default": {
        "BACKEND": "path.to.MediaStorage",  # User uploads
    },
    "staticfiles": {
        "BACKEND": "path.to.StaticStorage",  # CSS, JS, images
    },
}
```

**Bucket Policies for Option 2:**
- `arpansahu-static`: Set to **Download** (public read-only)
- `arpansahu-media`: Set to **Private** (Django controls access)

#### Option 3: Single Bucket with Path-Based Access (Recommended for Simplicity)

```python
# settings.py

# MinIO/S3 Configuration
AWS_S3_ENDPOINT_URL = "https://minioapi.arpansahu.space"
AWS_S3_VERIFY = True
AWS_ACCESS_KEY_ID = "django_user"
AWS_SECRET_ACCESS_KEY = "Gandu302@djangominio"
AWS_STORAGE_BUCKET_NAME = "arpansahu-one-bucket"
AWS_S3_ADDRESSING_STYLE = "path"
AWS_DEFAULT_ACL = None

# Custom Storage Classes for Different Paths
from storages.backends.s3boto3 import S3Boto3Storage

class StaticStorage(S3Boto3Storage):
    location = 'static'  # Files stored in /static/ prefix
    default_acl = 'public-read'
    querystring_auth = False  # No signed URLs (public access via bucket policy)

class MediaStorage(S3Boto3Storage):
    location = 'media'  # Files stored in /media/ prefix
    default_acl = 'private'
    file_overwrite = False
    querystring_auth = True  # Presigned URLs for authenticated users
    querystring_expire = 3600  # 1 hour

class ProtectedStorage(S3Boto3Storage):
    location = 'protected'  # Files stored in /protected/ prefix
    default_acl = 'private'
    file_overwrite = False
    querystring_auth = True
    querystring_expire = 300  # 5 minutes (shorter for security)

# Storage Backends
STORAGES = {
    "default": {
        "BACKEND": "path.to.MediaStorage",
    },
    "staticfiles": {
        "BACKEND": "path.to.StaticStorage",
    },
}
```

**Bucket Policy for Option 3:**
Set custom policy (see step 3 above) to make `static/*` public, rest private.

**Django Model Example with Protected Storage:**
```python
class Invoice(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    pdf = models.FileField(
        upload_to='invoices/',
        storage=lambda: storages['protected']  # Protected path
    )

def download_invoice(request, invoice_id):
    invoice = Invoice.objects.get(id=invoice_id)
    if invoice.user != request.user:
        return HttpResponseForbidden()
    
    # Generate presigned URL only for owner
    storage = ProtectedStorage()
    url = storage.url(invoice.pdf.name)
    return redirect(url)
```

### Environment Variables (.env)

```env
# Single Bucket Setup
AWS_S3_ENDPOINT_URL="https://minioapi.arpansahu.space"
AWS_S3_VERIFY=True
AWS_ACCESS_KEY_ID="django_user"
AWS_SECRET_ACCESS_KEY="Gandu302@djangominio"
AWS_STORAGE_BUCKET_NAME="arpansahu-one-bucket"
AWS_S3_ADDRESSING_STYLE="path"

# Multiple Buckets Setup (add these)
AWS_STATIC_BUCKET_NAME="arpansahu-static"
AWS_MEDIA_BUCKET_NAME="arpansahu-media"
```

### Collect Static Files

```bash
python manage.py collectstatic --noinput
```

### Usage in Models

```python
from django.db import models

class Document(models.Model):
    title = models.CharField(max_length=200)
    # Uploads to media bucket (private)
    file = models.FileField(upload_to='documents/')
    created_at = models.DateTimeField(auto_now_add=True)

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    # Uploads to media bucket with presigned URL access
    avatar = models.ImageField(upload_to='avatars/')
```

### Accessing Private Files (Presigned URLs)

```python
from django.core.files.storage import default_storage

# Generate temporary URL for private file
file_url = default_storage.url('documents/private_file.pdf')
# URL is valid for 1 hour (querystring_expire setting)
```

---

## 🐍 Python boto3 Examples

### Basic Operations

```python
import boto3
from botocore.client import Config

# Initialize S3 client
s3 = boto3.client(
    's3',
    endpoint_url='https://minioapi.arpansahu.space',
    aws_access_key_id='django_user',
    aws_secret_access_key='Gandu302@djangominio',
    config=Config(signature_version='s3v4'),
    verify=True
)

# Upload file
s3.upload_file('local-file.txt', 'arpansahu-one-bucket', 'remote-file.txt')

# Upload with metadata
s3.upload_file(
    'image.jpg',
    'arpansahu-one-bucket',
    'images/profile.jpg',
    ExtraArgs={'ContentType': 'image/jpeg', 'ACL': 'public-read'}
)

# Download file
s3.download_file('arpansahu-one-bucket', 'remote-file.txt', 'downloaded.txt')

# List objects
response = s3.list_objects_v2(Bucket='arpansahu-one-bucket', Prefix='documents/')
for obj in response.get('Contents', []):
    print(f"{obj['Key']} - {obj['Size']} bytes")

# Delete object
s3.delete_object(Bucket='arpansahu-one-bucket', Key='remote-file.txt')

# Generate presigned URL (temporary access)
url = s3.generate_presigned_url(
    'get_object',
    Params={'Bucket': 'arpansahu-one-bucket', 'Key': 'private-file.pdf'},
    ExpiresIn=3600  # 1 hour
)
print(f"Temporary URL: {url}")
```

### Upload Directory

```python
import os

def upload_directory(local_dir, bucket, s3_prefix=''):
    for root, dirs, files in os.walk(local_dir):
        for file in files:
            local_path = os.path.join(root, file)
            relative_path = os.path.relpath(local_path, local_dir)
            s3_path = os.path.join(s3_prefix, relative_path).replace('\\', '/')
            
            print(f"Uploading {local_path} to {s3_path}")
            s3.upload_file(local_path, bucket, s3_path)

# Usage
upload_directory('/path/to/local/folder', 'arpansahu-one-bucket', 'backups/')
```

---

---

## 🛠️ MinIO Client (mc)

MinIO Client provides a modern alternative to UNIX commands like ls, cat, cp, mirror, diff.

### Installation

```bash
# Linux/Mac
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Mac (Homebrew)
brew install minio/stable/mc
```

### Configuration

```bash
# Add MinIO server as alias
mc alias set myminio https://minioapi.arpansahu.space django_user Gandu302@djangominio

# Test connection
mc admin info myminio
```

### Common Commands

```bash
# List buckets
mc ls myminio

# List objects in bucket
mc ls myminio/arpansahu-one-bucket

# Copy file to bucket
mc cp local-file.txt myminio/arpansahu-one-bucket/

# Copy entire directory
mc cp --recursive local-folder/ myminio/arpansahu-one-bucket/folder/

# Mirror directory (sync)
mc mirror local-folder/ myminio/arpansahu-one-bucket/folder/

# Download file
mc cp myminio/arpansahu-one-bucket/file.txt ./downloaded.txt

# Remove file
mc rm myminio/arpansahu-one-bucket/file.txt

# Remove directory recursively
mc rm --recursive --force myminio/arpansahu-one-bucket/folder/

# Get file stats
mc stat myminio/arpansahu-one-bucket/file.txt

# Watch for events
mc watch myminio/arpansahu-one-bucket
```

### Bucket Management

```bash
# Create bucket
mc mb myminio/new-bucket

# Remove bucket
mc rb myminio/old-bucket

# Set bucket policy (public read)
mc anonymous set public myminio/arpansahu-one-bucket

# Set bucket policy (download only)
mc anonymous set download myminio/arpansahu-one-bucket

# Get bucket policy
mc anonymous get myminio/arpansahu-one-bucket
```

---

## 🔧 Management & Maintenance

### Docker Commands

```bash
# View logs
docker logs -f minio

# Restart container
docker restart minio

# Stop container
docker stop minio

# Start container
docker start minio

# Remove container
docker rm -f minio
```

### Update MinIO

```bash
# Pull latest image
docker pull quay.io/minio/minio:latest

# Stop and remove old container
docker stop minio && docker rm minio

# Reinstall
cd "AWS Deployment/Minio"
./install.sh
```

### Backup Data

```bash
# Backup all data
tar -czf minio-backup-$(date +%Y%m%d).tar.gz ~/minio/data

# Backup specific bucket (using mc)
mc mirror myminio/arpansahu-one-bucket ~/backups/bucket-backup/

# Restore from backup
mc mirror ~/backups/bucket-backup/ myminio/arpansahu-one-bucket/
```

### Check Disk Usage

```bash
# Server disk space
df -h ~/minio/data

# Bucket sizes (via mc)
mc du myminio/arpansahu-one-bucket
```

---

## 🐛 Troubleshooting

### WebSocket Connection Errors

**Symptoms:** Console shows repeated errors:
```
WebSocket connection to 'wss://minio.arpansahu.space/ws/objectManager' failed
```

**Cause:** Missing WebSocket upgrade headers in nginx configuration.

**Fix:**
```bash
cd "AWS Deployment/Minio"
sudo ./fix-websocket.sh
```

This script adds required headers:
- `proxy_http_version 1.1`
- `proxy_set_header Upgrade $http_upgrade`
- `proxy_set_header Connection "upgrade"`

After running, hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R).

**Manual Verification:**
```bash
grep -A 5 "server_name minio.arpansahu.space" /etc/nginx/sites-enabled/services | grep Upgrade
```

Should show: `proxy_set_header Upgrade $http_upgrade;`

### Can't Access Console

```bash
# Check if container is running
docker ps | grep minio

# Check logs
docker logs minio

# Restart container
docker restart minio

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Check DNS resolution
nslookup minio.arpansahu.space
```

### Upload Fails / File Too Large

```bash
# Check nginx client_max_body_size
sudo grep -r "client_max_body_size" /etc/nginx/

# Should be 500M in MinIO configs
# If not, update and reload:
sudo vi /etc/nginx/sites-enabled/minio-console
sudo vi /etc/nginx/sites-enabled/minio-api
sudo systemctl reload nginx

# Check disk space
df -h ~/minio/data
```

### Connection Refused / Can't Connect to API

```bash
# Verify ports are listening
sudo ss -lntp | grep -E '9000|9002'

# Test local access
curl http://localhost:9002  # Console
curl http://localhost:9000/minio/health/live  # API health

# Check firewall
sudo ufw status

# Test from Mac/external
curl -I https://minio.arpansahu.space
curl -I https://minioapi.arpansahu.space
```

### SSL/Certificate Issues

```bash
# Verify certificates exist
ls -la /etc/letsencrypt/live/arpansahu.space/

# Test SSL
openssl s_client -connect minio.arpansahu.space:443 -servername minio.arpansahu.space

# Check nginx SSL configuration
sudo nginx -T | grep -A 10 "minio.arpansahu.space"
```

### Django Integration Issues

```python
# Test boto3 connection
import boto3
s3 = boto3.client(
    's3',
    endpoint_url='https://minioapi.arpansahu.space',
    aws_access_key_id='django_user',
    aws_secret_access_key='Gandu302@djangominio'
)
print(s3.list_buckets())
```

### Access Denied Errors

1. **Verify access keys are correct** in Django settings
2. **Check bucket policy** in MinIO Console → Buckets → [bucket name] → Access Policy
3. **Verify access key permissions** in MinIO Console → Access Keys → [key] → Policy
4. **Ensure bucket exists:** `mc ls myminio`

---

## 📚 Additional Resources

- **MinIO Documentation:** https://min.io/docs/minio/linux/index.html
- **Django Storages:** https://django-storages.readthedocs.io/en/latest/backends/amazon-S3.html
- **boto3 Documentation:** https://boto3.amazonaws.com/v1/documentation/api/latest/index.html
- **MinIO Client Guide:** https://min.io/docs/minio/linux/reference/minio-mc.html

---

## 🔒 Security Best Practices

### Bucket Policy Guidelines

**✅ DO:**
- Use **Private** policy for user uploads, sensitive data, backups
- Use **Download** (public read) policy ONLY for static assets (CSS, JS, images)
- Create separate buckets for different access levels
- Use presigned URLs for temporary access to private files
- Enable bucket versioning for important data

**❌ DON'T:**
- Never use **Public** (full read/write) policy - major security risk
- Don't store sensitive data in public buckets
- Don't share root credentials with applications
- Don't set static and media files in same bucket with public policy

### Bucket Policy by Use Case

| Content Type | Bucket Policy | Why |
|--------------|---------------|-----|
| **Static Files** (CSS, JS, fonts, images) | Download (public read) | Need to be loaded by browsers without authentication |
| **Media Uploads** (user avatars, documents) | Private | Access controlled by Django, use presigned URLs |
| **Database Backups** | Private | Sensitive data, admin-only access |
| **Public Assets** (blog images, public downloads) | Download (public read) | Intentionally public content |
| **Form Uploads** (before processing) | Private | Temporary storage, should be access-controlled |

### Access Key Permissions

Create access keys with minimal required permissions:

**For Django Application:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::arpansahu-media/*",
        "arn:aws:s3:::arpansahu-static/*",
        "arn:aws:s3:::arpansahu-media",
        "arn:aws:s3:::arpansahu-static"
      ]
    }
  ]
}
```

**For Read-Only Access:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::arpansahu-media/*",
        "arn:aws:s3:::arpansahu-media"
      ]
    }
  ]
}
```

### General Security

1. **Never expose MinIO ports (9000, 9002) directly** - always use nginx reverse proxy
2. **Use separate access keys for each application** - never share root credentials
3. **Enable bucket versioning** for important data
4. **Set minimal required permissions** on access keys
5. **Regularly rotate access keys**
6. **Monitor access logs** via MinIO Console
7. **Use HTTPS only** - never HTTP for production
8. **Keep MinIO updated** to latest stable version
9. **Review bucket policies regularly** - ensure they match current requirements
10. **Use presigned URLs for private content** - temporary access with expiration

---

---

## 🌐 Complete Django Integration with All Services

### Full Production Configuration Example

This example shows a complete Django setup with **MinIO + Redis (TLS) + PostgreSQL + Celery**, all using domain names and secure SSL/TLS connections.

#### Environment Variables (.env)

```env
# Django
DEBUG=False
SECRET_KEY="your-secret-key"
ALLOWED_HOSTS=django-starter.arpansahu.space

# PostgreSQL (TLS stream proxy on port 9552)
DATABASE_URL=postgresql://postgres:your_postgres_password@postgres.arpansahu.space:9552/your_database_name

# Redis (TLS stream proxy on port 9551)
REDIS_CLOUD_URL=rediss://:your_redis_password@redis.arpansahu.space:9551

# MinIO S3 (API endpoint with HTTPS)
AWS_S3_ENDPOINT_URL=https://minioapi.arpansahu.space
AWS_S3_VERIFY=True
AWS_ACCESS_KEY_ID=your_minio_access_key
AWS_SECRET_ACCESS_KEY=your_minio_secret_key
AWS_STORAGE_BUCKET_NAME=your-bucket-name
AWS_S3_ADDRESSING_STYLE=path
```

#### Django Settings (settings.py)

```python
import os
import ssl
from pathlib import Path

# Load environment variables
DEBUG = os.getenv('DEBUG', 'False') == 'True'
SECRET_KEY = os.getenv('SECRET_KEY')
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '').split(',')

# Database Configuration
import dj_database_url
DATABASES = {
    'default': dj_database_url.config(
        default=os.getenv('DATABASE_URL'),
        conn_max_age=600,
        conn_health_checks=True,
    )
}

# Redis Configuration
REDIS_CLOUD_URL = os.getenv('REDIS_CLOUD_URL')

# Cache with Redis SSL
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

# Celery Configuration with Redis SSL
CELERY_BROKER_URL = REDIS_CLOUD_URL
CELERY_RESULT_BACKEND = REDIS_CLOUD_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'

# Celery SSL Configuration (Let's Encrypt certificates are trusted)
CELERY_REDIS_BACKEND_USE_SSL = {
    'ssl_cert_reqs': ssl.CERT_REQUIRED
}
CELERY_BROKER_USE_SSL = {
    'ssl_cert_reqs': ssl.CERT_REQUIRED
}

# MinIO/S3 Configuration for Multi-Project Setup
AWS_S3_ENDPOINT_URL = os.getenv('AWS_S3_ENDPOINT_URL')
AWS_S3_VERIFY = os.getenv('AWS_S3_VERIFY', 'True') == 'True'
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME')
AWS_S3_ADDRESSING_STYLE = 'path'
AWS_DEFAULT_ACL = None

# Custom domain for static files (portfolio prefix for multi-project)
PROJECT_NAME = 'django_starter'  # Change per project
AWS_LOCATION = f'portfolio/{PROJECT_NAME}'  # Project-specific prefix
AWS_S3_CUSTOM_DOMAIN = f'{AWS_S3_ENDPOINT_URL.replace("https://", "")}/{AWS_STORAGE_BUCKET_NAME}'

# Static files configuration
STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/{AWS_LOCATION}/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Storage backends (Django 4.2+)
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
    },
    "staticfiles": {
        "BACKEND": "storages.backends.s3boto3.S3StaticStorage",
    },
}

# Additional S3 settings
AWS_S3_OBJECT_PARAMETERS = {
    'CacheControl': 'max-age=86400',  # Cache for 1 day
}
AWS_QUERYSTRING_AUTH = False  # No signed URLs for static files
```

#### Celery Configuration (celery.py)

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_starter.settings')

app = Celery('django_starter')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
```

#### Requirements

```txt
Django>=4.2
psycopg2-binary
dj-database-url
django-redis
redis
celery
django-storages
boto3
```

#### Deployment Commands

```bash
# Collect static files to MinIO
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate

# Start Django (production)
gunicorn django_starter.wsgi:application --bind 0.0.0.0:8016

# Start Celery worker
celery -A django_starter worker --loglevel=info

# Start Celery beat (if needed)
celery -A django_starter beat --loglevel=info
```

#### Infrastructure Requirements

All these services must be configured on your server:

1. **PostgreSQL** with nginx TLS stream proxy on port 9552
2. **Redis** with nginx TLS stream proxy on port 9551
3. **MinIO API** with nginx HTTPS proxy at minioapi.arpansahu.space
4. **Let's Encrypt SSL certificates** (automatically trusted by Python)

See individual service documentation:
- [PostgreSQL Setup](../03-postgres/README.md)
- [Redis Setup](../05-redis/README.md)
- [MinIO Setup](../08-minio/README.md)

#### Verification

```bash
# Test Redis connection
redis-cli -h redis.arpansahu.space -p 9551 -a your_redis_password --tls ping
# Should return: PONG

# Test MinIO access
curl -I https://minioapi.arpansahu.space/your-bucket-name/portfolio/your_project/static/admin/css/base.css
# Should return: HTTP/2 200

# Test static file serving
curl https://django-starter.arpansahu.space
# CSS/JS should load from minioapi.arpansahu.space
```

#### Expected Celery Logs

```
[2026-02-03 14:42:59,941: INFO/MainProcess] Connected to rediss://:**@redis.arpansahu.space:9551//
[2026-02-03 14:42:59,953: INFO/MainProcess] celery@django_starter ready.
```

#### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 400 Bad Request from boto3 | Using Console URL instead of API | Use `minioapi.arpansahu.space`, not `minio.arpansahu.space` |
| CSS not loading | Files not uploaded to MinIO | Run `collectstatic`, check MinIO bucket |
| Redis SSL connection failed | Certificate verification issue | Use `ssl.CERT_REQUIRED` (Let's Encrypt is trusted) |
| Celery can't connect to Redis | Wrong URL or missing TLS proxy | Use `rediss://` scheme, ensure nginx stream proxy on 9551 |
| collectstatic slow/fails | Network issues or wrong credentials | Check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY |

---

## ✅ Verification

After installation, verify everything works:

```bash
# 1. Check container status
docker ps | grep minio

# 2. Check local access
curl http://localhost:9002
curl http://localhost:9000/minio/health/live

# 3. Check HTTPS access
curl -I https://minio.arpansahu.space
curl -I https://minioapi.arpansahu.space

# 4. Login to console
# Visit: https://minio.arpansahu.space
# Login with: arpansahu / Gandu302@minio

# 5. Test with mc client
mc alias set test https://minioapi.arpansahu.space django_user Gandu302@djangominio
mc ls test
```

All checks should pass ✅

---

## 📁 Files Reference

All deployment files are in: `AWS Deployment/Minio/`

| File | Purpose |
|------|---------|
| `.env.example` | Template for environment variables |
| `.env` | Actual credentials (not in git) |
| `install.sh` | Main installation script |
| `add-nginx-config.sh` | Adds nginx reverse proxy config |
| `fix-websocket.sh` | Fixes WebSocket connection issues |
| `nginx-console.conf` | Standalone Console nginx config |
| `nginx-api.conf` | Standalone API nginx config |
| `README.md` | This documentation |

**On Server:**
- Data: `~/minio/data/`
- Nginx config: `/etc/nginx/sites-available/services` (merged config)
- Logs: `docker logs minio`

---

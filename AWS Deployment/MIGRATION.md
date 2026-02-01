# Documentation Migration Guide

## What Changed

The documentation has been completely restructured for better maintainability and ease of use.

### Old Structure
```
AWS Deployment/
├── Rabbitmq.md (200+ lines with repeated code)
├── Redis.md (300+ lines with repeated code)
├── nginx.md (all configs in one file)
└── ... (scattered files)
```

### New Structure
```
AWS Deployment/
├── README.md (Master index)
│
├── rabbitmq/
│   ├── README.md (Documentation)
│   ├── install.sh (Automated script)
│   └── nginx.conf (Nginx config)
│
├── redis/
│   ├── README.md
│   ├── install.sh
│   └── nginx-stream.conf
│
└── ssh-web-terminal/
    ├── README.md
    ├── install.sh
    └── nginx.conf
```

## Benefits

### 1. **No Code Repetition**
- Installation commands → `install.sh`
- Nginx configs → `nginx.conf` or `nginx-stream.conf`
- Documentation → `README.md` (references the files)

### 2. **One-Command Installation**
```bash
cd rabbitmq
./install.sh
```

### 3. **Easy Nginx Setup**
```bash
sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 4. **Version Control Friendly**
- Each service in its own directory
- Easy to track changes per service
- Can update one service without touching others

### 5. **Consistent Structure**
All services follow the same pattern:
```
service-name/
├── README.md      (Documentation with examples)
├── install.sh     (Complete automation)
├── nginx.conf     (HTTP/HTTPS config)
└── additional     (Service-specific configs)
```

## Migration Steps

### For Existing Installations

Your current installations **keep working**. This is just documentation restructuring.

To use the new structure:

1. **Keep your existing services running**
2. **For new services**, use the new folders:
   ```bash
   cd "AWS Deployment/redis"
   ./install.sh
   ```

3. **To standardize existing configs**, copy nginx files:
   ```bash
   sudo cp rabbitmq/nginx.conf /etc/nginx/sites-available/rabbitmq
   ```

### For Fresh Installations

1. **Start with main README:**
   ```bash
   cat "AWS Deployment/README.md"
   ```

2. **Pick a service and install:**
   ```bash
   cd "AWS Deployment/rabbitmq"
   cat README.md  # Read documentation
   ./install.sh   # Run installation
   ```

3. **Configure Nginx:**
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq
   sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

## What's Available Now

### ✅ Completed Services

| Service | Location | Status |
|---------|----------|--------|
| RabbitMQ | `rabbitmq/` | ✅ Complete |
| Redis | `redis/` | ✅ Complete |
| SSH Web Terminal | `ssh-web-terminal/` | ✅ Complete |

### 🚧 To Be Migrated

The following services still need restructuring:

- [ ] Jenkins
- [ ] Portainer
- [ ] PgAdmin
- [ ] MinIO
- [ ] PostgreSQL
- [ ] Harbor
- [ ] Kafka

**Template for new services:**
```bash
mkdir -p "AWS Deployment/service-name"
cd "AWS Deployment/service-name"

# Create files:
touch README.md install.sh nginx.conf
chmod +x install.sh
```

## Example: Adding a New Service

Let's say you want to add Portainer:

1. **Create directory:**
   ```bash
   mkdir -p "AWS Deployment/portainer"
   cd "AWS Deployment/portainer"
   ```

2. **Create install.sh:**
   ```bash
   #!/bin/bash
   set -e
   echo "Installing Portainer..."
   docker volume create portainer_data
   docker run -d \
     --name portainer \
     --restart unless-stopped \
     -p 127.0.0.1:9443:9443 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v portainer_data:/data \
     portainer/portainer-ce:latest
   ```

3. **Create nginx.conf:**
   ```nginx
   server {
       listen 443 ssl http2;
       server_name portainer.arpansahu.space;
       
       ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
       ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
       
       location / {
           proxy_pass https://127.0.0.1:9443;
           proxy_set_header Host $host;
       }
   }
   ```

4. **Create README.md:**
   ```markdown
   ## Portainer
   
   Docker management UI.
   
   ### Quick Install
   ```bash
   ./install.sh
   sudo cp nginx.conf /etc/nginx/sites-available/portainer
   sudo ln -sf /etc/nginx/sites-available/portainer /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl reload nginx
   ```
   
   ### Installation Script
   ```bash file=install.sh
   ```
   
   ### Nginx Configuration
   ```nginx file=nginx.conf
   ```
   ```

5. **Update main README.md:**
   Add Portainer to the services table.

## Key Improvements

### Before
```markdown
### Installing RabbitMQ
1. Run this command:
   ```bash
   docker run -d --name rabbitmq ...
   ```
2. Configure nginx:
   ```nginx
   server {
       listen 443 ssl;
       ...
   }
   ```
```

### After
```markdown
### Quick Install
```bash
./install.sh
sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq
```

### Installation Script
```bash file=install.sh
```

### Nginx Configuration  
```nginx file=nginx.conf
```
```

**Result:**
- ✅ No code duplication
- ✅ Easy to maintain
- ✅ Easy to copy configs
- ✅ Scripts can be run directly

## File References in Markdown

The new documentation uses file references:

```markdown
### Installation Script
```bash file=install.sh
```

### Nginx Configuration
```nginx file=nginx.conf
```
```

This tells readers:
1. The code is in a separate file
2. They can copy the file directly
3. The documentation shows what's in the file

## Troubleshooting

### Old docs still exist?

Yes, they're untouched. The new structure is **additive**, not replacing.

Old files:
- `AWS Deployment/Rabbitmq.md` (old)
- `AWS Deployment/rabbitmq/README.md` (new)

Both work, but the new structure is recommended for:
- New installations
- Updates to documentation
- Sharing with team

### How to clean up old files?

After confirming the new structure works:

```bash
# Move old files to archive
mkdir -p "AWS Deployment/_archive"
mv "AWS Deployment/Rabbitmq.md" "AWS Deployment/_archive/"
mv "AWS Deployment/Redis.md" "AWS Deployment/_archive/"
```

## Next Steps

1. **Test the new structure:**
   ```bash
   cd "AWS Deployment/rabbitmq"
   cat README.md
   ```

2. **Migrate remaining services:**
   Follow the template above for each service

3. **Update main README.md:**
   Keep the service table updated

4. **Archive old files:**
   Once migration is complete

## Questions?

- **Q: Do I need to reinstall services?**
  A: No, this is documentation only

- **Q: Will old docs break?**
  A: No, they still exist and work

- **Q: Should I use old or new docs?**
  A: New structure is recommended

- **Q: Can I mix old and new?**
  A: Yes, but consistency is better

---

**Created:** February 2026  
**Status:** Initial migration complete (3 services)

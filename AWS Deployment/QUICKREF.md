# Quick Reference Card

## 📁 New Documentation Structure

```
AWS Deployment/
├── README.md           ← Start here
├── MIGRATION.md        ← Understanding changes
├── SUMMARY.md          ← What was done
│
├── rabbitmq/           ✅ Complete
│   ├── README.md
│   ├── install.sh
│   └── nginx.conf
│
├── redis/              ✅ Complete
│   ├── README.md
│   ├── install.sh
│   └── nginx-stream.conf
│
└── ssh-web-terminal/   ✅ Complete
    ├── README.md
    ├── install.sh
    └── nginx.conf
```

## 🚀 Quick Install Commands

### RabbitMQ
```bash
cd "AWS Deployment/rabbitmq"
./install.sh
sudo cp nginx.conf /etc/nginx/sites-available/rabbitmq
sudo ln -sf /etc/nginx/sites-available/rabbitmq /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### Redis
```bash
cd "AWS Deployment/redis"
./install.sh
# Add stream config from nginx-stream.conf to /etc/nginx/nginx.conf
sudo nginx -t && sudo systemctl reload nginx
```

### SSH Web Terminal
```bash
cd "AWS Deployment/ssh-web-terminal"
./install.sh
sudo cp nginx.conf /etc/nginx/sites-available/ssh-terminal
sudo ln -sf /etc/nginx/sites-available/ssh-terminal /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## 🔗 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| RabbitMQ | https://rabbitmq.arpansahu.space | admin / Gandu302@rabbitmq |
| Redis Commander | https://redis.arpansahu.space | arpansahu / Gandu302@rediscommander |
| SSH Terminal | https://ssh.arpansahu.space | arpansahu / Gandu302@ |
| Jenkins | https://jenkins.arpansahu.space | arpansahu / Gandu302@jenkins |
| Portainer | https://portainer.arpansahu.space | arpansahu / Gandu302@portainer |
| PgAdmin | https://pgadmin.arpansahu.space | admin@arpansahu.me / Gandu302@pgadmin |
| MinIO | https://minio.arpansahu.space | arpansahu / Gandu302@minio |
| Harbor | https://harbor.arpansahu.space | admin / Gandu302@harbor |
| Kafka/AKHQ | https://kafka.arpansahu.space/ui | arpansahu / Gandu302@kafkaui |

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Master index with all services |
| `MIGRATION.md` | Explains the restructuring |
| `SUMMARY.md` | What was done and why |
| `QUICKREF.md` | This cheat sheet |
| `creds.txt` | All credentials (updated) |

## 🔧 Common Commands

### Docker
```bash
# List containers
docker ps

# View logs
docker logs -f <container-name>

# Restart container
docker restart <container-name>

# Stop and remove
docker stop <container-name> && docker rm <container-name>
```

### Nginx
```bash
# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx

# View errors
sudo tail -f /var/log/nginx/error.log

# List sites
ls -la /etc/nginx/sites-enabled/
```

### Service Management
```bash
# Check container status
docker ps | grep <service>

# Check port binding
sudo ss -lntp | grep <port>

# Test local access
curl http://localhost:<port>

# Test HTTPS access
curl https://<subdomain>.arpansahu.space
```

## 🐛 Troubleshooting

### Container won't start
```bash
docker logs <container-name>
docker rm <container-name>
cd service-folder
./install.sh
```

### Can't access via HTTPS
```bash
# Check container
docker ps | grep <service>

# Check nginx
sudo nginx -t
sudo systemctl status nginx

# Check for conflicts
sudo nginx -T | grep "server_name <subdomain>"
```

### Port already in use
```bash
# Find what's using the port
sudo ss -lntp | grep :<port>

# Kill the process
sudo kill <PID>

# Or stop the container
docker stop <container-name>
```

## 📝 Adding New Services

```bash
# 1. Create folder
mkdir "AWS Deployment/new-service"
cd "AWS Deployment/new-service"

# 2. Create files
touch README.md install.sh nginx.conf
chmod +x install.sh

# 3. Use template from existing services
cat ../rabbitmq/install.sh  # Copy structure
cat ../rabbitmq/nginx.conf  # Copy nginx pattern

# 4. Update main README
# Add to service table in AWS Deployment/README.md
```

## 🔑 Key Benefits

✅ **No Code Duplication** - Scripts and configs in separate files  
✅ **One-Command Install** - Just run `./install.sh`  
✅ **Easy Updates** - Change one file, affects one service  
✅ **Version Control** - Clean diffs, easy reviews  
✅ **Consistent** - All services follow same pattern  

## 📖 Learning Path

1. **Start here:** `AWS Deployment/README.md`
2. **Pick a service:** Navigate to folder
3. **Read documentation:** Service `README.md`
4. **Run installer:** `./install.sh`
5. **Configure nginx:** Copy config file
6. **Test:** Access via HTTPS

## 🆘 Need Help?

1. Check service-specific `README.md`
2. Review `MIGRATION.md` for context
3. See `SUMMARY.md` for what's new
4. Check troubleshooting sections
5. View nginx/docker logs

---

**Quick Links:**
- [Main Documentation](./README.md)
- [Migration Guide](./MIGRATION.md)
- [Complete Summary](./SUMMARY.md)
- [Credentials](../creds.txt)

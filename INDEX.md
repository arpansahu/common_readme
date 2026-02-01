# Complete Server Documentation Index

This directory contains comprehensive documentation for the complete restoration and management of the arpansahu.space production server.

---

## 📋 Main Documentation Files

### 1. [SERVER_STATE_DOCUMENTATION.md](SERVER_STATE_DOCUMENTATION.md) (22KB)
**Complete server state snapshot**
- All running services with exact versions
- Full configuration details
- Installation order and dependencies
- Network configuration
- Critical files backup list
- Post-installation verification steps

**Use this for:** Understanding the EXACT current state of the server.

---

### 2. [FRESH_INSTALLATION_GUIDE.md](FRESH_INSTALLATION_GUIDE.md) (10KB)
**Step-by-step fresh installation guide**
- Phase-by-phase installation (7 phases)
- Commands for each service
- Verification steps at each phase
- Troubleshooting common issues
- Post-installation tasks
- Estimated time: 2.5 hours

**Use this for:** Installing everything fresh with no data restoration.

---

### 3. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (9KB)
**Quick command reference**
- All service URLs and credentials
- Start/stop commands for each service
- Database connection strings
- Monitoring commands
- Common maintenance tasks
- Quick troubleshooting

**Use this for:** Daily operations and quick lookups.

---

### 4. [creds.txt](creds.txt) (4KB)
**All credentials and passwords**
- Server SSH access
- Service usernames/passwords
- Docker commands with passwords
- Connection strings
- Environment variables

**Use this for:** Looking up credentials during setup or operations.

⚠️ **SECURITY:** Keep this file secure, never commit to public repos.

---

## 📂 Service-Specific Documentation

Located in `AWS Deployment/` directory:

### Core Infrastructure
- [Docker Installation](AWS%20Deployment/Docker%20Readme/docker_installation.md)
- [Nginx Setup](AWS%20Deployment/nginx.md)
- [Nginx HTTPS with SSL](AWS%20Deployment/nginx_https.md)
- [Introduction](AWS%20Deployment/Intro.md)

### Databases
- [PostgreSQL](AWS%20Deployment/Postgres.md)
- [Redis](AWS%20Deployment/Redis.md)
- [Redis Commander UI](AWS%20Deployment/RedisCommander.md)

### DevOps Tools
- [Jenkins CI/CD](AWS%20Deployment/Jenkins/Jenkins.md)
- [Kubernetes with Portainer](AWS%20Deployment/kubernetes_with_portainer/deployment.md)
- [Portainer](AWS%20Deployment/Portainer.md)
- [Harbor Private Registry](AWS%20Deployment/harbor/harbor.md)

### Application Services
- [RabbitMQ](AWS%20Deployment/Rabbitmq.md)
- [Kafka with KRaft](AWS%20Deployment/kafka/Kafka.md)
- [AKHQ (Kafka UI)](AWS%20Deployment/kafka/AKHQ.md)
- [MinIO Object Storage](AWS%20Deployment/Minio.md)
- [PgAdmin](AWS%20Deployment/Pgadmin.md)

### Additional Services
- [SSH Key Setup for Ubuntu Installation](AWS%20Deployment/ssh_key_setup.md) ← **Do this FIRST!**
- [Guacamole SSH Web UI](AWS%20Deployment/ssh_guacamole.md)
- [Home Server Setup](AWS%20Deployment/home_server_setup.md)
- [Router Admin via Nginx](AWS%20Deployment/router_admin_nginx.md)

---

## 🎯 Quick Navigation by Use Case

### "I'm about to format the server"
1. Save [creds.txt](creds.txt) securely (that's all you need!)
2. Format and install fresh Ubuntu 22.04 LTS

### "I just installed fresh Ubuntu"
1. Follow: [FRESH_INSTALLATION_GUIDE.md](FRESH_INSTALLATION_GUIDE.md) from Phase 1
2. Use [creds.txt](creds.txt) for all passwords
3. Refer to service-specific docs in `AWS Deployment/` as needed
4. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for commands
5. After installation, run Django migrations and create superuser

### "Service X is down, how do I fix it?"
1. Check: [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Section: Quick Troubleshooting
2. Check logs: `docker logs <container>` or `journalctl -u <service>`
3. Refer to service-specific doc in `AWS Deployment/`

### "What's the password for X?"
1. Check: [creds.txt](creds.txt)
2. Or check: [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Web Access URLs table

### "How do I start/stop X?"
1. Check: [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Service Start/Stop Commands

### "How do I connect to database/Kafka/Redis?"
1. Check: [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Database Connection Strings

---

## 🔄 Server Architecture Summary

### Services Distribution

**systemd services (5):**
- Nginx (web server + reverse proxy)
- PostgreSQL 16 (database)
- Jenkins (CI/CD)
- K3s (Kubernetes)
- MinIO (object storage)

**Docker containers (10):**
- redis-external (Redis cache)
- rabbitmq (message broker)
- kafka-kraft (event streaming)
- akhq (Kafka UI)
- harbor-log (+ 8 other Harbor containers)
- portainer (container management)
- portainer_agent (K3s agent)
- guacamole (+ guacd, guacamole-db)

**PM2 process (1):**
- redis-commander (Redis UI)

**Standalone (1):**
- PgAdmin (Python virtualenv)

**K3s deployments (5):**
- arpansahu-dot-me-app (main Django app)
- coredns
- local-path-provisioner
- metrics-server
- portainer-agent

### Network Ports

| Port | Service | Access |
|------|---------|--------|
| 22 | SSH | Public |
| 80 | HTTP (→443) | Public |
| 443 | HTTPS (Nginx) | Public |
| 5432 | PostgreSQL | LAN only |
| 9550 | PostgreSQL TLS | Public (Nginx stream) |
| 6380 | Redis | Localhost |
| 9551 | Redis TLS | Public (Nginx stream) |
| 9092 | Kafka SASL_SSL | Public |
| 9000 | MinIO API | Public |
| 9002 | MinIO Console | Public |
| 8080 | Jenkins | Localhost (Nginx proxy) |
| 15672 | RabbitMQ UI | Localhost (Nginx proxy) |
| 8086 | AKHQ | Localhost (Nginx proxy) |
| 8602 | Harbor | Localhost (Nginx proxy) |
| 9998 | Portainer | Localhost (Nginx proxy) |
| 5050 | PgAdmin | Localhost (Nginx proxy) |
| 8085 | Guacamole | Localhost (Nginx proxy) |
| 9996 | Redis Commander | Localhost (Nginx proxy) |
| 32000 | K3s NodePort | LAN (Nginx proxy) |

---

## ⏱️ Installation Timeline

```
Phase 1: Base System (30 min)
  ├── Ubuntu 22.04 LTS
  ├── Essential tools
  ├── UFW firewall
  ├── Docker
  └── Docker DNS/MTU fix

Phase 2: Nginx + SSL (20 min)
  ├── Nginx
  ├── acme.sh + wildcard SSL
  ├── Nginx configs (arpansahu, services)
  └── Nginx stream (PostgreSQL/Redis TLS)

Phase 3: Databases (15 min)
  ├── PostgreSQL 16
  ├── Redis (Docker)
  └── Redis Commander (PM2)

Phase 4: DevOps Tools (30 min)
  ├── Jenkins
  ├── K3s (--disable=traefik)
  ├── Portainer
  └── Harbor

Phase 5: Application Services (20 min)
  ├── RabbitMQ (Docker)
  ├── Kafka + AKHQ (Docker)
  ├── MinIO (systemd)
  ├── PgAdmin (standalone)
  └── Guacamole (Docker)

Phase 6: Deploy Applications (15 min)
  ├── Build Docker image (Jenkins)
  ├── Push to Harbor
  ├── Deploy to K3s
  └── Configure router proxy

Phase 7: Verification (10 min)
  ├── Service health checks
  ├── SSL verification
  ├── Database connectivity
  └── Web access test

Total: ~2 hours 20 minutes
```

---

## 🎓 Learning Path

### For Beginners
1. Read [Introduction](AWS%20Deployment/Intro.md) first
2. Understand [Docker Installation](AWS%20Deployment/Docker%20Readme/docker_installation.md)
3. Learn [Nginx basics](AWS%20Deployment/nginx.md)
4. Follow [RESTORATION_CHECKLIST.md](RESTORATION_CHECKLIST.md) step by step

### For Experienced Users
1. Skim [SERVER_STATE_DOCUMENTATION.md](SERVER_STATE_DOCUMENTATION.md) for architecture
2. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for commands
3. Refer to specific service docs only when needed

---

## 🔐 Security Notes

1. **creds.txt** - Never commit to public repo, backup securely
2. **SSL certificates** - Backup `~/.acme.sh/` with API tokens
3. **Passwords** - All use strong passwords (see creds.txt)
4. **Firewall** - UFW enabled with minimal open ports
5. **Services** - Most behind Nginx reverse proxy (not directly exposed)
6. **TLS** - PostgreSQL and Redis use TLS via Nginx stream
7. **SASL_SSL** - Kafka uses SASL/PLAIN over TLS

---

## 🆘 Emergency Contacts

**AI Assistant:** Available for restoration assistance with:
- Access to all documentation
- Knowledge of current server state
- Can guide through restoration process
- Provide when needed: passwords from creds.txt, backup files

**Required from you:**
- Fresh Ubuntu 22.04 server ready
- Server IP and SSH access
- Backup files (if restoring data)
- creds.txt for passwords

---

## 📝 Maintenance Schedule

### Daily
- Monitor service health
- Check disk space
- Review error logs

### Weekly
- Check for security updates
- Verify backups
- Review SSL certificate expiry

### Monthly
- Update Docker images
- PostgreSQL vacuum
- Clean old logs

### Every 60 Days
- SSL certificate auto-renewal (acme.sh cron)

---

## 📞 Quick Help

**Issue:** Service won't start  
**Solution:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) → Troubleshooting → Service Down

**Issue:** Can't access website  
**Solution:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) → Troubleshooting → Cannot Access Website

**Issue:** SSL error  
**Solution:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) → SSL Certificate Management

**Issue:** Database connection failed  
**Solution:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) → Database Connection Strings

**Need to restore server:**  
**Solutioninstall fresh server:**  
**Solution:** [FRESH_INSTALLATION_GUIDE.md](FRESH_INSTALLATION_GUIDE
---

## 🎉 System Status

**Current Server:** arpansahu.space (122.176.93.72)  
**OS:** Ubuntu 22.04 LTS  
**Last Documented:** 31 January 2026  
**Total Services:** 22 services  
**Uptime Target:** 99.9%  
**Estimated Restoration Time:** 2 hours  

---

**All documentation is complete and ready for server restoration! 🚀**

# Home Server Infrastructure Documentation

Complete documentation for arpansahu.space production infrastructure running on Ubuntu 22.04 LTS home server.

## 🏠 Server Overview

**Production URL:** https://arpansahu.space  
**Server OS:** Ubuntu 22.04 LTS  
**Architecture:** Docker + Kubernetes (k3s) + Nginx  
**SSL/TLS:** Let's Encrypt wildcard certificate via acme.sh  
**Total Services:** 17 services (8 core + 5 management + 4 additional)

---

## 📋 Complete Service Inventory

### 🔧 Core Backend Services

| Service | Purpose | Access | Port(s) |
|---------|---------|--------|---------|
| **PostgreSQL** | Primary database | `postgres.arpansahu.space:9552` | 5432 (internal), 9552 (TLS) |
| **Redis** | Cache & message broker | `redis.arpansahu.space:9551` | 6380 (internal), 9551 (TLS) |
| **MinIO** | S3-compatible object storage | Console: `minio.arpansahu.space`<br>API: `minioapi.arpansahu.space` | 9001→9002 (console)<br>9000 (API) |
| **RabbitMQ** | Message queue broker | `rabbitmq.arpansahu.space` | 5672, 15672 |
| **Kafka** | Event streaming platform | `kafka.arpansahu.space` | 9092 |

### 🎛️ Management & UI Dashboards

| Service | Purpose | Access | Port |
|---------|---------|--------|------|
| **PgAdmin** | PostgreSQL management UI | `pgadmin.arpansahu.space` | 5050 |
| **Redis Commander** | Redis management UI | `redis.arpansahu.space` | 8081 |
| **Portainer** | Docker/Kubernetes management | `portainer.arpansahu.space` | 9443 |
| **AKHQ** | Kafka management UI | `kafka.arpansahu.space/ui` | 8080 |
| **SSH Web Terminal** | Browser-based SSH access | `ssh.arpansahu.space` | 8084 |

### 🚀 CI/CD & DevOps

| Service | Purpose | Access | Port |
|---------|---------|--------|------|
| **Jenkins** | CI/CD automation | `jenkins.arpansahu.space` | 8080 |
| **Harbor** | Docker container registry | `harbor.arpansahu.space` | 8888 |

### 📊 Monitoring & Logging

| Service | Purpose | Access |
|---------|---------|--------|
| **Prometheus** | Metrics collection | Internal |
| **Grafana** | Metrics visualization | Monitoring dashboard |
| **node-exporter** | System metrics | Internal |
| **Sentry** | Error tracking | `arpansahu.sentry.io` |

### 🌐 Infrastructure Services

| Service | Purpose | Access |
|---------|---------|--------|
| **Nginx** | Reverse proxy & load balancer | All HTTPS traffic |
| **Kubernetes (k3s)** | Container orchestration | Via Portainer |
| **acme.sh** | SSL certificate automation | Background service |
| **Airtel Router Admin** | Router management | `airtel.arpansahu.space` |

---

## 📚 Documentation Structure

```
common_readme/
├── INFRASTRUCTURE.md          ← This file (overview of all services)
├── INDEX.md                   ← Complete documentation index
├── README.md                  ← About the readme updater tool
│
├── AWS Deployment/            ← Individual service documentation
│   ├── README.md              ← Service deployment guide
│   ├── INSTALLATION_ORDER.md ← Step-by-step installation sequence
│   ├── QUICKREF.md            ← Quick reference for all services
│   │
│   ├── 01-docker/             ← Docker setup
│   ├── 02-nginx/              ← Nginx proxy with SSL
│   ├── 03-postgres/           ← PostgreSQL with TLS stream
│   ├── 04-redis/              ← Redis with TLS stream
│   ├── 05-portainer/          ← Portainer UI
│   ├── 06-pgadmin/            ← PgAdmin UI
│   ├── 07-redis_commander/    ← Redis Commander UI
│   ├── 08-minio/              ← MinIO object storage
│   ├── 09-rabbitmq/           ← RabbitMQ message broker
│   ├── 10-kafka/              ← Kafka event streaming
│   ├── 11-harbor/             ← Harbor registry
│   ├── 12-jenkins/            ← Jenkins CI/CD
│   │
│   ├── kubernetes_k3s/        ← Kubernetes setup
│   ├── ssh-web-terminal/      ← SSH terminal setup
│   ├── airtel/                ← Router admin setup
│   └── home_server/           ← Complete home server setup guide
│
├── Introduction/              ← Conceptual documentation
│   ├── aws_desployment_introduction.md
│   ├── static_files_settings.md
│   ├── sentry.md
│   ├── channels.md
│   └── cache.md
│
└── post_server_setup/         ← Post-installation scripts
    ├── jenkins_pipeline_creator/
    └── jenkins_project_env/
```

---

## 🚀 Quick Start

### For Complete Server Setup
See [AWS Deployment/home_server/README.md](AWS%20Deployment/home_server/README.md)

### For Individual Service Installation
1. Navigate to service directory: `cd "AWS Deployment/XX-service-name"`
2. Run install script: `./install.sh`
3. Configure nginx: Follow README.md in that directory

### For Installing Everything in Order
See [AWS Deployment/INSTALLATION_ORDER.md](AWS%20Deployment/INSTALLATION_ORDER.md)

---

## 🔗 Key Documentation Links

- **[Installation Order](AWS%20Deployment/INSTALLATION_ORDER.md)** - Sequence to install all services
- **[Home Server Setup](AWS%20Deployment/home_server/README.md)** - Complete hardware to software guide
- **[Quick Reference](AWS%20Deployment/QUICKREF.md)** - All service URLs and credentials
- **[Service Deployment Guide](AWS%20Deployment/README.md)** - Deploy individual services
- **[Docker Setup](AWS%20Deployment/01-docker/docker_installation.md)** - Docker installation and configuration
- **[Nginx Setup](AWS%20Deployment/02-nginx/README.md)** - Nginx with SSL/TLS
- **[PostgreSQL Setup](AWS%20Deployment/03-postgres/README.md)** - Database with TLS
- **[Redis Setup](AWS%20Deployment/04-redis/README.md)** - Cache with TLS
- **[MinIO Setup](AWS%20Deployment/08-minio/README.md)** - Object storage
- **[Jenkins Setup](AWS%20Deployment/12-jenkins/README.md)** - CI/CD pipeline
- **[Harbor Setup](AWS%20Deployment/11-harbor/README.md)** - Docker registry
- **[Kubernetes Setup](AWS%20Deployment/kubernetes_k3s/README.md)** - Container orchestration

---

## 🏗️ Architecture

```
Internet
    ↓
[Cloudflare DNS] → *.arpansahu.space
    ↓
[Airtel Router] → Port forwarding 80, 443
    ↓
[Ubuntu Home Server 192.168.1.200]
    ↓
[Nginx] → Reverse proxy with Let's Encrypt SSL
    ├── HTTP server blocks → Django apps
    ├── Stream proxies → PostgreSQL (9552), Redis (9551)
    └── WebSocket support
    ↓
[Docker Containers / Kubernetes Pods]
    ├── Application containers (Django apps)
    ├── Database containers (PostgreSQL, Redis)
    ├── Storage containers (MinIO)
    ├── Queue containers (RabbitMQ, Kafka)
    ├── Management UIs (PgAdmin, Portainer, etc.)
    └── CI/CD services (Jenkins, Harbor)
```

---

## 🔐 Security Features

- ✅ **Wildcard SSL** - Let's Encrypt certificate for *.arpansahu.space
- ✅ **TLS Stream Proxies** - PostgreSQL and Redis with encrypted connections
- ✅ **Docker Network Isolation** - Services in separate networks
- ✅ **Nginx Rate Limiting** - DDoS protection
- ✅ **Authentication** - All management UIs password-protected
- ✅ **Firewall Rules** - UFW configured for necessary ports only
- ✅ **SSL Certificate Auto-renewal** - acme.sh with acme-dns

---

## 📊 System Requirements

### Minimum for All Services
- **CPU:** 4+ cores
- **RAM:** 16GB+
- **Storage:** 500GB+ SSD
- **Network:** Stable broadband with static IP or DDNS

### Current Production Setup
- **CPU:** Intel/AMD multi-core processor
- **RAM:** 32GB
- **Storage:** 1TB NVMe SSD
- **Network:** Airtel Fiber 200Mbps with DDNS

---

## 🔧 Common Operations

### Check Service Status
```bash
# Docker containers
docker ps

# Kubernetes pods
sudo kubectl get pods -A

# Nginx status
sudo systemctl status nginx

# Check logs
docker logs -f <container-name>
sudo kubectl logs -f <pod-name>
```

### Restart Services
```bash
# Restart container
docker restart <container-name>

# Restart pod
sudo kubectl delete pod <pod-name>  # Auto-recreates

# Reload nginx
sudo nginx -t && sudo systemctl reload nginx
```

### Database Operations
```bash
# Connect to PostgreSQL
psql -h postgres.arpansahu.space -p 9552 -U postgres

# Connect to Redis
redis-cli -h redis.arpansahu.space -p 9551 --tls -a <password>

# MinIO client
mc alias set myminio https://minioapi.arpansahu.space <access-key> <secret-key>
```

---

## 📝 Maintenance Tasks

### Weekly
- Check disk space: `df -h`
- Review logs for errors
- Check service health in Portainer
- Verify backups are running

### Monthly
- Update system packages: `sudo apt update && sudo apt upgrade`
- Update Docker images
- Review SSL certificate expiry
- Check Prometheus metrics

### Quarterly
- Full system backup
- Security audit
- Performance review
- Update documentation

---

## 🆘 Troubleshooting

### Service Won't Start
1. Check container logs: `docker logs <container>`
2. Verify port availability: `sudo netstat -tulpn | grep <port>`
3. Check docker network: `docker network ls`
4. Review service README in `AWS Deployment/`

### SSL Certificate Issues
1. Check certificate: `openssl s_client -connect arpansahu.space:443`
2. Renew manually: `sudo acme.sh --renew --force -d "*.arpansahu.space"`
3. Reload nginx: `sudo systemctl reload nginx`

### Database Connection Issues
1. Check TLS stream proxy: `sudo nginx -T | grep stream`
2. Test connection: `telnet postgres.arpansahu.space 9552`
3. Check PostgreSQL logs: `docker logs postgres`

---

## 📞 Support & Resources

- **GitHub Repository:** https://github.com/arpansahu/common_readme
- **Live Projects:** https://arpansahu.space/projects
- **Main Portfolio:** https://arpansahu.me (separate AWS EC2 instance)

---

## 📄 License

[MIT](https://choosealicense.com/licenses/mit/)

---

**Last Updated:** February 2026  
**Maintained By:** Arpan Sahu  
**Production Status:** ✅ Active

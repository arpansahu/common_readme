# AWS Deployment Documentation - Recommended Installation Order

This guide provides the **recommended sequence** for installing all services on your home server. Services are organized by dependencies and prerequisites.

---

## 📋 Installation Phases

### Phase 1: Foundation (Required First)

**1. Docker & Docker Compose**
- **Guide:** [01-docker/docker_installation.md](01-docker/docker_installation.md)
- **Why First:** Almost all services run in Docker containers
- **Time:** 10 minutes
- **Verification:**
  ```bash
  docker --version
  docker compose version
  ```

**2. Nginx with SSL**
- **Guide:** [02-nginx/README.md](02-nginx/README.md)
- **Why Second:** Provides HTTPS for all web services
- **Prerequisites:** Domain name, DNS configured
- **Time:** 20 minutes

---

### Phase 2: Core Management Tools

**3. Portainer** (Docker UI)
- **Guide:** [05-portainer/README.md](05-portainer/README.md)
- **Prerequisites:** Docker installed
- **Why:** Makes Docker management visual and easier
- **Time:** 10 minutes
- **Access:** https://portainer.arpansahu.space

**4. PgAdmin** (PostgreSQL UI)
- **Guide:** [06-pgadmin/README.md](06-pgadmin/README.md)
- **Prerequisites:** Docker installed, PostgreSQL server running
- **Time:** 10 minutes
- **Access:** https://pgadmin.arpansahu.space

---

### Phase 3: Data Storage Services

**5. PostgreSQL**
- **Guide:** [03-postgres/README.md](03-postgres/README.md)
- **Prerequisites:** Docker installed
- **Why:** Primary database for Django applications
- **Time:** 15 minutes
- **Port:** 5432

**6. Redis**
- **Guide:** [04-redis/README.md](04-redis/README.md)
- **Prerequisites:** Docker installed
- **Why:** Caching and session storage
- **Time:** 10 minutes
- **Port:** 6380 (external), 6379 (internal)

**7. Redis Commander** (Redis UI)
- **Guide:** [07-redis_commander/README.md](07-redis_commander/README.md)
- **Prerequisites:** Redis running, Node.js OR Docker
- **Time:** 10 minutes
- **Access:** https://redis.arpansahu.space

---

### Phase 4: Object Storage & Registry

**8. MinIO** (S3-compatible storage)
- **Guide:** [08-minio/README.md](08-minio/README.md)
- **Prerequisites:** Docker installed
- **Why:** Store Django media files, backups
- **Time:** 15 minutes
- **Access:** https://minio.arpansahu.space (console)
- **API:** https://minioapi.arpansahu.space

**9. Harbor** (Docker Registry)
- **Guide:** [11-harbor/harbor.md](11-harbor/harbor.md)
- **Prerequisites:** Docker, Docker Compose
- **Why:** Private Docker image registry
- **Time:** 20 minutes
- **Access:** https://harbor.arpansahu.space

---

### Phase 5: Message Queue & Streaming

**10. RabbitMQ**
- **Guide:** [09-rabbitmq/README.md](09-rabbitmq/README.md)
- **Prerequisites:** Docker installed
- **Why:** Message broker for Celery tasks
- **Time:** 10 minutes
- **Access:** https://rabbitmq.arpansahu.space

**11. Kafka + AKHQ**
- **Guide:** [10-kafka/README.md](10-kafka/README.md)
- **Prerequisites:** Docker, Nginx SSL certificates
- **Why:** Event streaming platform
- **Time:** 20 minutes
- **Access:** https://kafka.arpansahu.space

---

### Phase 6: Kubernetes (Optional)

**12. K3s + Portainer Agent**
- **Guide:** [kubernetes/README.md](kubernetes/README.md)
- **Prerequisites:** Existing Portainer installation
- **Why:** Container orchestration for scalability
- **Time:** 30 minutes
- **Note:** Only if you need container orchestration

---

### Phase 7: Network Utilities

**13. Airtel Router Admin** (via nginx proxy)
- **Guide:** [airtel/README.md](airtel/README.md)
- **Prerequisites:** Nginx with SSL
- **Why:** Easy HTTPS access to router admin panel
- **Time:** 10 minutes
- **Access:** https://airtel.arpansahu.space

---

## 🔄 Service Dependencies Tree

```
Docker
├── Portainer
├── PostgreSQL
│   └── PgAdmin
├── Redis
│   └── Redis Commander
├── MinIO
├── Harbor
├── RabbitMQ
├── Kafka
│   └── AKHQ
└── K3s
    └── Portainer Agent (connects to main Portainer)

Nginx (SSL)
├── All HTTPS services
└── Router Admin Proxy
```

---

## ⏱️ Total Installation Time

- **Minimal Setup** (Docker + PostgreSQL + Redis + MinIO): ~1 hour
- **Standard Setup** (Add Portainer, PgAdmin, Redis Commander): ~1.5 hours  
- **Complete Setup** (All services): ~3 hours

---

## 🎯 Recommended Starting Point

### For Development
1. Docker
2. PostgreSQL
3. Redis
4. MinIO
5. Portainer (for management)

### For Production
1. Docker
2. Nginx SSL
3. Portainer
4. PostgreSQL + PgAdmin
5. Redis + Redis Commander
6. MinIO
7. Harbor
8. RabbitMQ
9. Kafka (if needed for event streaming)

---

## 📝 Notes

- **Always install Docker first** - it's a prerequisite for almost everything
- **Nginx SSL should be second** - provides HTTPS for all web UIs
- **Install management tools early** (Portainer, PgAdmin) - makes debugging easier
- **Data services before applications** - databases must exist before apps connect
- **Kubernetes is optional** - only needed for container orchestration at scale

---

## 🔍 Quick Reference

| Service | Guide | Port/Access | Dependencies |
|---------|-------|-------------|--------------|
| Docker | [docker/](docker/) | - | None |
| Nginx | Existing setup | 80, 443 | None |
| Portainer | [portainer/](portainer/) | https://portainer.arpansahu.space | Docker |
| PostgreSQL | [postgres/](postgres/) | 5432 | Docker |
| PgAdmin | [pgadmin/](pgadmin/) | https://pgadmin.arpansahu.space | Docker, PostgreSQL |
| Redis | [redis/](redis/) | 6380 | Docker |
| Redis Commander | [redis_commander/](redis_commander/) | https://redis.arpansahu.space | Redis, Node.js/Docker |
| MinIO | [minio/](minio/) | https://minio.arpansahu.space | Docker |
| Harbor | [harbor/](harbor/) | https://harbor.arpansahu.space | Docker, Docker Compose |
| RabbitMQ | [rabbitmq/](rabbitmq/) | https://rabbitmq.arpansahu.space | Docker |
| Kafka | [kafka/](kafka/) | https://kafka.arpansahu.space | Docker, Nginx SSL |
| K3s | [kubernetes/](kubernetes/) | - | Portainer |
| Airtel Router | [airtel/](airtel/) | https://airtel.arpansahu.space | Nginx SSL |

---

## 🆘 Need Help?

- **Can't find a guide?** Check the [INDEX.md](../INDEX.md) for all documentation
- **Installation failed?** Each service README has a detailed troubleshooting section
- **Want quick commands?** See [QUICK_REFERENCE.md](../QUICK_REFERENCE.md)

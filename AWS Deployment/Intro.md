## Deployment Architecture Evolution

This project and all related services have evolved through multiple deployment strategies, each with unique advantages. This documentation covers all three approaches to provide flexibility based on your needs.

### Deployment Timeline

**Phase 1: Heroku (Legacy)**
- Initial hosting on Heroku
- Simple deployment but expensive at scale
- Limited control over infrastructure

**Phase 2: EC2 + Home Server Hybrid (2022-2023)**
- EC2 for portfolio (arpansahu.me) with Nginx
- Home Server for all other projects
- Nginx on EC2 forwarded traffic to Home Server
- Cost-effective but faced reliability challenges

**Phase 3: Single EC2 Server (Aug 2023)**
- Consolidated all projects to single EC2 instance
- Started with t2.medium (~$40/month)
- Optimized to t2.small (~$15/month)
- Better reliability, higher costs

**Phase 4: Hostinger VPS (Jan 2024)**
- Migrated to Hostinger VPS for cost optimization
- Better pricing than EC2
- Good balance of cost and reliability

**Phase 5: Home Server (Current - 2026)**
- Back to Home Server with improved setup
- Leveraging lessons learned from previous attempts
- Modern infrastructure with Kubernetes, proper monitoring
- Significant cost savings with better reliability measures

### Three Deployment Options

This documentation supports all three deployment strategies:

#### 1. AWS EC2

**Advantages:**
- High reliability (99.99% uptime SLA)
- Global infrastructure and CDN integration
- Scalable on demand
- Professional-grade monitoring and support
- No dependency on home internet/power

**Disadvantages:**
- Higher cost (~$15-40/month depending on instance)
- Ongoing monthly expenses
- Limited by instance size without additional cost

**Best For:**
- Production applications requiring maximum uptime
- Applications needing global reach
- When budget allows for convenience
- Business-critical services

#### 2. Hostinger VPS

**Advantages:**
- Cost-effective (~$8-12/month)
- Good performance for price
- Managed infrastructure options
- Reliable uptime
- Easy scaling

**Disadvantages:**
- Still recurring monthly cost
- Less control than EC2
- Limited to Hostinger's infrastructure

**Best For:**
- Budget-conscious deployments
- Personal projects requiring good uptime
- When you want managed services at lower cost
- Small to medium applications

#### 3. Home Server

**Advantages:**
- **Zero recurring costs** (only electricity)
- Full hardware control and unlimited resources
- Privacy and data sovereignty
- Learning opportunity for infrastructure management
- Can repurpose old laptops/desktops
- Ideal for development and testing

**Disadvantages (and Mitigations):**
- **ISP downtime** → Use UPS + mobile hotspot backup
- **Power cuts** → UPS with sufficient backup time
- **Weather issues** → Redundant internet connection
- **Hardware failure** → Regular backups, spare parts
- **Remote troubleshooting** → Proper monitoring, remote access tools
- **Dynamic IP** → Dynamic DNS services (afraid.org, No-IP)

**Best For:**
- Personal projects and portfolios
- Development and testing environments
- Learning DevOps and system administration
- When you have reliable power and internet
- Cost-sensitive deployments

### Current Architecture (Home Server)

```
Internet
   │
   ├─ arpansahu.space (Home Server with Dynamic DNS)
   │   │
   │   └─ Nginx (Port 443) - TLS Termination
   │        │
   │        ├─ Jenkins (CI/CD)
   │        ├─ Portainer (Docker Management)
   │        ├─ PgAdmin (Database Admin)
   │        ├─ RabbitMQ (Message Queue)
   │        ├─ Redis Commander (Cache Admin)
   │        ├─ MinIO (Object Storage)
   │        │
   │        └─ Kubernetes (k3s)
   │             ├─ Django Applications
   │             ├─ PostgreSQL Databases
   │             └─ Redis Instances
```

### Home Server Improvements (2026)

Lessons learned from 2022-2023 experience have been addressed:

**Reliability Enhancements:**
1. UPS with 2-4 hour backup capacity
2. Redundant internet (primary broadband + 4G backup)
3. Hardware RAID for data redundancy
4. Automated monitoring and alerting
5. Remote management tools (SSH, VPN)
6. Automated backup to cloud storage

**Monitoring Stack:**
- Uptime monitoring (UptimeRobot, Healthchecks.io)
- System monitoring (Prometheus + Grafana)
- Log aggregation (Loki)
- Alert notifications (Email, Telegram)

**Infrastructure:**
- Kubernetes (k3s) for orchestration
- Docker for containerization
- PM2 for process management
- Nginx for reverse proxy and HTTPS
- Automated deployments via Jenkins

### Comparison Matrix

| Feature | EC2 | Hostinger VPS | Home Server |
| ------- | --- | ------------- | ----------- |
| Monthly Cost | $15-40 | $8-12 | ~$5 (electricity) |
| Uptime SLA | 99.99% | 99.9% | 95-98% (with improvements) |
| Setup Time | Medium | Easy | Complex |
| Scalability | Excellent | Good | Limited by hardware |
| Control | High | Medium | Full |
| Learning Value | Medium | Low | Very High |
| Remote Access | Built-in | Built-in | Requires setup |
| Backup | Easy | Easy | Manual setup needed |
| Privacy | Low | Medium | Complete |

### Recommended Setup by Use Case

**For Production/Business:**
- Use EC2 or Hostinger VPS
- Follow all documentation except home server specific sections
- Implement proper backup and disaster recovery

**For Personal Projects:**
- Home Server is ideal
- Follow complete documentation including home server setup
- Implement monitoring and backup strategies

**For Learning:**
- Home Server provides maximum learning opportunity
- Experiment with all services and configurations
- Break things and fix them safely

### Infrastructure Components

All deployment options use the same software stack:

**Core Services:**
- Docker Engine with docker-compose-plugin
- Nginx with wildcard SSL (acme.sh)
- Kubernetes (k3s) without Traefik
- Portainer for container management

**Application Services:**
- PostgreSQL 16 with SCRAM-SHA-256
- Redis for caching
- RabbitMQ for message queuing
- Kafka with KRaft mode for event streaming
- MinIO for object storage
- PgAdmin for database administration
- AKHQ for Kafka management

**DevOps Tools:**
- Jenkins for CI/CD
- Git for version control
- PM2 for process management

**Monitoring (Home Server):**
- System metrics and health checks
- Automated alerting
- Log aggregation

### Documentation Structure

This repository provides step-by-step guides for:

0. [SSH Key Setup (Do This First!)](home_server/steps/00-ssh-key-setup.md) ← **IMPORTANT**
1. [Installation Order & Dependencies](INSTALLATION_ORDER.md) ← **Start Here**
2. [Docker Installation](01-docker/docker_installation.md)
3. [Nginx Setup (HTTP + HTTPS)](02-nginx/README.md)
4. [Kubernetes with Portainer](kubernetes_k3s/deployment.md)
5. [PostgreSQL Setup](03-postgres/README.md)
6. [Redis Setup](04-redis/README.md)
7. [Redis Commander](07-redis_commander/README.md)
8. [RabbitMQ](09-rabbitmq/README.md)
9. [Kafka with KRaft](10-kafka/Kafka.md)
10. [AKHQ (Kafka UI)](10-kafka/AKHQ.md)
11. [Portainer](05-portainer/README.md)
12. [PgAdmin](06-pgadmin/README.md)
13. [MinIO Object Storage](08-minio/README.md)
14. [Jenkins CI/CD](12-jenkins/Jenkins.md)
15. [Harbor Private Registry](11-harbor/harbor.md)
16. [Home Server Setup](home_server/README.md) ← Complete laptop-to-server guide
17. [SSH Web Terminal](ssh-web-terminal/README.md) ← Browser-based SSH access
18. [Airtel Router Admin](airtel/README.md) ← Secure router management

### Getting Started

**For EC2/VPS Deployment:**
1. Provision Ubuntu 22.04 server
2. Follow [Installation Order Guide](INSTALLATION_ORDER.md)
3. Install Docker and Docker Compose
4. Set up Nginx with HTTPS
5. Install required services in sequence

**For Home Server Deployment:**
1. Follow [Home Server Setup Guide](home_server/README.md)
2. Install Ubuntu Server 22.04
3. Configure UPS and backup internet
4. Follow [Installation Order Guide](INSTALLATION_ORDER.md)
5. Set up monitoring and alerting

All projects are dockerized and run on predefined ports specified in Dockerfile and docker-compose.yml.

### Architecture Diagrams

**Historical Setup (2022-2023):**
![EC2 and Home Server Hybrid](https://github.com/arpansahu/common_readme/blob/main/Images/ec2_and_home_server.png)

**Single Server Setup (2023-2024):**
![Single Server Configuration](https://github.com/arpansahu/common_readme/blob/main/Images/One%20Server%20Configuration%20for%20arpanahuone.png)

**Current Home Server Setup (2026):**
- Updated architecture with Kubernetes
- Improved reliability and monitoring
- All services behind Nginx with HTTPS
- Dynamic DNS for domain management

### My Current Setup

As of January 2026, I'm running a home server setup with:
- Repurposed laptop as primary server
- Ubuntu 22.04 LTS Server
- 16GB RAM, 500GB SSD
- UPS backup power
- Dual internet connections (broadband + 4G)
- All services accessible via arpansahu.space
- Automated backups to cloud storage

Live projects: https://arpansahu.me/projects

### Next Steps

Choose your deployment strategy and follow the relevant guides:
- **EC2/VPS**: Skip home server setup, start with Docker installation
- **Home Server**: Start with [Home Server Setup Guide](home_server_setup.md)

All guides are production-tested and follow the same format for consistency.
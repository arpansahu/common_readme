## Home Server Setup

This guide provides step-by-step instructions for converting a laptop or desktop into a production-ready home server for hosting applications, databases, and services. This is the actual setup used for arpansahu.space running all projects reliably from a home environment.

### Prerequisites

Before starting, ensure you have:

1. Laptop or desktop with minimum specifications
2. Reliable internet connection
3. Basic networking knowledge
4. Access to router for port forwarding
5. Domain name (optional but recommended)
6. UPS for power backup (highly recommended)

### Minimum Hardware Requirements

**Basic Setup:**
- CPU: Intel i3/i5 or AMD Ryzen 3/5 (4 cores minimum)
- RAM: 8GB (16GB recommended)
- Storage: 256GB SSD (500GB recommended)
- Network: Ethernet port (1Gbps)
- Age: Any laptop/desktop from 2015 onwards

**Recommended Setup:**
- CPU: Intel i5/i7 or AMD Ryzen 5/7 (6+ cores)
- RAM: 16GB or more
- Storage: 500GB NVMe SSD + 1TB HDD for backups
- Network: Gigabit Ethernet
- UPS: 1000VA with 2-4 hour backup

**Tested Setup (My Configuration):**
- Laptop: HP Pavilion 15 (2018 model)
- CPU: Intel i5-8250U (4 cores, 8 threads)
- RAM: 16GB DDR4
- Storage: 512GB NVMe SSD
- Additional: 1TB USB 3.0 HDD for backups
- UPS: APC 1100VA (3-4 hour backup)
- Internet: 100Mbps fiber + 4G hotspot backup

### Architecture Overview

```
Internet (Dynamic IP)
   │
   └─ Dynamic DNS (afraid.org / No-IP)
        │
        └─ Home Router
             │
             ├─ Port Forwarding (80, 443, 22)
             │
             └─ Home Server (Static Local IP)
                  │
                  └─ Ubuntu Server 22.04
                       │
                       ├─ Nginx (TLS Termination)
                       ├─ Kubernetes (k3s)
                       ├─ Docker Services
                       ├─ PostgreSQL
                       ├─ Redis
                       ├─ RabbitMQ
                       └─ MinIO
```

---

## Setup Steps

Follow these steps in order to set up your home server:

### Step 0: SSH Key Setup (Do This First!)

[SSH Key Setup Guide](steps/00-ssh-key-setup.md)

Set up SSH keys for secure, password-less authentication. This is critical for:
- Secure remote access
- CI/CD deployments
- Git operations
- Service-to-service authentication

**What's covered:**
- Generating ED25519 SSH keys
- Adding keys to GitHub/GitLab
- Configuring SSH agent
- Key management best practices

---

### Step 1: Hardware Preparation

[Hardware Preparation Guide](steps/01-hardware-preparation.md)

Convert your laptop/desktop into a stable server. This step covers:
- Disabling sleep and suspend modes
- Configuring lid and power button behavior
- Fixing ACPI and black screen issues
- WiFi power saving configuration
- SSH keep-alive settings
- Emergency kernel reboot setup

**Critical for:** Preventing SSH disconnections, system hangs, and black screens.

---

### Step 2: Ubuntu Server Installation

[Ubuntu Installation Guide](steps/02-ubuntu-installation.md)

Install Ubuntu Server 22.04 LTS on your hardware:
- Download and create bootable USB
- Boot from USB and install Ubuntu Server
- Initial configuration during installation
- First boot and login

**Time required:** 30-60 minutes

---

### Step 3: Initial Server Configuration

[Initial Configuration Guide](steps/03-initial-configuration.md)

Configure basic server settings after installation:
- Update system packages
- Configure firewall (UFW)
- Set up user accounts and sudo
- Install essential tools
- Configure timezone and locale

**Time required:** 15-30 minutes

---

### Step 4: Network Configuration

[Network Configuration Guide](steps/04-network-configuration.md)

Set up networking for your home server:
- Assign static local IP address
- Configure router port forwarding
- Set up Dynamic DNS (DDNS)
- Domain configuration
- Test external accessibility

**Time required:** 30-45 minutes

---

### Step 5: UPS Configuration

[UPS Configuration Guide](steps/05-ups-configuration.md)

Set up UPS for power backup and automatic shutdown:
- Install NUT (Network UPS Tools)
- Configure UPS monitoring
- Set up automatic shutdown
- Test UPS failover

**Time required:** 20-30 minutes

---

### Step 6: Backup Internet Connection

[Backup Internet Guide](steps/06-backup-internet.md)

Set up backup internet connection for high availability:
- Configure 4G/5G hotspot as backup
- Set up automatic failover
- Test backup connection switching
- Monitor connection status

**Time required:** 15-30 minutes

---

### Step 7: Monitoring Setup

[Monitoring Setup Guide](steps/07-monitoring-setup.md)

Set up system monitoring and alerting:
- Install monitoring tools
- Configure health checks
- Set up email/SMS alerts
- Dashboard setup

**Time required:** 30-45 minutes

---

### Step 8: Automated Backups

[Backup Configuration Guide](steps/08-automated-backups.md)

Set up automated backup system:
- Configure backup scripts
- Set up external storage backups
- Schedule automated backups
- Test backup restoration

**Time required:** 30-45 minutes

---

### Step 9: Remote Access Setup

[Remote Access Guide](steps/09-remote-access.md)

Set up additional remote access methods:
- SSH Web Terminal configuration
- Browser-based access
- Mobile access setup
- VPN configuration (optional)

**Time required:** 20-30 minutes

---

### Step 10: Install Core Services

[Core Services Installation](steps/10-core-services.md)

Install and configure essential services:
- Docker and Docker Compose
- Nginx with HTTPS
- PostgreSQL database
- Redis cache
- Message queues
- Object storage

**Time required:** 2-3 hours

---

## Next Steps

After completing the home server setup, proceed with service installation:

1. **Install Docker and Docker Compose**
   - Follow: [../01-docker/docker_installation.md](../01-docker/docker_installation.md)

2. **Install Core Services**
   - Follow: [../INSTALLATION_ORDER.md](../INSTALLATION_ORDER.md)

3. **Set up Management UIs**
   - Portainer: [../05-portainer/README.md](../05-portainer/README.md)
   - PgAdmin: [../06-pgadmin/README.md](../06-pgadmin/README.md)
   - Redis Commander: [../07-redis_commander/README.md](../07-redis_commander/README.md)

4. **Configure Storage & Registry**
   - MinIO: [../08-minio/README.md](../08-minio/README.md)
   - Harbor: [../11-harbor/harbor.md](../11-harbor/harbor.md)

5. **Set up Message Queue & Streaming**
   - RabbitMQ: [../09-rabbitmq/README.md](../09-rabbitmq/README.md)
   - Kafka: [../10-kafka/Kafka.md](../10-kafka/Kafka.md)

6. **Additional Services**
   - Airtel Router Access: [../airtel/README.md](../airtel/README.md)
   - SSH Web Terminal: [../ssh-web-terminal/README.md](../ssh-web-terminal/README.md)

---

## Quick Reference

**Total Time Estimate:** 6-8 hours (spread across 1-2 days recommended)

**Critical Steps (Don't Skip):**
1. SSH Key Setup (Step 0)
2. Hardware Preparation (Step 1) - Laptop users
3. Network Configuration (Step 4)
4. Core Services Installation (Step 10)

**Optional But Recommended:**
- UPS Configuration (Step 5)
- Backup Internet (Step 6)
- Monitoring (Step 7)
- Automated Backups (Step 8)

**Support:**
- Issues: Check individual step files for troubleshooting
- Questions: Each step has detailed explanations
- Updates: Keep system packages updated regularly

---

## Architecture After Setup

Once complete, your home server will have:

```
┌─────────────────────────────────────────────────────────────┐
│                     Home Server (Ubuntu 22.04)              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │    Nginx     │  │  Portainer   │  │   Jenkins    │    │
│  │  (Port 443)  │  │   (Docker)   │  │   (CI/CD)    │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  PostgreSQL  │  │    Redis     │  │   RabbitMQ   │    │
│  │  (Port 5432) │  │ (Port 6379)  │  │ (Port 5672)  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │    MinIO     │  │    Harbor    │  │     Kafka    │    │
│  │  (S3 Storage)│  │  (Registry)  │  │  (Streaming) │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │         Kubernetes (k3s) - Optional                  │ │
│  │         Container orchestration for production       │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

All services accessible via HTTPS with automated SSL certificate renewal.

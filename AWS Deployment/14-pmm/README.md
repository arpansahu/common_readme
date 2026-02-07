# PMM (Percona Monitoring and Management) Setup

Complete guide for monitoring PostgreSQL with PMM.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Monitoring Features](#monitoring-features)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

## Overview

PMM (Percona Monitoring and Management) is an open-source database monitoring solution that provides:
- Real-time performance monitoring
- Query analytics  
- Database health metrics
- Historical data trending
- Alerting capabilities

### What Gets Monitored

**PostgreSQL Metrics:**
- Connection statistics
- Query performance (with pg_stat_monitor)
- Table and index statistics
- Replication lag (if applicable)
- Database size and growth
- Locks and deadlocks
- Checkpoint performance

**System Metrics:**
- CPU usage
- Memory usage
- Disk I/O
- Network traffic

## Architecture

```
┌─────────────────┐
│   Web Browser   │
│  (You)          │
└────────┬────────┘
         │ HTTPS
         ↓
┌─────────────────┐
│  Nginx Proxy    │
│  Port 443       │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  PMM Server     │
│  (Docker)       │
│  Port 8443      │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  PMM Client     │
│  (pmm-agent)    │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  PostgreSQL     │
│  Port 5432/9552 │
└─────────────────┘
```

## Prerequisites

- Ubuntu Server 22.04+
- Docker installed
- Nginx installed
- PostgreSQL server running
- SSL certificates (from nginx setup)
- At least 2GB free RAM
- At least 10GB free disk space

## Quick Start

### Step 1: Prepare Environment

```bash
cd "AWS Deployment/14-pmm"

# Copy and edit environment file
cp .env.example .env
nano .env
```

**Update .env with your values:**
```bash
PMM_ADMIN_PASSWORD=Gandu302@pmm
POSTGRES_HOST=192.168.1.200
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Gandu302postgres
POSTGRES_DB=arpansahu_one_db
```

### Step 2: Run Installation

```bash
sudo ./install.sh
```

The script will:
1. ✅ Install PMM Server (Docker container)
2. ✅ Install PMM Client
3. ✅ Configure PostgreSQL monitoring
4. ✅ Setup nginx reverse proxy
5. ✅ Configure SSL

### Step 3: Access PMM

Open your browser:
```
https://pmm.arpansahu.space/
```

**Login:**
- Username: `admin`
- Password: (from .env: `PMM_ADMIN_PASSWORD`)

## Configuration

### PostgreSQL Configuration

For better monitoring, update PostgreSQL configuration:

```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
```

**Add/update these settings:**
```conf
# Query statistics
shared_preload_libraries = 'pg_stat_statements,pg_stat_monitor'
pg_stat_statements.track = all
pg_stat_statements.max = 10000

# Logging for slow queries
log_min_duration_statement = 1000  # Log queries > 1 second
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
```

**Restart PostgreSQL:**
```bash
sudo systemctl restart postgresql
```

### PMM Server Configuration

Access PMM web interface and configure:

1. **Settings → Settings:**
   - Data retention: 30 days (or as needed)
   - Metrics resolution: Medium (10s)
   - Enable advisors

2. **Alerting:**
   - Configure AlertManager
   - Set up notification channels (email, Slack, etc.)

3. **Users:**
   - Create additional users if needed
   - Configure roles and permissions

## Monitoring Features

### Key Dashboards

1. **PostgreSQL Overview:**
   - Database connections
   - Transactions per second
   - Query execution time
   - Cache hit ratio

2. **PostgreSQL Instance Summary:**
   - Connections by state
   - Checkpoint performance
   - WAL generation rate
   - Lock wait time

3. **Query Analytics:**
   - Slowest queries
   - Most executed queries
   - Query performance trends
   - Execution plan analysis

4. **System Overview:**
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network statistics

### Setting Up Alerts

**Example: High connection count alert**

```yaml
# Go to Alerting → Alert Rules → Create

Name: High PostgreSQL Connections
Expression: 
  pg_stat_database_numbackends{datname="arpansahu_one_db"} > 80
For: 5m
Severity: warning
Annotations:
  summary: "High number of PostgreSQL connections"
  description: "Database {{ $labels.datname }} has {{ $value }} connections"
```

## Troubleshooting

### PMM Server Not Starting

```bash
# Check Docker logs
docker logs pmm-server

# Check if port is in use
sudo netstat -tulpn | grep 8443

# Restart container
docker restart pmm-server
```

### PMM Client Not Connecting

```bash
# Check PMM agent status
sudo systemctl status pmm-agent

# View agent logs
sudo journalctl -u pmm-agent -f

# Reconfigure client
sudo pmm-admin config \
  --server-insecure-tls \
  --server-url=https://admin:PASSWORD@127.0.0.1:8443
```

### PostgreSQL Not Monitored

```bash
# List monitored services
sudo pmm-admin list

# Check connection
sudo pmm-admin status

# Remove and re-add PostgreSQL
sudo pmm-admin remove postgresql postgresql-main
sudo pmm-admin add postgresql \
  --username=postgres \
  --password="Gandu302postgres" \
  --host=192.168.1.200 \
  --port=5432 \
  postgresql-main
```

### No Metrics Showing

```bash
# Verify PostgreSQL permissions
sudo -u postgres psql -d arpansahu_one_db

# Check if extensions are loaded
SELECT * FROM pg_extension WHERE extname IN ('pg_stat_statements', 'pg_stat_monitor');

# Restart PMM agent
sudo systemctl restart pmm-agent
```

### High Memory Usage

```bash
# Check PMM Server memory
docker stats pmm-server

# Adjust data retention (in PMM web UI)
Settings → Settings → Data Retention → 7 days

# Restart with memory limit
docker update --memory="2g" --memory-swap="2g" pmm-server
docker restart pmm-server
```

## Maintenance

### Backup PMM Data

```bash
# Stop PMM Server
docker stop pmm-server

# Backup data directory
tar -czf pmm-backup-$(date +%Y%m%d).tar.gz ~/pmm-data/

# Start PMM Server
docker start pmm-server
```

### Update PMM

```bash
# Backup first (see above)

# Pull latest image
docker pull percona/pmm-server:2

# Stop and remove old container
docker stop pmm-server
docker rm pmm-server

# Create new container with same data
docker run -d \
  --name pmm-server \
  --restart always \
  -p 8443:443 \
  -v ~/pmm-data:/srv \
  -e DISABLE_TELEMETRY=1 \
  percona/pmm-server:2

# Update PMM Client
wget https://downloads.percona.com/downloads/pmm2/LATEST/binary/debian/bookworm/x86_64/pmm2-client_LATEST.bookworm_amd64.deb
sudo dpkg -i pmm2-client_LATEST.bookworm_amd64.deb
```

### Clean Old Data

```bash
# Access PMM Server container
docker exec -it pmm-server bash

# Run cleanup (inside container)
supervisorctl stop victoriametrics
rm -rf /srv/victoriametrics/data/*
supervisorctl start victoriametrics
exit
```

### Monitor PMM Itself

```bash
# Check disk space
df -h ~/pmm-data

# Check container stats
docker stats pmm-server

# View logs
docker logs pmm-server --tail 100 -f
```

## Useful Commands

```bash
# PMM Client Commands
sudo pmm-admin list                    # List all monitored services
sudo pmm-admin status                  # Check PMM agent status
sudo pmm-admin summary                 # Generate diagnostic summary

# Docker Commands
docker ps | grep pmm                   # Check if PMM Server is running
docker logs pmm-server                 # View PMM Server logs
docker exec -it pmm-server bash        # Access PMM Server shell

# Service Management
sudo systemctl status pmm-agent        # Check PMM agent service
sudo systemctl restart pmm-agent       # Restart PMM agent
sudo journalctl -u pmm-agent -f        # View agent logs in real-time
```

## Integration with Django

PMM doesn't interfere with Django applications. Your connection strings remain the same:

```python
# Django settings.py - No changes needed
DATABASE_URL="postgresql://postgres:Gandu302postgres@arpansahu.space:9552/arpansahu_one_db?sslmode=require"
```

PMM monitors at the PostgreSQL server level, not the application level.

## Performance Impact

PMM has minimal impact:
- **CPU:** < 5% overhead
- **Memory:** ~100MB for pmm-agent
- **Network:** Metrics collected every 10-60 seconds
- **Disk:** ~1GB per month for metrics storage

## Security Notes

- ✅ PMM UI requires authentication
- ✅ Uses HTTPS with SSL certificates
- ✅ PostgreSQL credentials stored securely in PMM
- ✅ Metrics data stored locally (no external calls)
- ✅ Optional: Configure firewall to restrict access

## Next Steps

1. ✅ Access https://pmm.arpansahu.space/
2. ✅ Explore PostgreSQL dashboards
3. ✅ Set up alerts for critical metrics
4. ✅ Review Query Analytics regularly
5. ✅ Configure backup schedule
6. ✅ Add more databases/servers as needed

## Support

- Official Docs: https://docs.percona.com/percona-monitoring-and-management/
- Community Forum: https://forums.percona.com/
- GitHub Issues: https://github.com/percona/pmm

---

**Installation completed successfully! Your PostgreSQL is now being monitored.** 🎉

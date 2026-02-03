#!/bin/bash

# Pre-Migration Backup Script
# Run this on the current system BEFORE migrating to SSD

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/tmp/migration_backup_$(date +%Y%m%d_%H%M%S)"
EXTERNAL_MOUNT="/media/backup"  # Change this to your external drive mount point

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Pre-Migration Backup Script          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Create backup directory
echo -e "${YELLOW}Creating backup directory: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# System Information
echo -e "${GREEN}[1/15] Collecting system information...${NC}"
cat > system_info.txt << EOF
Backup Date: $(date)
Hostname: $(hostname)
Kernel: $(uname -r)
Ubuntu Version: $(lsb_release -d | cut -f2)
Architecture: $(uname -m)
EOF

lsblk > disk_layout.txt
df -h > disk_usage.txt
mount > mounted_filesystems.txt
cat /proc/cpuinfo > cpu_info.txt
free -h > memory_info.txt

# Nginx Configuration
echo -e "${GREEN}[2/15] Backing up Nginx configuration...${NC}"
if [ -d /etc/nginx ]; then
    tar czf nginx_configs.tar.gz /etc/nginx/ 2>/dev/null || true
    echo "✓ Nginx configs backed up"
fi

# SSL Certificates
echo -e "${GREEN}[3/15] Backing up SSL certificates...${NC}"
if [ -d /etc/nginx/ssl ]; then
    tar czf ssl_certs.tar.gz /etc/nginx/ssl/ 2>/dev/null || true
    echo "✓ SSL certs backed up"
fi

# Docker Configuration
echo -e "${GREEN}[4/15] Backing up Docker configuration...${NC}"
if [ -d /etc/docker ]; then
    tar czf docker_configs.tar.gz /etc/docker/ 2>/dev/null || true
fi

# Docker Compose Files
echo -e "${GREEN}[5/15] Finding and backing up Docker Compose files...${NC}"
find / -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null > compose_files.txt
mkdir -p docker_compose_files
while IFS= read -r file; do
    if [ -f "$file" ]; then
        cp "$file" "docker_compose_files/$(basename $(dirname "$file"))_compose.yml" 2>/dev/null || true
    fi
done < compose_files.txt
echo "✓ Found $(wc -l < compose_files.txt) compose files"

# Docker Container List
echo -e "${GREEN}[6/15] Exporting Docker container information...${NC}"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > docker_containers.txt 2>/dev/null || true
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" > docker_images.txt 2>/dev/null || true
docker volume ls > docker_volumes.txt 2>/dev/null || true
docker network ls > docker_networks.txt 2>/dev/null || true

# Home Directory
echo -e "${GREEN}[7/15] Backing up home directory...${NC}"
if [ -d /home/arpansahu ]; then
    tar czf home_backup.tar.gz /home/arpansahu/ 2>/dev/null || true
    echo "✓ Home directory backed up"
fi

# /opt Directory
echo -e "${GREEN}[8/15] Backing up /opt directory...${NC}"
if [ -d /opt ]; then
    tar czf opt_backup.tar.gz /opt/ 2>/dev/null || true
    echo "✓ /opt directory backed up"
fi

# SSH Configuration
echo -e "${GREEN}[9/15] Backing up SSH configuration...${NC}"
if [ -d /etc/ssh ]; then
    tar czf ssh_server_config.tar.gz /etc/ssh/ 2>/dev/null || true
fi
if [ -d /home/arpansahu/.ssh ]; then
    tar czf ssh_user_keys.tar.gz /home/arpansahu/.ssh/ 2>/dev/null || true
    echo "✓ SSH configs backed up"
fi

# Package Lists
echo -e "${GREEN}[10/15] Exporting installed packages...${NC}"
dpkg --get-selections > installed_packages.txt
apt-mark showmanual > manual_packages.txt
snap list > snap_packages.txt 2>/dev/null || true
echo "✓ Package lists exported"

# Database Backups
echo -e "${GREEN}[11/15] Backing up databases...${NC}"
if command -v pg_dumpall &> /dev/null; then
    sudo -u postgres pg_dumpall > postgres_all.sql 2>/dev/null || echo "Warning: PostgreSQL backup failed"
    echo "✓ PostgreSQL backed up"
fi

# Network Configuration
echo -e "${GREEN}[12/15] Backing up network configuration...${NC}"
ip addr > network_interfaces.txt
if [ -d /etc/netplan ]; then
    tar czf netplan_config.tar.gz /etc/netplan/ 2>/dev/null || true
fi
cat /etc/hosts > hosts_file_backup.txt
cat /etc/hostname > hostname_backup.txt
cat /etc/resolv.conf > dns_config.txt
echo "✓ Network config backed up"

# Systemd Services
echo -e "${GREEN}[13/15] Backing up systemd services...${NC}"
tar czf systemd_services.tar.gz /etc/systemd/system/*.service 2>/dev/null || true
systemctl list-unit-files --state=enabled > enabled_services.txt

# Cron Jobs
echo -e "${GREEN}[14/15] Backing up cron jobs...${NC}"
crontab -l > user_crontab.txt 2>/dev/null || echo "No user crontab"
crontab -u root -l > root_crontab.txt 2>/dev/null || echo "No root crontab"
if [ -d /etc/cron.d ]; then
    tar czf cron_d.tar.gz /etc/cron.d/ 2>/dev/null || true
fi

# Firewall Rules
echo -e "${GREEN}[15/15] Backing up firewall rules...${NC}"
ufw status verbose > ufw_rules.txt 2>/dev/null || true
iptables-save > iptables_rules.txt 2>/dev/null || true

# Create restore instructions
cat > RESTORE_INSTRUCTIONS.txt << 'EOF'
RESTORE INSTRUCTIONS
====================

After installing Ubuntu on SSD, restore in this order:

1. System Configuration:
   - Restore network: tar xzf netplan_config.tar.gz -C /
   - Restore hostname: sudo cp hostname_backup.txt /etc/hostname
   - Restore hosts: sudo cp hosts_file_backup.txt /etc/hosts

2. Install Docker:
   curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh

3. Restore Nginx & SSL:
   sudo tar xzf nginx_configs.tar.gz -C /
   sudo tar xzf ssl_certs.tar.gz -C /
   sudo nginx -t && sudo systemctl reload nginx

4. Restore Home & SSH:
   tar xzf home_backup.tar.gz -C /
   tar xzf ssh_user_keys.tar.gz -C /
   chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub

5. Restore /opt:
   sudo tar xzf opt_backup.tar.gz -C /

6. Restore Databases:
   sudo -u postgres psql < postgres_all.sql

7. Restore Docker Compose Services:
   - Copy compose files from docker_compose_files/
   - Run: docker compose up -d in each directory

8. Restore Packages (selective):
   while read package; do sudo apt-get install -y "$package"; done < manual_packages.txt

9. Restore Cron Jobs:
   crontab user_crontab.txt
   sudo crontab root_crontab.txt

10. Verify Everything Works!

EOF

# Calculate backup size
echo ""
echo -e "${YELLOW}Calculating backup size...${NC}"
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo -e "${GREEN}✓ Backup complete!${NC}"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Backup Summary               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "Location: ${YELLOW}$BACKUP_DIR${NC}"
echo -e "Size: ${YELLOW}$BACKUP_SIZE${NC}"
echo -e "Files: ${YELLOW}$(find "$BACKUP_DIR" -type f | wc -l)${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Copy this backup to external drive:"
echo -e "   ${GREEN}sudo cp -r $BACKUP_DIR $EXTERNAL_MOUNT/${NC}"
echo ""
echo "2. Verify backup on external drive"
echo ""
echo "3. Create Ubuntu USB installer"
echo ""
echo "4. Boot from USB and install Ubuntu on SSD (nvme0n1)"
echo ""
echo "5. After installation, restore using RESTORE_INSTRUCTIONS.txt"
echo ""
echo -e "${RED}⚠️  DO NOT DELETE THIS BACKUP UNTIL NEW SYSTEM IS VERIFIED!${NC}"
echo ""

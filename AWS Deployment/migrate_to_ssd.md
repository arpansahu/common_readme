# Migrate Ubuntu from HDD to SSD - Complete Guide

This guide will help you migrate your Ubuntu installation from HDD (931GB) to SSD (238GB NVMe).

## Current Setup
- **HDD (sda)**: 931.5GB, Ubuntu LVM with 100GB allocated (52GB used)
- **SSD (nvme0n1)**: 238.5GB, Windows installed (will be wiped)
- **Goal**: Fresh Ubuntu installation on SSD with all data migrated

## Prerequisites

### What You'll Need
1. **USB Drive** (8GB+) for Ubuntu installation media
2. **Backup Drive** (external HDD/USB) for data backup
3. **Physical Access** to the server
4. **Time**: 2-4 hours
5. **Ubuntu 22.04 LTS ISO** (or your current version)

### Important Warnings
⚠️ **This will completely wipe Windows from SSD**
⚠️ **Server will be down during migration**
⚠️ **Always backup critical data first**

## Phase 1: Backup Current System (Do This First!)

### Step 1.1: Backup Critical Data

Run these commands on your current system:

```bash
# Create backup directory
mkdir -p /tmp/migration_backup
cd /tmp/migration_backup

# Backup important configurations
sudo tar czf nginx_configs.tar.gz /etc/nginx/
sudo tar czf ssl_certs.tar.gz /etc/nginx/ssl/
sudo tar czf docker_configs.tar.gz /etc/docker/
sudo tar czf systemd_services.tar.gz /etc/systemd/system/*.service

# Backup home directory
tar czf home_backup.tar.gz /home/arpansahu/

# Backup /opt directory (if any custom software)
sudo tar czf opt_backup.tar.gz /opt/

# Export Docker volumes list
docker volume ls > docker_volumes.txt

# Export list of installed packages
dpkg --get-selections > installed_packages.txt
apt-mark showmanual > manual_packages.txt

# Backup SSH keys
tar czf ssh_backup.tar.gz ~/.ssh/

# Copy all backups to external drive
# Mount your external drive first, then:
# sudo cp -r /tmp/migration_backup /media/your_external_drive/
```

### Step 1.2: Backup Databases

```bash
# PostgreSQL backup
sudo -u postgres pg_dumpall > /tmp/migration_backup/postgres_all.sql

# If you have specific database backups needed
docker exec postgres_container pg_dump -U postgres your_database > /tmp/migration_backup/specific_db.sql
```

### Step 1.3: Export Docker Containers

```bash
# List all containers
docker ps -a > /tmp/migration_backup/docker_containers.txt

# Export Docker Compose files
find / -name "docker-compose.yml" 2>/dev/null > /tmp/migration_backup/compose_files.txt

# Copy all compose files to backup
while IFS= read -r file; do
    sudo cp "$file" /tmp/migration_backup/compose_$(basename $(dirname "$file")).yml
done < /tmp/migration_backup/compose_files.txt
```

### Step 1.4: Document Current State

```bash
# Network configuration
ip addr > /tmp/migration_backup/network_config.txt
cat /etc/netplan/*.yaml > /tmp/migration_backup/netplan_config.txt

# Mounted filesystems
mount > /tmp/migration_backup/mounts.txt
cat /etc/fstab > /tmp/migration_backup/fstab_backup.txt

# Cron jobs
crontab -l > /tmp/migration_backup/user_crontab.txt
sudo crontab -l > /tmp/migration_backup/root_crontab.txt

# Firewall rules
sudo ufw status verbose > /tmp/migration_backup/ufw_rules.txt

# Kernel modules
lsmod > /tmp/migration_backup/kernel_modules.txt
```

## Phase 2: Prepare Installation Media

### Step 2.1: Download Ubuntu ISO

On your Mac:
```bash
# Download Ubuntu 22.04 LTS
curl -L -o ~/Downloads/ubuntu-22.04.5-live-server-amd64.iso \
  https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
```

### Step 2.2: Create Bootable USB

```bash
# Find your USB drive
diskutil list

# Unmount USB (replace diskX with your USB)
diskutil unmountDisk /dev/diskX

# Write ISO to USB (THIS WILL ERASE USB!)
sudo dd if=~/Downloads/ubuntu-22.04.5-live-server-amd64.iso of=/dev/rdiskX bs=1m

# Eject USB
diskutil eject /dev/diskX
```

## Phase 3: Install Ubuntu on SSD

### Step 3.1: Boot from USB

1. Insert USB drive into server
2. Restart server
3. Press F12/F2/Del (depends on motherboard) to enter boot menu
4. Select USB drive to boot

### Step 3.2: Installation Process

1. **Select "Install Ubuntu Server"**

2. **Language & Keyboard**: Choose your preferences

3. **Network Configuration**: 
   - Keep existing network settings or configure static IP
   - Note your current IP from backup: `cat /tmp/migration_backup/network_config.txt`

4. **Storage Configuration**: **CRITICAL STEP**
   
   Choose "Custom storage layout"
   
   **Delete all partitions on nvme0n1 (SSD)**
   
   **Create new partition scheme:**
   
   ```
   Device: /dev/nvme0n1 (238.5 GB SSD)
   
   Partition 1:
     Type: EFI System Partition
     Size: 512 MB
     Mount: /boot/efi
     Format: FAT32
   
   Partition 2:
     Type: Linux filesystem
     Size: 2 GB
     Mount: /boot
     Format: ext4
   
   Partition 3:
     Type: Linux filesystem (or LVM)
     Size: Remaining space (~236 GB)
     Mount: /
     Format: ext4
     
     OR for LVM (more flexible):
     Type: LVM physical volume
     Volume Group: ubuntu-vg-ssd
     Logical Volume: root-lv (100GB), data-lv (130GB)
   ```

5. **User Setup**:
   - Username: arpansahu
   - Server name: same as before
   - Password: (your password)

6. **SSH Setup**: Install OpenSSH server

7. **Software**: Skip snaps for now, install later

8. **Install & Reboot**

## Phase 4: Post-Installation Configuration

### Step 4.1: Initial Setup

After first boot, SSH into the new system:

```bash
ssh arpansahu@192.168.1.200
```

Update system:
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 4.2: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker compose version
```

### Step 4.3: Restore Configurations

Copy backups from external drive to server, then:

```bash
# Navigate to backup location
cd /path/to/migration_backup/

# Restore nginx configs
sudo tar xzf nginx_configs.tar.gz -C /
sudo tar xzf ssl_certs.tar.gz -C /

# Restore home directory
tar xzf home_backup.tar.gz -C /

# Restore SSH keys
tar xzf ssh_backup.tar.gz -C ~/

# Restore /opt
sudo tar xzf opt_backup.tar.gz -C /

# Fix permissions
sudo chown -R arpansahu:arpansahu /home/arpansahu
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
```

### Step 4.4: Restore PostgreSQL

```bash
# Install PostgreSQL (if needed)
sudo apt install postgresql postgresql-contrib -y

# Restore all databases
sudo -u postgres psql < postgres_all.sql

# Or restore specific database
sudo -u postgres psql -d database_name < specific_db.sql
```

### Step 4.5: Restore Docker Containers

```bash
# Pull all images (list from backup)
# docker pull image:tag

# Restore compose services
# Copy docker-compose.yml files to appropriate locations
# Run: docker compose up -d in each directory
```

### Step 4.6: Reinstall Packages

```bash
# Restore manually installed packages
sudo dpkg --set-selections < installed_packages.txt
sudo apt-get dselect-upgrade -y

# Or selective restore
while read package; do
    sudo apt-get install -y "$package"
done < manual_packages.txt
```

### Step 4.7: Restore Network Configuration

```bash
# Edit netplan if needed
sudo nano /etc/netplan/00-installer-config.yaml

# Apply netplan
sudo netplan apply
```

### Step 4.8: Restore Cron Jobs

```bash
crontab user_crontab.txt
sudo crontab root_crontab.txt
```

### Step 4.9: Restore Firewall

```bash
# Parse and reapply ufw rules from backup
sudo ufw enable
# Add rules from ufw_rules.txt manually
```

## Phase 5: Verification

### Step 5.1: Check System

```bash
# Verify SSD is being used
df -h
lsblk

# Check boot time (should be faster)
systemd-analyze

# Test disk speed
sudo hdparm -Tt /dev/nvme0n1

# Check all services
sudo systemctl list-units --state=failed
```

### Step 5.2: Test Applications

1. Access all websites (nginx)
2. Test Docker containers
3. Verify databases
4. Check Celery workers
5. Test Jenkins builds

### Step 5.3: Monitor Performance

```bash
# Check I/O performance
iostat -x 1

# Monitor disk usage
watch df -h

# Check memory
free -h
```

## Phase 6: Cleanup Old HDD

### After confirming everything works:

```bash
# The old HDD (sda) can now be:
# Option 1: Wipe and use for storage
# Option 2: Keep as backup for a while
# Option 3: Repurpose for Docker volumes

# To wipe (BE CAREFUL!):
# sudo wipefs -a /dev/sda
# sudo fdisk /dev/sda  # Create new partition table
```

## Performance Improvements Expected

After migration to SSD:

- **Boot time**: 30-60% faster
- **Docker start/stop**: 5-10x faster
- **Database queries**: 3-5x faster
- **File operations**: 10-20x faster
- **Build times**: 40-60% faster
- **Overall responsiveness**: Significantly better

## Troubleshooting

### If system won't boot after installation:

1. Boot from USB again
2. Mount the SSD root partition
3. Chroot into it
4. Reinstall GRUB:
   ```bash
   sudo mount /dev/nvme0n1p3 /mnt
   sudo mount /dev/nvme0n1p2 /mnt/boot
   sudo mount /dev/nvme0n1p1 /mnt/boot/efi
   sudo mount --bind /dev /mnt/dev
   sudo mount --bind /proc /mnt/proc
   sudo mount --bind /sys /mnt/sys
   sudo chroot /mnt
   grub-install /dev/nvme0n1
   update-grub
   exit
   sudo reboot
   ```

### If network doesn't work:

Check netplan configuration and reapply.

### If Docker containers won't start:

Check volumes and network configurations.

## Alternative: Quick Clone Method

If you prefer cloning over fresh install:

```bash
# Boot from Ubuntu Live USB
# Install clonezilla
sudo apt install clonezilla

# Use Clonezilla to clone sda to nvme0n1
# Then resize partitions to fit SSD
# Update fstab and GRUB
```

Note: Fresh install is cleaner and recommended for SSD optimization.

## Timeline

- **Backup**: 30-60 minutes
- **Installation**: 20-30 minutes  
- **Restore**: 1-2 hours
- **Testing**: 30 minutes
- **Total**: 2.5-4 hours

## Support

If you encounter issues during migration:
1. Boot from USB into recovery mode
2. Access old HDD data if needed
3. Restore from backups
4. Ask for help with specific error messages

## Post-Migration Optimization

After successful migration, optimize for SSD:

```bash
# Enable TRIM
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Check TRIM status
sudo fstrim -v /

# Verify SSD is detected
sudo hdparm -I /dev/nvme0n1 | grep TRIM
```

Your system will be significantly faster on the SSD! 🚀

# Clone Ubuntu HDD to SSD using Clonezilla

This is the EASIEST method - clone your current system directly to SSD with Clonezilla.

## What You Need
- ✅ 64GB USB pendrive (you have this!)
- ✅ Physical access to server
- ✅ 1-2 hours of time

## Advantages Over Fresh Install
- ✅ Everything preserved exactly as-is
- ✅ No need to restore configurations
- ✅ No need to reinstall Docker containers
- ✅ Much faster process
- ✅ Boots immediately after cloning
- ⏱️ Only 1-2 hours vs 3-4 hours

## Step 1: Create Clonezilla USB (On Your Mac)

### Download Clonezilla
```bash
# Download Clonezilla ISO
cd ~/Downloads
curl -L -o clonezilla-live.iso \
  "https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/3.1.2-22/clonezilla-live-3.1.2-22-amd64.iso/download"
```

### Create Bootable USB
```bash
# Find your 64GB USB drive
diskutil list

# Identify your USB (look for 64GB drive, e.g., /dev/disk4)
# BE CAREFUL - wrong disk will erase your data!

# Unmount the USB
diskutil unmountDisk /dev/diskX  # Replace X with your USB disk number

# Write Clonezilla to USB (THIS WILL ERASE USB!)
sudo dd if=~/Downloads/clonezilla-live.iso of=/dev/rdiskX bs=1m status=progress

# This takes 5-10 minutes, wait for completion

# Eject USB
diskutil eject /dev/diskX
```

## Step 2: Boot from Clonezilla USB

1. **Insert USB** into server
2. **Restart** server
3. **Enter BIOS/Boot Menu** (press F12, F2, Del, or Esc during boot)
4. **Select USB** to boot from
5. **Wait** for Clonezilla to load (takes ~30 seconds)

## Step 3: Clone Using Clonezilla

### 3.1 Initial Setup

1. **Language**: Choose English (or your preference)
2. **Keyboard**: Choose your keyboard layout (default is OK)
3. **Start Clonezilla**: Select "Start Clonezilla"
4. **Mode**: Select "device-device" (disk to disk)
5. **Mode**: Select "Beginner mode" (recommended)

### 3.2 Select Source and Destination

⚠️ **CRITICAL STEP - BE VERY CAREFUL!**

1. **Source disk**: Select `/dev/sda` (931.5GB HDD)
   - This is your current Ubuntu system

2. **Destination disk**: Select `/dev/nvme0n1` (238.5GB SSD)
   - This will WIPE Windows on SSD!

⚠️ **Double-check**: 
- Source = sda (HDD with Ubuntu)
- Destination = nvme0n1 (SSD with Windows - will be wiped)

### 3.3 Cloning Options

1. **Clone type**: Select "sfsck" (skip checking source filesystem)
   - Or select "sfsck" (check and repair source filesystem) if you want to be safe

2. **Clone method**: Select "Use the partition table from the source disk"

3. **Advanced parameters**: 
   - Select "-k1" (Create partition table proportionally)
   - This will automatically resize partitions to fit SSD

4. **Confirm**: Type "y" to confirm (it will show warnings)

5. **Final confirmation**: Type "y" again to start cloning

### 3.4 Wait for Cloning

- **Time**: 30-60 minutes (depends on data amount, you have 52GB used)
- **Progress**: Shows percentage and estimated time
- Coffee break! ☕

## Step 4: Post-Clone Configuration

After cloning completes:

1. **Reboot**: Remove USB and reboot
2. **BIOS**: Enter BIOS (F2/Del during boot)
3. **Boot Order**: Set SSD (nvme0n1) as first boot device
4. **Save & Exit**

### 4.1 First Boot on SSD

System should boot normally! But we need to fix a few things:

```bash
# After booting into the cloned system
ssh arpansahu@192.168.1.200

# Check if booted from SSD
df -h
# Should show /dev/nvme0n1p3 (or similar) mounted on /

# Verify disk usage
lsblk
```

### 4.2 Expand Filesystem (Optional)

Clonezilla should auto-expand, but if not:

```bash
# Check current size
df -h /

# If root partition is not using full SSD space:
sudo lvresize -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# Or if not using LVM:
sudo resize2fs /dev/nvme0n1p3

# Verify
df -h /
```

### 4.3 Update fstab (if needed)

```bash
# Check fstab
cat /etc/fstab

# If it references old disk UUIDs, update them
sudo blkid  # Get new UUIDs
sudo nano /etc/fstab  # Update if needed (usually not necessary)
```

### 4.4 Reinstall/Update GRUB (if boot issues)

```bash
# Only if you have boot issues
sudo grub-install /dev/nvme0n1
sudo update-grub
```

### 4.5 Enable TRIM for SSD

```bash
# Enable TRIM for better SSD performance
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Run TRIM manually first time
sudo fstrim -v /
```

## Step 5: Verification

### Check Everything Works

```bash
# 1. Verify booted from SSD
lsblk
df -h

# 2. Test disk performance (should be much faster!)
sudo hdparm -Tt /dev/nvme0n1

# Expected: 
# - Cached reads: ~10,000-15,000 MB/sec (vs ~150 MB/sec on HDD)
# - Buffered reads: ~500-1500 MB/sec (vs ~120 MB/sec on HDD)

# 3. Check boot time (should be faster)
systemd-analyze

# 4. Verify all services running
sudo systemctl status docker
sudo systemctl status nginx
docker ps

# 5. Test websites
curl -I https://django-starter.arpansahu.space
curl -I https://jenkins.arpansahu.space

# 6. Check Docker
docker ps -a

# 7. Test database
# Access PostgreSQL, Redis, etc.
```

### Performance Comparison

Run these before and after:

```bash
# Disk speed test
sudo hdparm -Tt /dev/nvme0n1  # SSD
sudo hdparm -Tt /dev/sda      # HDD (for comparison)

# I/O performance
sudo dd if=/dev/zero of=/tmp/testfile bs=1M count=1000 conv=fdatasync
rm /tmp/testfile

# Docker start time
time docker restart postgres_container
```

## Step 6: Cleanup Old HDD

After confirming everything works (keep for a week to be safe):

### Option A: Wipe HDD and Use for Storage

```bash
# CAREFUL - This will erase all data on HDD!
sudo wipefs -a /dev/sda
sudo fdisk /dev/sda

# Create new partition:
# - Press 'n' for new partition
# - Press 'p' for primary
# - Accept defaults
# - Press 'w' to write

# Format as ext4
sudo mkfs.ext4 /dev/sda1

# Mount for storage
sudo mkdir -p /mnt/storage
sudo mount /dev/sda1 /mnt/storage

# Add to fstab for permanent mount
echo "/dev/sda1 /mnt/storage ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

### Option B: Keep HDD as Backup

Just leave it as-is for emergency recovery.

### Option C: Use HDD for Docker Volumes

```bash
# Move large Docker volumes to HDD
# Useful for MinIO, PostgreSQL data, etc.
```

## Troubleshooting

### Problem: Won't Boot After Clone

**Solution 1**: Reinstall GRUB
```bash
# Boot from Clonezilla USB again
# Select "Enter shell"

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

### Problem: System Boots but Slow

**Solution**: Enable TRIM
```bash
sudo systemctl enable fstrim.timer
sudo fstrim -v /
```

### Problem: Partition Too Small

**Solution**: Expand filesystem
```bash
# For LVM
sudo lvresize -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# For regular partition
sudo resize2fs /dev/nvme0n1p3
```

### Problem: Can't Boot Either Disk

**Solution**: Boot from USB, mount and check logs
```bash
# Boot from Clonezilla USB
# Select "Enter shell"
sudo mount /dev/nvme0n1p3 /mnt
sudo cat /mnt/var/log/syslog
# Check for errors
```

## Expected Timeline

- **Create USB**: 10 minutes
- **Boot and setup**: 5 minutes
- **Cloning**: 30-60 minutes (52GB data)
- **Post-configuration**: 10 minutes
- **Testing**: 10 minutes
- **Total**: 1-1.5 hours

## Benefits After Migration

- ⚡ **Boot time**: 20-30 seconds (vs 60-90 seconds)
- ⚡ **Docker start**: Near instant (vs 5-10 seconds)
- ⚡ **Jenkins builds**: 40-50% faster
- ⚡ **Database queries**: 3-5x faster
- ⚡ **File operations**: 10-20x faster
- ⚡ **Overall**: System feels much more responsive!

## Comparison: Clonezilla vs Fresh Install

| Aspect | Clonezilla Clone | Fresh Install |
|--------|-----------------|---------------|
| Time | 1-1.5 hours | 3-4 hours |
| Complexity | Easy | Moderate |
| Risk | Low | Medium |
| Preservation | Everything preserved | Manual restore needed |
| Optimization | May need tweaks | Fresh & optimized |
| Recommended | ✅ Yes, for you! | If you want clean slate |

## Why Clonezilla is Better for You

1. ✅ You have working system - why rebuild?
2. ✅ All configs, Docker, databases preserved
3. ✅ Much faster process
4. ✅ Less chance of forgetting something
5. ✅ Can fall back to HDD if issues

## Important Notes

1. ⚠️ **Windows will be wiped** - make sure you don't need it
2. ✅ All your Docker containers, databases, configs will be preserved
3. ✅ All your Jenkins builds and configurations will work
4. ✅ All your SSL certificates and nginx configs will work
5. ✅ Everything stays exactly as-is, just faster!

Ready to proceed? This is definitely the easiest way! 🚀

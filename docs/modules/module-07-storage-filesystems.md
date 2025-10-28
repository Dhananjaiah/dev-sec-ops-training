# Module 07: Storage, Partitions, Filesystems

## Why it matters
Storage management is critical—disks fill up, partitions need resizing, and choosing the wrong filesystem can cost performance or data. Understanding lsblk, fdisk, mkfs, and /etc/fstab prevents catastrophic data loss. This module teaches safe disk operations with clear danger warnings.

## Prerequisites
**Packages/Tools:**
- util-linux (lsblk, fdisk, mount) — pre-installed
- e2fsprogs (mkfs.ext4, tune2fs) — pre-installed
- xfsprogs (mkfs.xfs) — install if using XFS
- parted — install for GPT partitioning

**Files/Labs:**
- **🚨 DANGER:** Use spare VM or disk, NOT production
- Take VM snapshot before proceeding

## Cheat-Sheet
- `lsblk` — list block devices
- `blkid` — show UUID and filesystem type
- `fdisk -l` — list partition tables (MBR)
- `parted -l` — list partition tables (GPT)
- `fdisk /dev/sdX` — partition disk (MBR)
- `parted /dev/sdX` — partition disk (GPT)
- `mkfs.ext4 /dev/sdX1` — format partition as ext4
- `mount /dev/sdX1 /mnt` — mount filesystem
- `umount /mnt` — unmount
- `df -h` — show mounted filesystems and usage
- `du -sh <dir>` — show directory size

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== VIEW STORAGE DEVICES =====
# List block devices (best overview)
lsblk
# NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda      8:0    0   20G  0 disk
# ├─sda1   8:1    0    1M  0 part
# ├─sda2   8:2    0    1G  0 part /boot
# └─sda3   8:3    0   19G  0 part /

# Show UUIDs and filesystem types
sudo blkid
# /dev/sda2: UUID="abc-123" TYPE="ext4"

# List all disks and partitions
sudo fdisk -l
sudo parted -l

# Show disk usage (mounted filesystems)
df -h
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda3        19G   8G   10G  45% /

# Show directory sizes
du -sh /var/log
du -h --max-depth=1 /var | sort -h

# Find large files
find /var -type f -size +100M 2>/dev/null

# ===== PARTITIONING WITH FDISK (MBR, disks < 2TB) =====
# 🚨 DANGER: This will destroy data! Use test VM with spare disk!

# Attach new virtual disk to VM first (in VM settings)
# After attaching, find it:
lsblk
# Assume new disk is /dev/sdb

# Partition with fdisk
sudo fdisk /dev/sdb

# Inside fdisk:
# p - print partition table
# n - new partition
# p - primary partition
# 1 - partition number
# [Enter] - first sector (default)
# +5G - size (5GB partition)
# p - verify
# w - write changes and exit

# Verify partition created
lsblk
# sdb      8:16   0   10G  0 disk
# └─sdb1   8:17   0    5G  0 part

# ===== PARTITIONING WITH PARTED (GPT, any size) =====
# Use parted for disks > 2TB or modern systems

sudo parted /dev/sdb
# (parted) print  # show current layout
# (parted) mklabel gpt  # create GPT table (🚨 destroys data!)
# (parted) mkpart primary 0% 50%  # create partition using 50% of disk
# (parted) print
# (parted) quit

# Or one-liner:
sudo parted /dev/sdb mklabel gpt mkpart primary 0% 50%

lsblk  # verify

# ===== FILESYSTEMS =====
# Format partition as ext4 (🚨 DANGER: erases all data on partition!)
sudo mkfs.ext4 /dev/sdb1
# Creates ext4 filesystem

# Format as XFS
sudo apt install xfsprogs
sudo mkfs.xfs -f /dev/sdb1  # -f force overwrites

# Format as btrfs
sudo apt install btrfs-progs
sudo mkfs.btrfs /dev/sdb1

# Set filesystem label
sudo e2label /dev/sdb1 "MyData"  # ext4
sudo xfs_admin -L "MyData" /dev/sdb1  # XFS

# Show filesystem info
sudo tune2fs -l /dev/sdb1 | head -20  # ext4
sudo xfs_info /dev/sdb1  # XFS

# ===== MOUNTING =====
# Create mount point
sudo mkdir -p /mnt/data

# Mount filesystem
sudo mount /dev/sdb1 /mnt/data

# Verify
df -h | grep sdb1
lsblk

# Test write
sudo touch /mnt/data/testfile
ls /mnt/data

# Unmount
sudo umount /mnt/data

# Mount by UUID (safer than device name)
UUID=$(sudo blkid -s UUID -o value /dev/sdb1)
sudo mount UUID=$UUID /mnt/data

# Unmount
sudo umount /mnt/data

# ===== /etc/fstab (persistent mounts) =====
# Backup fstab first!
sudo cp /etc/fstab /etc/fstab.backup

# Get UUID
sudo blkid /dev/sdb1
# UUID="abc-123-def"

# Edit fstab
sudo nano /etc/fstab

# Add line (use UUID, not /dev/sdX):
# UUID=abc-123-def  /mnt/data  ext4  defaults  0  2
# Format: <device> <mountpoint> <filesystem> <options> <dump> <fsck>

# Options:
# defaults = rw,suid,dev,exec,auto,nouser,async
# noatime = don't update access time (performance)
# ro = read-only
# user = allow non-root to mount

# Dump: 0 = don't backup, 1 = backup
# Fsck: 0 = don't check, 1 = check first (root), 2 = check after root

# Test fstab without rebooting
sudo mount -a
# If errors, fix fstab before rebooting!

df -h | grep sdb1

# ===== SWAP =====
# Create swap partition
sudo fdisk /dev/sdb
# n, p, 2, [Enter], +2G, t, 2, 82 (swap type), w

# Format as swap
sudo mkswap /dev/sdb2

# Enable swap
sudo swapon /dev/sdb2

# Verify
swapon --show
free -h

# Disable swap
sudo swapoff /dev/sdb2

# Add to fstab for persistence
UUID=$(sudo blkid -s UUID -o value /dev/sdb2)
echo "UUID=$UUID  none  swap  sw  0  0" | sudo tee -a /etc/fstab

# ===== SWAP FILE (alternative to partition) =====
# Create 2GB swap file
sudo fallocate -l 2G /swapfile  # or: sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile  # security
sudo mkswap /swapfile
sudo swapon /swapfile
swapon --show

# Add to fstab
echo "/swapfile  none  swap  sw  0  0" | sudo tee -a /etc/fstab

# ===== QUOTAS =====
# Install quota tools
sudo apt install quota quotatool

# Edit fstab to enable quotas
sudo nano /etc/fstab
# Add usrquota,grpquota to options:
# UUID=abc  /mnt/data  ext4  defaults,usrquota,grpquota  0  2

# Remount with quotas
sudo mount -o remount /mnt/data

# Initialize quota database
sudo quotacheck -cugm /mnt/data
# -c create, -u user, -g group, -m don't remount

# Turn on quotas
sudo quotaon /mnt/data

# Set user quota (1GB soft, 2GB hard limit)
sudo setquota -u alice 1000000 2000000 0 0 /mnt/data

# Check quota
sudo quota -u alice

# Report all quotas
sudo repquota /mnt/data

# ===== TMPFS (RAM-based filesystem) =====
# Create tmpfs mount
sudo mkdir /mnt/ramdisk
sudo mount -t tmpfs -o size=512M tmpfs /mnt/ramdisk

df -h | grep ramdisk

# Add to fstab
echo "tmpfs  /mnt/ramdisk  tmpfs  size=512M  0  0" | sudo tee -a /etc/fstab

# ===== FILESYSTEM CHECKS =====
# Check filesystem (must be unmounted!)
sudo umount /dev/sdb1
sudo fsck /dev/sdb1  # ext4
sudo xfs_repair /dev/sdb1  # XFS (doesn't need umount for checking)

# Force check on next boot (ext4)
sudo tune2fs -C 1 /dev/sdb1  # sets mount count to trigger check
```

### RHEL/Rocky
```bash
# ===== VIEW STORAGE (same as Ubuntu) =====
lsblk
sudo blkid
df -h

# ===== PARTITIONING (same commands) =====
sudo fdisk /dev/sdb
sudo parted /dev/sdb mklabel gpt mkpart primary 0% 50%

# ===== FILESYSTEMS =====
# XFS is default on RHEL
sudo dnf install xfsprogs
sudo mkfs.xfs -f /dev/sdb1

# ext4 also available
sudo mkfs.ext4 /dev/sdb1

# ===== MOUNTING (same as Ubuntu) =====
sudo mkdir /mnt/data
sudo mount /dev/sdb1 /mnt/data
sudo umount /mnt/data

# ===== /etc/fstab (same format) =====
sudo nano /etc/fstab
# UUID=abc  /mnt/data  xfs  defaults  0  2

sudo mount -a
df -h

# ===== SWAP (same as Ubuntu) =====
sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2
swapon --show

# ===== QUOTAS (same process) =====
sudo dnf install quota
# (same steps as Ubuntu)
```

### SUSE
```bash
# ===== VIEW STORAGE (same) =====
lsblk
sudo blkid
df -h

# ===== PARTITIONING (same) =====
sudo fdisk /dev/sdb
sudo parted /dev/sdb

# ===== FILESYSTEMS =====
# Btrfs is default on SUSE
sudo mkfs.btrfs /dev/sdb1

# ext4 also available
sudo mkfs.ext4 /dev/sdb1

# ===== MOUNTING (same) =====
sudo mkdir /mnt/data
sudo mount /dev/sdb1 /mnt/data

# ===== /etc/fstab (same) =====
sudo nano /etc/fstab
# UUID=abc  /mnt/data  btrfs  defaults  0  2

# ===== QUOTAS (same) =====
sudo zypper install quota
```

---

## Verify
```bash
# List all block devices
lsblk
# Expected: sda, sdb, etc. with partitions

# Show mounted filesystems
df -h
# Expected: / and other mounts

# Test creating small partition (safe on VM)
# (Requires spare disk - skip if unavailable)

# Verify fstab syntax
sudo mount -a
echo $?
# Expected: 0 (success)
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `mount: /dev/sdb1 already mounted` | Partition already mounted | `sudo umount /dev/sdb1` first |
| `mount: unknown filesystem type` | Wrong filesystem or not formatted | Check `sudo blkid /dev/sdb1`; reformat if needed |
| `device is busy` when unmounting | Files open or process using it | `lsof /mnt/data` to find process, kill it, then umount |
| Boot fails after fstab edit | Syntax error in fstab | Boot rescue mode, edit /etc/fstab, remove bad line |
| `fsck: Permission denied` | Filesystem is mounted | Unmount first or boot rescue |
| `disk full` but df shows space | Inodes exhausted | `df -i` to check inodes; delete old files |

---

## Cleanup
```bash
# 🚨 ONLY if you created test partitions
sudo umount /mnt/data 2>/dev/null || true
sudo swapoff /dev/sdb2 2>/dev/null || true

# Remove fstab entries (edit manually)
sudo nano /etc/fstab
# Remove test lines

# Optional: wipe partition table (🚨 destroys all data on disk!)
# sudo wipefs -a /dev/sdb
```

---

## Quick Quiz

1. What command shows all block devices and their mount points?
2. What's the difference between fdisk and parted?
3. What does the last column in /etc/fstab (fsck order) mean?
4. How do you mount a filesystem by UUID instead of device name?
5. What's the difference between a swap partition and a swap file?

---

**Next:** [Module 08: LVM & RAID](module-08-lvm-raid.md)

# Module 08: LVM & RAID

## Why it matters
LVM (Logical Volume Manager) provides flexible storage: resize volumes without downtime, create snapshots for backups, and add disks on-the-fly. RAID combines multiple disks for redundancy (RAID 1, 5, 6) or performance (RAID 0). Together, they're the foundation of enterprise storage. Understanding pvcreate, vgcreate, lvcreate, and mdadm is essential for managing production systems.

## Prerequisites
**Packages/Tools:**
- lvm2 — usually pre-installed
- mdadm — install for RAID management
- 

**Files/Labs:**
- **🚨 DANGER:** Use test VM with multiple spare disks
- Take VM snapshot before proceeding

## Cheat-Sheet
**LVM:**
- `pvcreate /dev/sdX` — create physical volume
- `vgcreate vgname /dev/sdX` — create volume group
- `lvcreate -L 5G -n lvname vgname` — create logical volume (5GB)
- `lvextend -L +2G /dev/vgname/lvname` — extend LV by 2GB
- `resize2fs /dev/vgname/lvname` — resize ext4 filesystem
- `pvs`, `vgs`, `lvs` — show PVs, VGs, LVs
- `lvcreate -L 1G -s -n snap /dev/vg/lv` — create snapshot

**RAID:**
- `mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdX /dev/sdY` — create RAID 1
- `mdadm --detail /dev/md0` — show RAID status
- `cat /proc/mdstat` — quick RAID status

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== LVM SETUP =====
# Install LVM tools (usually pre-installed)
sudo apt install lvm2

# Attach 2-3 spare virtual disks to VM first
# Verify disks available
lsblk
# Assume /dev/sdb, /dev/sdc available

# STEP 1: Create Physical Volumes (PVs)
sudo pvcreate /dev/sdb
sudo pvcreate /dev/sdc

# Verify PVs
sudo pvs
sudo pvdisplay /dev/sdb

# STEP 2: Create Volume Group (VG)
sudo vgcreate vg_data /dev/sdb /dev/sdc

# Verify VG
sudo vgs
sudo vgdisplay vg_data
# Shows total size (sum of both disks)

# STEP 3: Create Logical Volumes (LVs)
# Create 5GB LV
sudo lvcreate -L 5G -n lv_storage vg_data

# Create LV using percentage of VG
sudo lvcreate -l 50%VG -n lv_backup vg_data

# Verify LVs
sudo lvs
sudo lvdisplay /dev/vg_data/lv_storage

# LV path: /dev/vg_data/lv_storage or /dev/mapper/vg_data-lv_storage

# STEP 4: Format and Mount LV
sudo mkfs.ext4 /dev/vg_data/lv_storage
sudo mkdir /mnt/storage
sudo mount /dev/vg_data/lv_storage /mnt/storage

df -h | grep storage

# Add to fstab
echo "/dev/vg_data/lv_storage  /mnt/storage  ext4  defaults  0  2" | sudo tee -a /etc/fstab

# ===== EXTENDING LVM =====
# Add new disk to VG (if you attach /dev/sdd later)
sudo pvcreate /dev/sdd
sudo vgextend vg_data /dev/sdd
sudo vgs  # total size increased

# Extend LV
sudo lvextend -L +2G /dev/vg_data/lv_storage
# or use percentage: sudo lvextend -l +50%FREE /dev/vg_data/lv_storage

# Verify LV extended
sudo lvs

# Resize filesystem (ext4, MUST do this!)
sudo resize2fs /dev/vg_data/lv_storage
df -h | grep storage  # should show increased size

# For XFS (use xfs_growfs instead):
# sudo xfs_growfs /mnt/storage

# ===== REDUCING LVM (ext4 only, 🚨 DANGER) =====
# XFS cannot be shrunk!
# Unmount first
sudo umount /mnt/storage

# Check filesystem
sudo e2fsck -f /dev/vg_data/lv_storage

# Shrink filesystem to 3GB
sudo resize2fs /dev/vg_data/lv_storage 3G

# Shrink LV to 3GB
sudo lvreduce -L 3G /dev/vg_data/lv_storage

# Remount
sudo mount /dev/vg_data/lv_storage /mnt/storage

# ===== LVM SNAPSHOTS =====
# Create snapshot (10% of LV size)
sudo lvcreate -L 500M -s -n lv_storage_snap /dev/vg_data/lv_storage

# Verify snapshot
sudo lvs
# Shows lv_storage_snap as snapshot of lv_storage

# Mount snapshot (read-only)
sudo mkdir /mnt/snap
sudo mount -o ro /dev/vg_data/lv_storage_snap /mnt/snap

# Snapshot shows data at time of creation
ls /mnt/snap

# Make changes to original
sudo touch /mnt/storage/newfile

# Snapshot unchanged
ls /mnt/snap  # no newfile

# Restore from snapshot (🚨 DANGER: overwrites current data!)
sudo umount /mnt/storage
sudo umount /mnt/snap
sudo lvconvert --merge /dev/vg_data/lv_storage_snap
# Snapshot is merged and removed
# Reboot or re-activate LV:
sudo lvchange -an /dev/vg_data/lv_storage
sudo lvchange -ay /dev/vg_data/lv_storage
sudo mount /dev/vg_data/lv_storage /mnt/storage

# Remove snapshot (if not merging)
sudo umount /mnt/snap
sudo lvremove /dev/vg_data/lv_storage_snap

# ===== REMOVING LVM COMPONENTS =====
# Unmount and remove LV
sudo umount /mnt/storage
sudo lvremove /dev/vg_data/lv_storage  # confirm with 'y'

# Remove VG
sudo vgremove vg_data

# Remove PVs
sudo pvremove /dev/sdb /dev/sdc

# ===== RAID WITH MDADM =====
# Install mdadm
sudo apt install mdadm

# Assume /dev/sdb and /dev/sdc available (wipe them first if used for LVM)
# 🚨 DANGER: This erases disks!
sudo wipefs -a /dev/sdb /dev/sdc

# Create RAID 1 (mirror)
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
# Confirm with 'y'

# Monitor creation (takes time)
cat /proc/mdstat
# Shows progress: [====>................]

# Wait for sync to complete
sudo mdadm --detail /dev/md0
# State should be "clean"

# Format RAID array
sudo mkfs.ext4 /dev/md0

# Mount
sudo mkdir /mnt/raid
sudo mount /dev/md0 /mnt/raid
df -h | grep md0

# Add to fstab (by UUID)
UUID=$(sudo blkid -s UUID -o value /dev/md0)
echo "UUID=$UUID  /mnt/raid  ext4  defaults  0  2" | sudo tee -a /etc/fstab

# Save RAID config
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u

# ===== RAID MANAGEMENT =====
# Check RAID status
cat /proc/mdstat
sudo mdadm --detail /dev/md0

# Simulate disk failure (🚨 test only!)
sudo mdadm --manage /dev/md0 --fail /dev/sdb
cat /proc/mdstat  # shows [U_] (underscore = failed)

# Remove failed disk
sudo mdadm --manage /dev/md0 --remove /dev/sdb

# Add replacement disk
sudo mdadm --manage /dev/md0 --add /dev/sdb
# Rebuilds automatically
cat /proc/mdstat  # shows rebuild progress

# Stop RAID array
sudo umount /mnt/raid
sudo mdadm --stop /dev/md0

# Reassemble RAID
sudo mdadm --assemble --scan
sudo mount /dev/md0 /mnt/raid

# ===== OTHER RAID LEVELS =====
# RAID 0 (striping, no redundancy, 🚨 dangerous!)
sudo mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sdb /dev/sdc

# RAID 5 (needs 3+ disks, 1 disk fault tolerance)
sudo mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd

# RAID 6 (needs 4+ disks, 2 disk fault tolerance)
sudo mdadm --create /dev/md0 --level=6 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

# RAID 10 (mirror + stripe, needs 4+ disks)
sudo mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

# ===== DISK MONITORING (smartctl) =====
# Install smartmontools
sudo apt install smartmontools

# Check disk health
sudo smartctl -H /dev/sdb
# Result: PASSED or FAILED

# Show all SMART data
sudo smartctl -a /dev/sdb

# Run short self-test
sudo smartctl -t short /dev/sdb
# Wait 2 minutes, then check results:
sudo smartctl -l selftest /dev/sdb
```

### RHEL/Rocky
```bash
# ===== LVM (same as Ubuntu) =====
sudo dnf install lvm2
sudo pvcreate /dev/sdb /dev/sdc
sudo vgcreate vg_data /dev/sdb /dev/sdc
sudo lvcreate -L 5G -n lv_storage vg_data
sudo mkfs.xfs /dev/vg_data/lv_storage  # XFS default on RHEL
sudo mount /dev/vg_data/lv_storage /mnt/storage

# Extend (XFS uses xfs_growfs)
sudo lvextend -L +2G /dev/vg_data/lv_storage
sudo xfs_growfs /mnt/storage

# Snapshots (same)
sudo lvcreate -L 500M -s -n lv_storage_snap /dev/vg_data/lv_storage

# ===== RAID (same as Ubuntu) =====
sudo dnf install mdadm
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
sudo mkfs.xfs /dev/md0
sudo mount /dev/md0 /mnt/raid

# Save RAID config
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm.conf
sudo dracut --force  # rebuild initramfs
```

### SUSE
```bash
# ===== LVM (same) =====
sudo zypper install lvm2
sudo pvcreate /dev/sdb
sudo vgcreate vg_data /dev/sdb
sudo lvcreate -L 5G -n lv_storage vg_data
sudo mkfs.btrfs /dev/vg_data/lv_storage  # btrfs default on SUSE
sudo mount /dev/vg_data/lv_storage /mnt/storage

# ===== RAID (same) =====
sudo zypper install mdadm
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
sudo mkfs.btrfs /dev/md0
```

---

## Verify
```bash
# Check LVM components
sudo pvs
sudo vgs
sudo lvs
# Expected: PVs, VGs, LVs listed

# Check RAID status (if created)
cat /proc/mdstat
# Expected: active raid1 md0

# Check mounted LVM
df -h | grep vg_data
# Expected: /mnt/storage shown
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Device /dev/sdb excluded by filter` | Disk has existing filesystem | `sudo wipefs -a /dev/sdb` to clear signatures |
| `resize2fs: Bad magic number` | Filesystem type wrong | Use `xfs_growfs` for XFS, `btrfs filesystem resize` for btrfs |
| LV won't reduce | XFS or btrfs can't shrink | Backup data, destroy LV, recreate smaller |
| RAID won't assemble after reboot | Config not saved | Add to /etc/mdadm.conf and rebuild initramfs |
| `mdadm: cannot open /dev/sdb: Device or resource busy` | Disk in use by LVM/mdadm | `sudo pvremove` or `mdadm --stop` first |

---

## Cleanup
```bash
# 🚨 ONLY if test setup
sudo umount /mnt/storage 2>/dev/null || true
sudo umount /mnt/raid 2>/dev/null || true
sudo lvremove -f /dev/vg_data/lv_storage 2>/dev/null || true
sudo vgremove -f vg_data 2>/dev/null || true
sudo pvremove /dev/sdb /dev/sdc 2>/dev/null || true
sudo mdadm --stop /dev/md0 2>/dev/null || true
sudo wipefs -a /dev/sdb /dev/sdc 2>/dev/null || true
```

---

## Quick Quiz

1. What's the difference between a Physical Volume, Volume Group, and Logical Volume?
2. How do you extend an LVM logical volume and its filesystem?
3. What RAID level provides mirroring with 2 disks?
4. How do you check the status of a RAID array?
5. What's the purpose of an LVM snapshot?

---

**Next:** [Module 09: Advanced Filesystems & Encryption](module-09-advanced-fs-encryption.md)

# Module 29: Troubleshooting Clinic

## Why it matters
Troubleshooting is 50% of a sysadmin's job. Servers crash, networks fail, disks fill up, and users get locked out. This module provides structured diagnostic checklists for the most common Linux issues. Follow these workflows to methodically identify and fix problems.

## Prerequisites
- Knowledge from Modules 1-28
- Root/sudo access
- Understanding of logs, processes, networking, storage

---

## General Troubleshooting Framework

### The 5-Step Process
1. **Define the problem** - What exactly is broken? When did it start?
2. **Gather information** - Logs, error messages, system state
3. **Form hypothesis** - What could cause this based on evidence?
4. **Test hypothesis** - Change one thing, observe result
5. **Document solution** - Write down what fixed it

### Golden Rules
- **Change one thing at a time** - You need to know what fixed it
- **Check logs first** - 90% of issues show up in logs
- **Verify basics** - Is it powered on? Is the service running?
- **Google the error** - Exact error messages, not paraphrases
- **Ask: What changed?** - New config? Update? Recent restart?

---

## Scenario 1: Network is Down

### Symptoms
- Can't ping external hosts
- DNS doesn't resolve
- No network connectivity

### Diagnostic Checklist
```bash
# 1. Check physical/link layer
ip link show
# Look for "UP" state, not "DOWN"
# If DOWN:
sudo ip link set eth0 up

# 2. Check IP address assigned
ip addr show
# Should have IP like 192.168.x.x or 10.x.x.x
# If no IP and using DHCP:
sudo dhclient eth0  # or
sudo systemctl restart NetworkManager

# 3. Check default gateway
ip route show | grep default
# Should show: default via X.X.X.X dev eth0
# If missing:
sudo ip route add default via 192.168.1.1

# 4. Test local network
ping -c 3 192.168.1.1  # ping gateway
# If fails, problem is local network (cable, switch, gateway)

# 5. Test external connectivity
ping -c 3 8.8.8.8  # Google DNS (doesn't require DNS resolution)
# If fails, routing or firewall issue

# 6. Check DNS resolution
ping -c 3 google.com
# If "unknown host", DNS problem

# 7. Check DNS config
cat /etc/resolv.conf
# Should have: nameserver X.X.X.X
# If missing:
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Or check systemd-resolved:
resolvectl status

# 8. Check firewall
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-all  # RHEL
# Temporarily disable to test:
sudo ufw disable  # Ubuntu
sudo systemctl stop firewalld  # RHEL

# 9. Check network service
systemctl status NetworkManager
# Or:
systemctl status systemd-networkd

# 10. Check for conflicting configs
# Netplan vs NetworkManager vs systemd-networkd
# Only one should manage interfaces
```

### Common Fixes
```bash
# Restart networking
sudo systemctl restart NetworkManager  # Desktop/Ubuntu
sudo systemctl restart systemd-networkd  # Server
sudo netplan apply  # Netplan systems

# Renew DHCP lease
sudo dhclient -r  # release
sudo dhclient  # renew

# Flush DNS cache
sudo systemd-resolve --flush-caches  # Ubuntu
sudo systemctl restart nscd  # RHEL (if installed)
```

---

## Scenario 2: Disk Full / No Space Left

### Symptoms
- "No space left on device"
- Services failing to write logs
- Can't create files

### Diagnostic Checklist
```bash
# 1. Check disk usage
df -h
# Look for 100% or near-100% filesystems

# 2. Find large directories
sudo du -sh /* | sort -h
sudo du -sh /var/* | sort -h
sudo du -sh /home/* | sort -h

# 3. Find large files
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -h

# 4. Check for deleted but open files (space not freed)
sudo lsof | grep deleted
# If found, restart the process holding the file

# 5. Check inode usage
df -i
# If 100%, too many small files

# 6. Find directories with most files
sudo find /var -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | tail -20

# 7. Check log files
sudo du -sh /var/log/*
ls -lh /var/log/*.log

# 8. Check apt/dnf cache
sudo du -sh /var/cache/apt/archives  # Ubuntu
sudo du -sh /var/cache/dnf  # RHEL
```

### Common Fixes
```bash
# Clean package cache
sudo apt clean  # Ubuntu
sudo dnf clean all  # RHEL

# Rotate and compress logs immediately
sudo logrotate -f /etc/logrotate.conf

# Delete old logs (careful!)
sudo find /var/log -name "*.log" -mtime +30 -delete
sudo find /var/log -name "*.gz" -mtime +90 -delete

# Clean journal logs
sudo journalctl --vacuum-time=7days
sudo journalctl --vacuum-size=500M

# Delete old kernels (Ubuntu)
sudo apt autoremove --purge

# Clean temp files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Find and delete large files
sudo find /var -type f -size +500M  # review before deleting
```

---

## Scenario 3: Permission Denied

### Symptoms
- "Permission denied" errors
- Can't read/write files
- Service can't start due to permissions

### Diagnostic Checklist
```bash
# 1. Check file permissions
ls -l /path/to/file
# Format: -rw-r--r-- owner group

# 2. Check file owner
stat /path/to/file

# 3. Check current user
whoami
id
groups

# 4. Check if SELinux is blocking (RHEL)
sudo grep -i denied /var/log/audit/audit.log | tail -20
sudo ausearch -m avc -ts recent

# 5. Check AppArmor (Ubuntu)
sudo grep -i apparmor /var/log/syslog | tail -20

# 6. Check ACLs
getfacl /path/to/file

# 7. Check parent directory permissions
ls -ld /path/to
# Need 'x' (execute) on directories to cd into them

# 8. Check immutable attribute
lsattr /path/to/file
# If 'i' flag, file is immutable
```

### Common Fixes
```bash
# Fix file permissions
sudo chmod 644 /path/to/file  # rw-r--r--
sudo chmod 755 /path/to/dir   # rwxr-xr-x

# Fix ownership
sudo chown user:group /path/to/file
sudo chown -R user:group /path/to/dir

# Fix directory traversal
sudo chmod +x /path/to/dir

# Remove immutable
sudo chattr -i /path/to/file

# Fix SELinux context
sudo restorecon -v /path/to/file
# Or set to permissive temporarily:
sudo setenforce 0

# Fix AppArmor
sudo aa-complain /etc/apparmor.d/usr.sbin.service
```

---

## Scenario 4: Service Won't Start

### Symptoms
- `systemctl start service` fails
- Service crashes immediately
- Service in "failed" state

### Diagnostic Checklist
```bash
# 1. Check service status
systemctl status service.service
# Look for error messages in output

# 2. Check recent logs
journalctl -u service.service -n 50
journalctl -u service.service --since "5 minutes ago"

# 3. Check errors only
journalctl -u service.service -p err

# 4. Check service dependencies
systemctl list-dependencies service.service
# Ensure dependencies are running

# 5. Check if port already in use
ss -tulnp | grep :80  # if service uses port 80

# 6. Check config file syntax
# For nginx:
sudo nginx -t
# For Apache:
sudo apache2ctl configtest

# 7. Check file permissions
ls -l /etc/service/config.conf
ls -l /var/run/service.pid

# 8. Check if binary exists
which service-binary

# 9. Try running manually
sudo -u service-user /usr/bin/service-binary --config /etc/service/config.conf

# 10. Check resource limits
ulimit -a
```

### Common Fixes
```bash
# Fix config syntax error
sudo nano /etc/service/config.conf
# Fix the error, then:
sudo systemctl restart service

# Kill process on conflicting port
sudo lsof -i :80
sudo kill -9 <PID>

# Fix permissions on config/run dirs
sudo chown -R service-user:service-group /etc/service
sudo chmod 755 /var/run/service

# Increase resource limits
sudo systemctl edit service.service
# Add:
# [Service]
# LimitNOFILE=65536

sudo systemctl daemon-reload
sudo systemctl restart service

# Reset failed state
sudo systemctl reset-failed service.service
```

---

## Scenario 5: User Locked Out / Can't Login

### Symptoms
- SSH connection refused
- "Permission denied (publickey)"
- Account locked
- Password not working

### Diagnostic Checklist
```bash
# 1. Check SSH service
systemctl status sshd

# 2. Check SSH logs
sudo tail -50 /var/log/auth.log  # Ubuntu
sudo tail -50 /var/log/secure    # RHEL

# 3. Check if account is locked
sudo passwd -S username
# Look for 'L' (locked)

# 4. Check password expiration
sudo chage -l username

# 5. Check if user exists
id username
grep username /etc/passwd

# 6. Check authorized_keys permissions (for key auth)
ls -la /home/username/.ssh/
cat /home/username/.ssh/authorized_keys

# 7. Check SSH config
sudo cat /etc/ssh/sshd_config | grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication'

# 8. Check firewall
sudo ufw status | grep ssh
sudo firewall-cmd --list-services | grep ssh

# 9. Check SELinux (RHEL)
sudo grep -i ssh /var/log/audit/audit.log | tail -20

# 10. Try SSH with verbose output
ssh -vvv username@host
```

### Common Fixes
```bash
# Unlock account
sudo passwd -u username
sudo usermod -U username

# Reset password expiration
sudo chage -E -1 username  # never expire
sudo chage -d 0 username  # force change on next login

# Fix .ssh permissions
sudo chmod 700 /home/username/.ssh
sudo chmod 600 /home/username/.ssh/authorized_keys
sudo chown -R username:username /home/username/.ssh

# Re-enable password authentication (temporary, for recovery)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication yes
sudo systemctl restart sshd

# Allow root login (emergency only)
# PermitRootLogin yes

# Check if user in AllowUsers/DenyUsers
sudo grep -E 'AllowUsers|DenyUsers' /etc/ssh/sshd_config
```

---

## Scenario 6: Boot Failure / System Won't Start

### Symptoms
- System hangs at boot
- "Emergency mode" or "rescue mode"
- Kernel panic
- Missing GRUB menu

### Diagnostic Checklist (Boot from live USB/rescue mode)
```bash
# 1. Boot into rescue/emergency mode
# At GRUB, press 'e', add 'systemd.unit=rescue.target' to kernel line

# 2. Check /etc/fstab errors
cat /etc/fstab
# Look for non-existent UUIDs or mount points

# 3. Check filesystem errors
sudo fsck /dev/sda1  # must be unmounted

# 4. Check disk space in /boot
df -h | grep boot
ls -lh /boot
# If full, remove old kernels

# 5. Check systemd failures
journalctl -xb  # logs from current boot
systemctl list-units --failed

# 6. Check for recent updates
ls -lt /var/log/apt/history.log  # Ubuntu
ls -lt /var/log/dnf.log  # RHEL

# 7. Boot in single-user mode
# At GRUB, add 'single' or 'systemd.unit=rescue.target'
```

### Common Fixes
```bash
# Fix fstab entry
sudo nano /etc/fstab
# Comment out problematic line with #

# Repair filesystem
sudo umount /dev/sda1
sudo fsck -y /dev/sda1

# Reinstall GRUB (from live USB)
sudo mount /dev/sda1 /mnt
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo chroot /mnt
grub-install /dev/sda
update-grub
exit
sudo reboot

# Remove old kernels
sudo apt autoremove --purge  # Ubuntu
sudo dnf remove kernel-old-version  # RHEL
```

---

## Scenario 7: High CPU / Memory Usage

### Diagnostic Checklist
```bash
# 1. Check overall load
uptime
top
htop

# 2. Find CPU hogs
ps aux --sort=-%cpu | head -10

# 3. Find memory hogs
ps aux --sort=-%mem | head -10

# 4. Check for runaway processes
top -bn1 | grep -E 'PID|%CPU' | head -20

# 5. Check for zombie processes
ps aux | grep Z

# 6. Check I/O wait
iostat -x 1 10  # requires sysstat package

# 7. Check swap usage
free -h
swapon --show

# 8. Check for memory leaks
# Monitor process memory over time
watch -n 5 'ps aux | grep process_name'
```

### Common Fixes
```bash
# Kill runaway process
sudo kill <PID>
sudo kill -9 <PID>  # force kill

# Kill all instances of a process
sudo pkill -9 process_name

# Renice process (lower priority)
sudo renice -n 19 -p <PID>

# Restart service with memory leak
sudo systemctl restart service

# Clear page cache (safe)
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Check for and disable memory-hungry services
systemctl list-units --type=service --state=running
sudo systemctl disable unwanted-service
```

---

## Quick Diagnostic Commands Reference

| Issue | Commands |
|-------|----------|
| Network down | `ip a`, `ip r`, `ping 8.8.8.8`, `resolvectl status` |
| Disk full | `df -h`, `du -sh /var/*`, `lsof \| grep deleted` |
| Permission denied | `ls -l`, `stat`, `getfacl`, `lsattr` |
| Service failed | `systemctl status`, `journalctl -u service -n 50` |
| High CPU | `top`, `ps aux --sort=-%cpu` |
| High memory | `free -h`, `ps aux --sort=-%mem` |
| Can't login | `passwd -S user`, `tail /var/log/auth.log` |
| Boot failure | `journalctl -xb`, `systemctl --failed` |

---

## Tips for Effective Troubleshooting

1. **Always backup before changing configs** - `cp file file.bak`
2. **Test in safe environment first** - Use VMs, not production
3. **Read error messages carefully** - Every word matters
4. **Check recent changes** - `ls -lt /etc` shows recently modified configs
5. **Use verbose/debug modes** - `ssh -vvv`, `nginx -t`, `systemctl status`
6. **Compare working vs broken systems** - `diff config.working config.broken`
7. **Use strace for mysterious failures** - `strace -e trace=open,read program`
8. **Check system resources** - `df -h`, `free -h`, `top`
9. **Verify basics** - Is it running? Is it enabled? Is port open?
10. **Keep calm** - Panic leads to mistakes

---

**Next:** [Module 30: Capstones (Integrations)](module-30-capstones.md)

# Module 04: Permissions, ACLs, Attributes, SELinux/AppArmor

## Why it matters
File permissions control who can read, write, or execute files—the first line of defense against unauthorized access. Standard permissions have limitations, so ACLs provide fine-grained control. File attributes prevent accidental deletion, and SELinux/AppArmor enforce mandatory access control, stopping even root from doing dangerous things. This module prevents 90% of security misconfigurations.

## Prerequisites
**Packages/Tools:**
- coreutils (chmod, chown, chgrp) — pre-installed
- acl (setfacl, getfacl)
- e2fsprogs (chattr, lsattr)
- SELinux tools (RHEL/Rocky) or AppArmor (Ubuntu/SUSE)

**Files/Labs:**
- Test files and directories
- Root/sudo access

## Cheat-Sheet
- `ls -l <file>` — show permissions, owner, group
- `chmod 755 <file>` — set rwxr-xr-x (numeric)
- `chmod u+x <file>` — add execute for owner (symbolic)
- `chown user:group <file>` — change owner and group
- `umask` — default permission mask for new files
- `setfacl -m u:alice:rw file` — grant alice read-write ACL
- `getfacl <file>` — show ACLs
- `chattr +i <file>` — make file immutable (can't delete/modify)
- `lsattr <file>` — show file attributes
- `getenforce` — show SELinux mode (RHEL)
- `setenforce 0` — disable SELinux temporarily
- `aa-status` — show AppArmor status (Ubuntu/SUSE)

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== STANDARD PERMISSIONS =====
# Create test files
mkdir -p ~/labs/perms
cd ~/labs/perms
touch file1.txt
echo "secret data" > file2.txt
mkdir dir1

# View permissions
ls -l
# -rw-rw-r-- 1 user group 0 Jan 15 10:00 file1.txt
# Format: type, owner perms, group perms, other perms, links, owner, group, size, date, name

# Permission breakdown: rwxrwxrwx
# r = read (4), w = write (2), x = execute (1)
# First triplet = owner, second = group, third = others

# Numeric (octal) chmod
chmod 755 file1.txt   # rwxr-xr-x (owner: rwx, group: r-x, others: r-x)
chmod 644 file2.txt   # rw-r--r-- (owner: rw, group: r, others: r)
chmod 600 file2.txt   # rw------- (owner only)
chmod 700 dir1        # rwx------ (owner only, needed for cd into dir)

# Symbolic chmod
chmod u+x file1.txt   # add execute for user (owner)
chmod g+w file1.txt   # add write for group
chmod o-r file2.txt   # remove read for others
chmod a+r file1.txt   # add read for all (a = ugo)
chmod u=rwx,g=rx,o=rx file1.txt  # set exact permissions

# Verify
ls -l file1.txt

# Recursive chmod
chmod -R 755 dir1     # apply to dir1 and all contents

# ===== OWNERSHIP =====
# Change owner (requires sudo)
sudo chown alice file1.txt
ls -l file1.txt  # owner is now alice

# Change group
sudo chgrp developers file1.txt
ls -l file1.txt

# Change both owner and group
sudo chown alice:developers file2.txt

# Recursive chown
sudo chown -R alice:developers dir1

# Reset ownership for testing
sudo chown $(whoami):$(whoami) file1.txt file2.txt

# ===== UMASK (default permissions) =====
umask
# Output: 0002 (common default)
# New files: 666 - 002 = 664 (rw-rw-r--)
# New dirs: 777 - 002 = 775 (rwxrwxr-x)

# Set umask (temporary)
umask 0022  # new files: 644, new dirs: 755
touch newfile.txt
ls -l newfile.txt  # should be rw-r--r--

# Make umask permanent
echo "umask 0022" >> ~/.bashrc

# ===== ACCESS CONTROL LISTS (ACLs) =====
# Install ACL tools (usually pre-installed)
sudo apt install acl

# Grant user alice read-write access (without changing group)
setfacl -m u:alice:rw file1.txt

# View ACLs
getfacl file1.txt
# Output includes: user:alice:rw-

# Grant group developers read-execute
setfacl -m g:developers:rx dir1

# Remove ACL for alice
setfacl -x u:alice file1.txt

# Remove all ACLs
setfacl -b file1.txt

# Default ACLs (inherited by new files in directory)
setfacl -d -m u:alice:rw dir1   # new files in dir1 get alice:rw
touch dir1/newfile
getfacl dir1/newfile  # should show alice:rw

# Recursive ACL
setfacl -R -m u:alice:r dir1  # apply to dir1 and all contents

# ===== FILE ATTRIBUTES =====
# Install tools (usually pre-installed)
sudo apt install e2fsprogs

# Make file immutable (can't delete, rename, or modify)
sudo chattr +i file1.txt
echo "test" >> file1.txt  # fails with "Operation not permitted"
rm file1.txt              # fails

# Remove immutable
sudo chattr -i file1.txt
echo "test" >> file1.txt  # now works

# Append-only (can append but not delete or modify existing content)
sudo chattr +a file2.txt
echo "new line" >> file2.txt  # works
echo "replace" > file2.txt    # fails
rm file2.txt                  # fails
sudo chattr -a file2.txt      # remove attribute

# View attributes
lsattr file1.txt
# Output: --------------e----- file1.txt (e = extent format, normal)

# Other useful attributes:
# +A = don't update access time (performance)
# +d = no dump (skip in backups)

# ===== APPARMOR (Ubuntu default) =====
# Check status
sudo aa-status
# Shows loaded profiles and enforcement mode

# AppArmor profiles in /etc/apparmor.d/
ls /etc/apparmor.d/

# Example: nginx profile
sudo cat /etc/apparmor.d/usr.sbin.nginx

# Set profile to complain mode (log violations, don't block)
sudo aa-complain /usr/sbin/nginx

# Set profile to enforce mode
sudo aa-enforce /usr/sbin/nginx

# Disable profile
sudo ln -s /etc/apparmor.d/usr.sbin.nginx /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.nginx

# View logs
sudo grep -i apparmor /var/log/syslog

# ===== SELINUX (not default on Ubuntu, but installable) =====
# Ubuntu uses AppArmor by default, but SELinux can be installed
# See RHEL/Rocky section for full SELinux usage
```

### RHEL/Rocky
```bash
# ===== STANDARD PERMISSIONS (same as Ubuntu) =====
mkdir -p ~/labs/perms
cd ~/labs/perms
touch file1.txt file2.txt
mkdir dir1

chmod 755 file1.txt
chmod 600 file2.txt
chown alice:developers file1.txt  # requires sudo
umask 0022

# ===== ACLs (same as Ubuntu) =====
sudo dnf install acl  # if not installed
setfacl -m u:alice:rw file1.txt
getfacl file1.txt
setfacl -b file1.txt

# ===== FILE ATTRIBUTES (same as Ubuntu) =====
sudo chattr +i file1.txt
lsattr file1.txt
sudo chattr -i file1.txt

# ===== SELINUX (RHEL default) =====
# Check SELinux status
getenforce
# Output: Enforcing, Permissive, or Disabled

sestatus
# Shows: current mode, config file mode, policy version

# SELinux modes:
# Enforcing = blocks violations
# Permissive = logs violations but allows them
# Disabled = SELinux off (requires reboot to enable)

# Temporarily set to permissive (until reboot)
sudo setenforce 0
getenforce  # should show Permissive

# Temporarily set to enforcing
sudo setenforce 1
getenforce  # should show Enforcing

# Permanently change mode (requires reboot)
sudo nano /etc/selinux/config
# Set: SELINUX=enforcing (or permissive or disabled)
# Reboot required: sudo reboot

# View file SELinux context
ls -Z file1.txt
# Output: unconfined_u:object_r:user_home_t:s0 file1.txt
# Format: user:role:type:level

# Change context (restorecon restores default context)
sudo restorecon file1.txt

# Set custom context
sudo chcon -t httpd_sys_content_t file1.txt
ls -Z file1.txt

# Restore default context
sudo restorecon -v file1.txt

# Recursive context change
sudo chcon -R -t httpd_sys_content_t /var/www/html

# SELinux booleans (toggleable policies)
getsebool -a | grep httpd  # show all httpd-related booleans
getsebool httpd_can_network_connect  # check specific boolean

# Enable boolean temporarily
sudo setsebool httpd_can_network_connect on

# Enable permanently
sudo setsebool -P httpd_can_network_connect on

# Troubleshoot denials
sudo grep -i 'avc.*denied' /var/log/audit/audit.log
# Shows what SELinux blocked

# Generate policy from denials (audit2allow)
sudo grep nginx /var/log/audit/audit.log | audit2allow -M mynginx
# Creates mynginx.pp policy module

# Load policy module
sudo semodule -i mynginx.pp

# List loaded modules
sudo semodule -l

# Useful commands:
# audit2why = explain why SELinux denied (requires policycoreutils-python-utils)
sudo dnf install policycoreutils-python-utils
sudo grep -i denied /var/log/audit/audit.log | audit2why
```

### SUSE
```bash
# ===== STANDARD PERMISSIONS (same as Ubuntu/RHEL) =====
mkdir -p ~/labs/perms
cd ~/labs/perms
touch file1.txt
chmod 644 file1.txt
sudo chown alice:developers file1.txt

# ===== ACLs =====
sudo zypper install acl
setfacl -m u:alice:rw file1.txt
getfacl file1.txt

# ===== FILE ATTRIBUTES =====
sudo chattr +i file1.txt
lsattr file1.txt
sudo chattr -i file1.txt

# ===== APPARMOR (SUSE default) =====
# Check status
sudo aa-status

# Profiles location
ls /etc/apparmor.d/

# Set to complain mode
sudo aa-complain /usr/sbin/nginx

# Set to enforce mode
sudo aa-enforce /usr/sbin/nginx

# Reload all profiles
sudo systemctl reload apparmor

# View logs
sudo grep -i apparmor /var/log/messages
```

---

## Verify
```bash
# Create test file
touch testfile.txt
ls -l testfile.txt
# Expected: -rw-rw-r-- or similar

# Change permissions
chmod 600 testfile.txt
ls -l testfile.txt
# Expected: -rw-------

# Test ACL
setfacl -m u:$(whoami):rwx testfile.txt
getfacl testfile.txt | grep user
# Expected: user::rw- and user:<yourname>:rwx

# Test immutable attribute
sudo chattr +i testfile.txt
echo "test" >> testfile.txt 2>&1 | grep -i "not permitted"
# Expected: Operation not permitted
sudo chattr -i testfile.txt

# Cleanup
rm testfile.txt
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `chmod: changing permissions: Operation not permitted` | File is immutable or not owner | Check `lsattr`; remove `+i` with `chattr -i` or use sudo |
| `Permission denied` when accessing file | No read permission | `chmod +r <file>` or check ACLs with `getfacl` |
| Can't cd into directory | No execute permission on dir | `chmod +x <dir>` |
| ACL changes not working | Filesystem not mounted with ACL support | Check `mount | grep acl`; remount with `acl` option or add to /etc/fstab |
| SELinux blocks legitimate app | Wrong context or boolean | Use `ausearch -m avc -ts recent` then `audit2allow` to create policy |
| AppArmor blocks app | Profile too restrictive | Set to complain mode or edit profile in /etc/apparmor.d/ |

---

## Cleanup
```bash
cd ~
rm -rf ~/labs/perms
```

---

## Quick Quiz

1. What does `chmod 755` mean in rwx notation?
2. What's the difference between `chmod u+x` and `chmod a+x`?
3. How do you make a file read-only for everyone except the owner?
4. What command prevents a file from being deleted, even by root?
5. What's the difference between SELinux Enforcing and Permissive modes?

---

**Next:** [Module 05: Processes, Jobs, and Systemd](module-05-processes-systemd.md)

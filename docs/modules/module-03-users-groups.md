# Module 03: Users, Groups, Identity & Access

## Why it matters
User and group management is the foundation of Linux security. Every process runs as a user, every file is owned by a user and group, and access control starts here. Understanding sudo, PAM, and password policies prevents unauthorized access and enables least-privilege setups.

## Prerequisites
**Packages/Tools:**
- shadow-utils (useradd, usermod, passwd, etc.) — pre-installed
- sudo — usually pre-installed
- PAM (Pluggable Authentication Modules) — pre-installed

**Files/Labs:**
- Root or sudo access required
- Practice VM (don't experiment on production!)

## Cheat-Sheet
- `useradd <user>` — create user (low-level)
- `adduser <user>` — create user (interactive, Debian/Ubuntu)
- `usermod -aG <group> <user>` — add user to group
- `passwd <user>` — set/change password
- `userdel -r <user>` — delete user and home directory
- `groupadd <group>` — create group
- `groups <user>` — show user's groups
- `id <user>` — show UID, GID, and groups
- `sudo <command>` — run command as root
- `visudo` — safely edit /etc/sudoers
- `su - <user>` — switch to user with login shell
- `whoami` — show current username

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== CREATE USERS =====
# Method 1: useradd (low-level, all distros)
sudo useradd alice
# Creates user but no home directory, no password

# Set password
sudo passwd alice
# Enter password twice

# Create home directory manually
sudo mkdir /home/alice
sudo chown alice:alice /home/alice
sudo cp -r /etc/skel/. /home/alice/  # copy default dotfiles

# Method 2: adduser (Debian/Ubuntu, interactive)
sudo adduser bob
# Prompts for password, full name, phone, etc.
# Automatically creates home dir and copies /etc/skel

# ===== VIEW USER INFO =====
id alice
# Output: uid=1001(alice) gid=1001(alice) groups=1001(alice)

grep alice /etc/passwd
# alice:x:1001:1001::/home/alice:/bin/bash
# Format: username:x:UID:GID:comment:home:shell

grep alice /etc/shadow  # requires sudo
# alice:$6$encrypted...:19745:0:99999:7:::
# Contains encrypted password and aging info

# ===== MODIFY USERS =====
# Change shell
sudo usermod -s /bin/zsh alice

# Add to group (append mode, important!)
sudo usermod -aG sudo alice     # add to sudo group (admin access)
sudo usermod -aG developers bob # add to custom group

# Change home directory
sudo usermod -d /opt/alice -m alice  # -m moves contents

# Lock/unlock account
sudo usermod -L alice  # lock (disable password login)
sudo usermod -U alice  # unlock

# Set expiration date
sudo usermod -e 2024-12-31 alice  # account expires on date

# ===== GROUPS =====
# Create group
sudo groupadd developers

# View group
grep developers /etc/group
# developers:x:1003:

# Add user to group (alternative to usermod)
sudo gpasswd -a bob developers

# Remove user from group
sudo gpasswd -d bob developers

# List all groups
cat /etc/group | cut -d: -f1

# Show user's groups
groups alice
id alice

# Change primary group (careful!)
sudo usermod -g developers alice  # primary group now developers, not alice

# ===== PASSWORD MANAGEMENT =====
# Change password (as user)
passwd
# Old password, new password, confirm

# Change another user's password (as root)
sudo passwd bob

# Force password change on next login
sudo chage -d 0 alice

# Set password expiration
sudo chage -M 90 alice    # password expires after 90 days
sudo chage -m 7 alice     # minimum 7 days between changes
sudo chage -W 14 alice    # warn 14 days before expiration

# View password aging info
sudo chage -l alice

# Lock user (prevents login)
sudo passwd -l alice
# Unlock
sudo passwd -u alice

# ===== SUDO CONFIGURATION =====
# View sudoers file (NEVER edit directly!)
sudo cat /etc/sudoers

# Safely edit sudoers
sudo visudo
# Opens editor with syntax checking

# Common sudoers patterns:
# Allow user to run all commands with password:
# alice ALL=(ALL:ALL) ALL

# Allow user to run specific commands without password:
# bob ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx

# Allow group to run all commands:
# %developers ALL=(ALL:ALL) ALL

# Test sudo access (as alice)
su - alice
sudo whoami  # should print "root"
exit

# View sudo logs
sudo grep sudo /var/log/auth.log

# ===== PAM BASICS =====
# PAM configs control authentication
ls /etc/pam.d/
cat /etc/pam.d/common-auth     # authentication rules
cat /etc/pam.d/common-password # password rules
cat /etc/pam.d/sudo            # sudo-specific auth

# Example: enforce strong passwords
sudo apt install libpam-pwquality
sudo nano /etc/security/pwquality.conf
# Uncomment/set: minlen = 12, dcredit = -1, ucredit = -1

# ===== DELETE USERS =====
# 🚨 DANGER: This removes user and home directory
sudo userdel -r alice  # -r removes home directory
sudo userdel bob       # without -r, keeps home directory

# Verify deletion
id alice  # should show "no such user"
ls /home  # alice directory should be gone
```

### RHEL/Rocky
```bash
# ===== CREATE USERS =====
# RHEL uses useradd (no adduser interactive tool)
sudo useradd alice
sudo passwd alice

# Create with home directory and default shell
sudo useradd -m -s /bin/bash bob
sudo passwd bob

# Create system user (UID < 1000, no home, no login)
sudo useradd -r -s /usr/sbin/nologin nginx-user

# ===== VIEW USER INFO =====
id alice
grep alice /etc/passwd
sudo grep alice /etc/shadow

# ===== MODIFY USERS =====
sudo usermod -aG wheel alice  # "wheel" group for sudo on RHEL
sudo usermod -s /bin/bash alice

# ===== GROUPS =====
sudo groupadd developers
sudo usermod -aG developers bob
groups bob

# ===== PASSWORD MANAGEMENT =====
sudo passwd bob
sudo chage -M 90 -m 7 -W 14 alice
sudo chage -l alice

# ===== SUDO CONFIGURATION =====
# RHEL uses wheel group for sudo
grep wheel /etc/group
# Ensure alice is in wheel group
sudo usermod -aG wheel alice

# Edit sudoers
sudo visudo

# Sudoers includes: %wheel ALL=(ALL) ALL

# View sudo logs
sudo grep sudo /var/log/secure

# ===== PAM =====
ls /etc/pam.d/
cat /etc/pam.d/system-auth
cat /etc/pam.d/password-auth

# Enforce strong passwords
sudo dnf install libpwquality
sudo authselect select sssd with-pwquality --force
sudo nano /etc/security/pwquality.conf
# Set: minlen=12, dcredit=-1, ucredit=-1

# ===== DELETE USERS =====
sudo userdel -r alice
```

### SUSE
```bash
# ===== CREATE USERS =====
sudo useradd -m alice
sudo passwd alice

# SUSE has YaST for GUI user management (but we use CLI)
# which yast2  # /usr/sbin/yast2

# ===== MODIFY USERS =====
sudo usermod -aG wheel alice  # wheel group for sudo

# ===== GROUPS =====
sudo groupadd developers
sudo usermod -aG developers alice

# ===== PASSWORD MANAGEMENT =====
sudo passwd alice
sudo chage -M 90 alice

# ===== SUDO =====
sudo visudo
# Ensure: %wheel ALL=(ALL) ALL

# ===== PAM =====
cat /etc/pam.d/common-auth
sudo zypper install pam-config
# pam-config --query --pwquality

# ===== DELETE USERS =====
sudo userdel -r alice
```

---

## Verify
```bash
# Create test user
sudo useradd -m testuser
sudo passwd testuser  # set password

# Verify user exists
id testuser
# Expected: uid=XXXX(testuser) gid=XXXX(testuser) groups=XXXX(testuser)

grep testuser /etc/passwd
# Expected: testuser:x:XXXX:XXXX::/home/testuser:/bin/bash

# Test sudo access
sudo usermod -aG sudo testuser  # or wheel on RHEL/SUSE
su - testuser
sudo whoami
# Expected: root (enter password when prompted)
exit

# Cleanup test user
sudo userdel -r testuser
id testuser
# Expected: no such user
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `useradd: user already exists` | User created previously | Use `usermod` to modify or `userdel` to remove first |
| User can't sudo | Not in sudo/wheel group | `sudo usermod -aG sudo <user>` (Ubuntu) or `wheel` (RHEL/SUSE) |
| `visudo: syntax error` | Invalid sudoers syntax | visudo won't save; fix the error shown |
| `su: Authentication failure` | Wrong password or user locked | Check `sudo passwd -S <user>` for lock status |
| No home directory created | Used `useradd` without `-m` | Create manually or use `usermod -d /home/user -m user` |
| Changes not taking effect | User still logged in | User must logout and login again for group changes |

---

## Cleanup
```bash
# If you created test users
sudo userdel -r alice 2>/dev/null
sudo userdel -r bob 2>/dev/null
sudo groupdel developers 2>/dev/null
```

---

## Quick Quiz

1. What's the difference between `useradd` and `adduser` on Ubuntu?
2. How do you add a user to the sudo group without removing them from other groups?
3. What command shows all groups a user belongs to?
4. What file stores encrypted passwords?
5. Why should you never edit /etc/sudoers directly with a text editor?

---

**Next:** [Module 04: Permissions, ACLs, Attributes, SELinux/AppArmor](module-04-permissions-acls.md)

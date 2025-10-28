# Module 17: SSH & Remote Admin

## Why it matters
SSH is how you manage remote servers. Proper SSH configuration prevents unauthorized access while key-based authentication eliminates password weaknesses. Understanding SSH keys, config files, tunnels, and jump hosts is essential for secure remote administration.

## Prerequisites
**Packages/Tools:**
- openssh-client — pre-installed
- openssh-server — install on remote systems

**Files/Labs:**
- Access to a remote Linux system (or second VM)
- Root/sudo access

## Cheat-Sheet
- `ssh user@host` — connect to remote host
- `ssh-keygen` — generate SSH key pair
- `ssh-copy-id user@host` — copy public key to remote
- `scp file user@host:/path` — secure copy file
- `ssh -L 8080:localhost:80 user@host` — local port forward
- `ssh -J jump@host user@target` — connect via jump host
- `ssh -i ~/.ssh/key user@host` — use specific private key

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== SSH CLIENT BASICS =====
# Connect to remote host
ssh user@192.168.1.100
ssh user@example.com

# Connect on non-standard port
ssh -p 2222 user@host

# Run single command
ssh user@host 'ls -la /var/log'

# Run multiple commands
ssh user@host 'uname -a && df -h'

# ===== SSH KEYS (passwordless authentication) =====
# Generate SSH key pair
ssh-keygen -t ed25519 -C "your_email@example.com"
# Press Enter for default location (~/.ssh/id_ed25519)
# Enter passphrase (optional but recommended)

# Generate RSA key (if ed25519 not supported)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# View public key
cat ~/.ssh/id_ed25519.pub

# Copy public key to remote server
ssh-copy-id user@remote
# Enter password one last time

# Test passwordless login
ssh user@remote
# Should not ask for password (may ask for key passphrase)

# Manual copy (if ssh-copy-id unavailable)
cat ~/.ssh/id_ed25519.pub | ssh user@remote "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# ===== SSH CONFIG FILE =====
# Create/edit SSH config
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/config

# Add host shortcuts:
# Host myserver
#   HostName 192.168.1.100
#   User admin
#   Port 22
#   IdentityFile ~/.ssh/id_ed25519
#
# Host jump
#   HostName jump.example.com
#   User jumpuser
#
# Host internal
#   HostName 10.0.1.50
#   User admin
#   ProxyJump jump

chmod 600 ~/.ssh/config

# Now connect with shortcut
ssh myserver  # instead of ssh admin@192.168.1.100

# ===== SSH AGENT (manage keys) =====
# Start ssh-agent (usually auto-started)
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519
# Enter passphrase once

# List loaded keys
ssh-add -l

# Remove key from agent
ssh-add -d ~/.ssh/id_ed25519

# Remove all keys
ssh-add -D

# ===== SSH SERVER SETUP =====
# Install SSH server
sudo apt install openssh-server

# Start SSH service
sudo systemctl start ssh
sudo systemctl enable ssh

# Check status
sudo systemctl status ssh

# Check SSH is listening
ss -tulnp | grep :22

# ===== SSH SERVER HARDENING =====
# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Recommended hardening settings:
# Port 22  # or change to non-standard like 2222
# PermitRootLogin no  # disable root login
# PasswordAuthentication no  # require keys only
# PubkeyAuthentication yes
# ChallengeResponseAuthentication no
# UsePAM yes
# X11Forwarding no  # unless needed
# MaxAuthTries 3
# MaxSessions 2
# AllowUsers alice bob  # whitelist users
# AllowGroups sshusers

# Test config syntax
sudo sshd -t

# Reload SSH service
sudo systemctl reload ssh

# ===== SSH PORT FORWARDING =====
# Local port forward (access remote service locally)
# Forward local port 8080 to remote localhost:80
ssh -L 8080:localhost:80 user@remote
# Now browse http://localhost:8080 (accesses remote:80)

# Access remote MySQL
ssh -L 3306:localhost:3306 user@remote
# Connect to localhost:3306 (actually remote MySQL)

# Remote port forward (expose local service to remote)
ssh -R 8080:localhost:80 user@remote
# Remote users can access your localhost:80 via remote:8080

# Dynamic port forward (SOCKS proxy)
ssh -D 1080 user@remote
# Set browser SOCKS5 proxy to localhost:1080

# ===== JUMP HOST / BASTION =====
# Connect through jump host (method 1: ProxyJump)
ssh -J jump@bastion.com user@internal.server

# Connect through multiple jumps
ssh -J jump1@host1,jump2@host2 user@target

# Using ProxyCommand (older method)
ssh -o ProxyCommand="ssh -W %h:%p jump@bastion" user@internal

# Or in ~/.ssh/config:
# Host internal
#   HostName 10.0.1.50
#   User admin
#   ProxyJump jump@bastion.com

ssh internal  # automatically jumps through bastion

# ===== SCP & SFTP =====
# Copy file to remote
scp file.txt user@remote:/path/to/destination/

# Copy file from remote
scp user@remote:/path/to/file.txt ./

# Copy directory (recursive)
scp -r /local/dir user@remote:/remote/dir/

# Copy through jump host
scp -J jump@bastion file.txt user@internal:/path/

# SFTP (interactive file transfer)
sftp user@remote
# sftp> ls
# sftp> cd /var/www
# sftp> get file.txt
# sftp> put localfile.txt
# sftp> mkdir newdir
# sftp> quit

# ===== RSYNC OVER SSH =====
# Sync directory to remote
rsync -avz /local/dir/ user@remote:/remote/dir/
# -a = archive, -v = verbose, -z = compress

# Sync from remote
rsync -avz user@remote:/remote/dir/ /local/dir/

# Sync with delete (mirror)
rsync -avz --delete /local/dir/ user@remote:/remote/dir/

# Dry run (test without changes)
rsync -avz --dry-run /local/dir/ user@remote:/remote/dir/

# Through jump host
rsync -avz -e "ssh -J jump@bastion" /local/ user@internal:/remote/

# ===== SSH TUNNELING (keep alive) =====
# Keep SSH tunnel alive
ssh -N -L 8080:localhost:80 user@remote
# -N = no command (just tunnel)

# Background tunnel
ssh -fN -L 8080:localhost:80 user@remote
# -f = background

# ===== SSH MULTIPLEXING (reuse connections) =====
# Add to ~/.ssh/config:
# Host *
#   ControlMaster auto
#   ControlPath ~/.ssh/cm-%r@%h:%p
#   ControlPersist 10m

# First connection creates master
ssh user@remote

# Subsequent connections reuse master (instant, no auth)
ssh user@remote  # instant!

# ===== DEBUGGING SSH =====
# Verbose output
ssh -v user@remote
ssh -vv user@remote  # more verbose
ssh -vvv user@remote  # maximum verbosity

# View server logs
sudo tail -f /var/log/auth.log  # Ubuntu
sudo tail -f /var/log/secure    # RHEL

# Check SSH connectivity without login
nc -zv remote 22
telnet remote 22
```

### RHEL/Rocky
```bash
# ===== INSTALL & START SSH =====
sudo dnf install openssh-server
sudo systemctl start sshd
sudo systemctl enable sshd

# ===== FIREWALL (allow SSH) =====
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload

# ===== SELINUX (if using non-standard port) =====
# Allow SSH on port 2222
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo firewall-cmd --add-port=2222/tcp --permanent
sudo firewall-cmd --reload

# ===== CONFIG & HARDENING (same as Ubuntu) =====
sudo nano /etc/ssh/sshd_config
# (same settings)
sudo systemctl reload sshd

# ===== LOGS =====
sudo tail -f /var/log/secure
```

### SUSE
```bash
# ===== INSTALL SSH =====
sudo zypper install openssh

sudo systemctl start sshd
sudo systemctl enable sshd

# ===== FIREWALL =====
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload

# ===== CONFIG (same) =====
sudo nano /etc/ssh/sshd_config
sudo systemctl reload sshd
```

---

## Verify
```bash
# Check SSH service running
sudo systemctl status ssh  # or sshd

# Check SSH listening
ss -tulnp | grep :22
# Expected: LISTEN on port 22

# Test SSH to localhost
ssh localhost
# Should connect (may need to accept fingerprint)

# Verify key authentication
ssh -v user@remote 2>&1 | grep "Offering public key"
# Should show key being offered
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Permission denied (publickey)` | Key not on server or wrong permissions | Check `~/.ssh/authorized_keys` permissions (600); directory (700) |
| `Connection refused` | SSH not running or firewall blocking | `sudo systemctl start sshd`; allow port 22 in firewall |
| `Too many authentication failures` | Too many keys in ssh-agent | Use `ssh -o IdentitiesOnly=yes -i keyfile` |
| `Bad owner or permissions` on config | ~/.ssh/config world-writable | `chmod 600 ~/.ssh/config` |
| Can't connect after hardening | Locked yourself out | Boot rescue, edit /etc/ssh/sshd_config |
| `Host key verification failed` | Server reinstalled or MITM | Remove old key: `ssh-keygen -R hostname` |

---

## Cleanup
```bash
# Remove test keys (if created)
# rm ~/.ssh/id_ed25519_test*

# Close SSH tunnels
pkill -f "ssh.*8080:localhost"
```

---

## Quick Quiz

1. How do you generate an Ed25519 SSH key pair?
2. What file on the remote server stores authorized public keys?
3. How do you forward local port 8080 to remote port 80?
4. What's the purpose of a jump host?
5. How do you disable password authentication in SSH?

---

**Next:** [Module 18: Task Scheduling](module-18-task-scheduling.md)

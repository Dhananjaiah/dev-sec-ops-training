# Module 30: Capstones (Integrations)

## Why it matters
Capstone projects integrate everything you've learned into real-world scenarios. Each project simulates production tasks: securing a web server, building a file server, or deploying VMs with automation. Completing these proves you can architect, implement, and troubleshoot complete systems—not just run individual commands.

## Prerequisites
- **Completion of Modules 1-29** (or strong Linux foundation)
- Multiple VMs or cloud instances
- Root/sudo access
- Time: 2-4 hours per capstone

---

## Capstone 1: Hardened Web + Database Server

### Objective
Deploy a secure web server (nginx) with MySQL database, TLS encryption, firewall rules, automated backups, and monitoring.

### Requirements
1. Install and configure nginx with PHP-FPM
2. Install and secure MySQL database
3. Generate self-signed TLS certificate
4. Configure firewall (allow only HTTP/HTTPS/SSH)
5. Set up daily automated database backups
6. Configure log rotation
7. Implement basic monitoring (disk space, service health)
8. Harden SSH (key-only authentication, non-standard port)
9. Enable SELinux/AppArmor policies
10. Document everything

### Implementation Steps

#### Ubuntu/Debian
```bash
# ===== STEP 1: SYSTEM PREPARATION =====
# Update system
sudo apt update && sudo apt upgrade -y

# Set hostname
sudo hostnamectl set-hostname webserver.lab.local

# Configure timezone
sudo timedatectl set-timezone America/New_York

# ===== STEP 2: INSTALL WEB STACK =====
# Install nginx, PHP, MySQL
sudo apt install -y nginx php-fpm php-mysql mariadb-server

# Start services
sudo systemctl enable --now nginx
sudo systemctl enable --now php8.1-fpm  # adjust version
sudo systemctl enable --now mariadb

# Verify services running
systemctl status nginx php8.1-fpm mariadb

# ===== STEP 3: SECURE MYSQL =====
# Run security script
sudo mysql_secure_installation
# Set root password, remove anonymous users, disallow root remote login

# Create database and user
sudo mysql <<EOF
CREATE DATABASE webapp_db;
CREATE USER 'webapp_user'@'localhost' IDENTIFIED BY 'SecurePassword123!';
GRANT ALL PRIVILEGES ON webapp_db.* TO 'webapp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Verify
sudo mysql -u webapp_user -p -e "SHOW DATABASES;"

# ===== STEP 4: CONFIGURE NGINX =====
# Create web directory
sudo mkdir -p /var/www/webapp
sudo chown -R www-data:www-data /var/www/webapp

# Create test PHP file
sudo tee /var/www/webapp/index.php <<'EOF'
<?php
phpinfo();
?>
EOF

# Create nginx config
sudo tee /etc/nginx/sites-available/webapp <<'EOF'
server {
    listen 80;
    server_name webserver.lab.local;
    root /var/www/webapp;
    index index.php index.html;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # remove default site

# Test config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Test
curl http://localhost

# ===== STEP 5: TLS/SSL CERTIFICATE =====
# Generate self-signed certificate (1 year validity)
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/webapp.key \
  -out /etc/nginx/ssl/webapp.crt \
  -subj "/C=US/ST=State/L=City/O=Org/CN=webserver.lab.local"

# Update nginx config for HTTPS
sudo tee /etc/nginx/sites-available/webapp <<'EOF'
server {
    listen 80;
    server_name webserver.lab.local;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name webserver.lab.local;
    root /var/www/webapp;
    index index.php index.html;

    ssl_certificate /etc/nginx/ssl/webapp.crt;
    ssl_certificate_key /etc/nginx/ssl/webapp.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
}
EOF

# Reload nginx
sudo nginx -t
sudo systemctl reload nginx

# Test HTTPS
curl -k https://localhost

# ===== STEP 6: FIREWALL =====
# Enable UFW
sudo ufw --force enable

# Allow SSH (change to custom port later)
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Deny all other incoming
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Verify
sudo ufw status verbose

# ===== STEP 7: SSH HARDENING =====
# Generate SSH key pair (on client machine)
# ssh-keygen -t ed25519 -C "admin@webserver"
# ssh-copy-id user@webserver

# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edit SSH config
sudo nano /etc/ssh/sshd_config
# Port 2222
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes

# Update firewall for new SSH port
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp

# Test SSH config
sudo sshd -t

# Reload SSH
sudo systemctl reload sshd

# Test new port (from another terminal)
# ssh -p 2222 user@webserver

# ===== STEP 8: AUTOMATED BACKUPS =====
# Create backup script
sudo tee /usr/local/bin/backup-mysql.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# Dump all databases
mysqldump -u root --all-databases --single-transaction | gzip > "$BACKUP_DIR/all_databases_$DATE.sql.gz"

# Delete backups older than 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: all_databases_$DATE.sql.gz"
EOF

sudo chmod +x /usr/local/bin/backup-mysql.sh

# Test backup
sudo /usr/local/bin/backup-mysql.sh
ls -lh /var/backups/mysql/

# Schedule with cron (daily at 2 AM)
echo "0 2 * * * /usr/local/bin/backup-mysql.sh >> /var/log/mysql-backup.log 2>&1" | sudo crontab -

# Or with systemd timer
sudo tee /etc/systemd/system/mysql-backup.service <<'EOF'
[Unit]
Description=MySQL Backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-mysql.sh
EOF

sudo tee /etc/systemd/system/mysql-backup.timer <<'EOF'
[Unit]
Description=MySQL Backup Timer

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mysql-backup.timer
systemctl list-timers

# ===== STEP 9: LOG ROTATION =====
# Nginx logs already rotated by default
cat /etc/logrotate.d/nginx

# Create custom log rotation
sudo tee /etc/logrotate.d/mysql-backup <<'EOF'
/var/log/mysql-backup.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF

# ===== STEP 10: MONITORING =====
# Create monitoring script
sudo tee /usr/local/bin/health-check.sh <<'EOF'
#!/bin/bash
EMAIL="admin@example.com"

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "ALERT: Disk usage is ${DISK_USAGE}%" | mail -s "Disk Alert" "$EMAIL"
fi

# Check services
for service in nginx mariadb php8.1-fpm; do
    if ! systemctl is-active --quiet "$service"; then
        echo "ALERT: $service is down" | mail -s "Service Alert: $service" "$EMAIL"
    fi
done
EOF

sudo chmod +x /usr/local/bin/health-check.sh

# Run every 15 minutes
echo "*/15 * * * * /usr/local/bin/health-check.sh" | sudo crontab -

# ===== STEP 11: APPARMOR (Ubuntu) =====
# Check AppArmor status
sudo aa-status

# Nginx and MySQL should have profiles loaded
# If not, enable them:
sudo aa-enforce /etc/apparmor.d/usr.sbin.nginx

# ===== STEP 12: DOCUMENTATION =====
# Create documentation file
sudo tee /root/webserver-setup.md <<'EOF'
# Web Server Documentation

## Services
- Nginx: HTTPS on port 443, HTTP redirects to HTTPS
- MariaDB: localhost only, port 3306
- PHP-FPM: socket /run/php/php8.1-fpm.sock

## Firewall
- SSH: port 2222 (key-only authentication)
- HTTP: port 80 (redirects to HTTPS)
- HTTPS: port 443

## Backups
- Location: /var/backups/mysql/
- Schedule: Daily at 2 AM
- Retention: 7 days

## TLS Certificate
- Location: /etc/nginx/ssl/
- Type: Self-signed
- Expiry: 1 year from creation

## Monitoring
- Health checks: every 15 minutes
- Checks: disk space (80% threshold), service status

## Recovery Procedures
1. MySQL restore: `gunzip < backup.sql.gz | mysql -u root`
2. Nginx config test: `nginx -t`
3. View logs: `journalctl -u nginx`, `tail /var/log/mysql/error.log`
EOF
```

### Verification Checklist
```bash
# ✅ Nginx serving HTTPS
curl -k https://localhost

# ✅ HTTP redirects to HTTPS
curl -I http://localhost

# ✅ MySQL accessible
sudo mysql -u webapp_user -p -e "SELECT 1;"

# ✅ Firewall active
sudo ufw status

# ✅ SSH on custom port
ss -tuln | grep 2222

# ✅ Backup script works
sudo /usr/local/bin/backup-mysql.sh
ls /var/backups/mysql/

# ✅ Services enabled
systemctl is-enabled nginx mariadb php8.1-fpm

# ✅ AppArmor profiles loaded
sudo aa-status | grep -E 'nginx|mysql'
```

---

## Capstone 2: NFS + Samba File Server with Quotas

### Objective
Build a multi-protocol file server with NFS (Linux clients) and Samba (Windows clients), user quotas, LVM snapshots, and automated backups.

### Requirements
1. Configure LVM for flexible storage
2. Set up NFS shares with proper permissions
3. Set up Samba shares with user authentication
4. Implement user quotas
5. Schedule LVM snapshots
6. Configure firewall rules
7. Set up rsync backups to remote server
8. Document share access and troubleshooting

### Implementation (Brief Overview)
```bash
# 1. LVM setup (Module 08)
sudo pvcreate /dev/sdb
sudo vgcreate vg_fileserver /dev/sdb
sudo lvcreate -L 50G -n lv_data vg_fileserver
sudo mkfs.ext4 /dev/vg_fileserver/lv_data

# 2. Mount and enable quotas
sudo mkdir /srv/fileserver
sudo mount /dev/vg_fileserver/lv_data /srv/fileserver
# Add to /etc/fstab with usrquota,grpquota

# 3. NFS setup
sudo apt install nfs-kernel-server
sudo mkdir /srv/fileserver/nfs_share
# Configure /etc/exports
# /srv/fileserver/nfs_share 192.168.1.0/24(rw,sync,no_subtree_check)

# 4. Samba setup
sudo apt install samba
# Configure /etc/samba/smb.conf
# Create Samba users

# 5. Quotas (Module 07)
sudo apt install quota
sudo quotacheck -cugm /srv/fileserver
sudo setquota -u alice 10000000 12000000 0 0 /srv/fileserver

# 6. Firewall
sudo ufw allow from 192.168.1.0/24 to any port 2049 # NFS
sudo ufw allow from 192.168.1.0/24 to any port 139,445 # Samba

# 7. LVM snapshots (daily via cron)
sudo lvcreate -L 5G -s -n lv_data_snap /dev/vg_fileserver/lv_data

# 8. Rsync backups
rsync -avz --delete /srv/fileserver/ remote:/backups/
```

---

## Capstone 3: KVM Host + Ansible Provisioning

### Objective
Set up KVM virtualization host, create 2 VMs using cloud-init, and provision them with Ansible.

### Requirements
1. Install KVM/libvirt on host
2. Create virtual network with NAT
3. Create 2 VMs with cloud-init (Ubuntu)
4. Configure Ansible inventory
5. Write playbook to:
   - Update packages
   - Install nginx
   - Configure firewall
   - Deploy simple web page
6. Verify VMs accessible via SSH
7. Document VM management procedures

### Implementation (Brief Overview)
```bash
# 1. Install KVM (Module 22)
sudo apt install qemu-kvm libvirt-daemon-system virtinst

# 2. Create VMs with virt-install
virt-install --name vm1 --memory 2048 --vcpus 2 --disk size=20 \
  --cdrom ubuntu-22.04.iso --network network=default

# 3. Ansible inventory
cat > inventory.ini <<EOF
[webservers]
vm1 ansible_host=192.168.122.10
vm2 ansible_host=192.168.122.11
EOF

# 4. Ansible playbook
cat > webserver.yml <<EOF
---
- hosts: webservers
  become: yes
  tasks:
    - name: Update packages
      apt:
        update_cache: yes
        upgrade: dist
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Start nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
EOF

# 5. Run playbook
ansible-playbook -i inventory.ini webserver.yml
```

---

## Success Criteria

For each capstone, you should be able to:

### Capstone 1
- Browse to https://webserver and see PHP info page
- Show firewall rules allow only necessary ports
- Demonstrate backup script runs and creates files
- SSH with key authentication on custom port
- Explain each security measure implemented

### Capstone 2
- Mount NFS share from Linux client
- Access Samba share from Windows client
- Show user quotas in effect
- Create and restore from LVM snapshot
- Demonstrate backup to remote server

### Capstone 3
- List running VMs with `virsh list`
- SSH into both VMs
- Show nginx running on both VMs (via Ansible)
- Execute Ansible playbook to update configuration
- Snapshot and restore a VM

---

## Troubleshooting Guide

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Can't connect to HTTPS | Check firewall: `sudo ufw status`; verify nginx: `systemctl status nginx` |
| MySQL connection denied | Check user grants; verify bind-address in /etc/mysql/mariadb.conf.d/50-server.cnf |
| SSH connection refused on new port | Verify SELinux/AppArmor allows port; check firewall |
| Backup script fails | Check permissions on /var/backups; verify mysqldump in PATH |
| NFS mount fails | Check /etc/exports; verify nfs-server running; check firewall |
| Samba access denied | Verify Samba user created; check share permissions |
| Ansible can't connect | Verify SSH keys; check inventory IPs; test `ansible all -m ping` |

---

## Final Notes

- **Time management:** Allocate 2-4 hours per capstone
- **Documentation is key:** Write down what you did and why
- **Test thoroughly:** Break things intentionally to practice troubleshooting
- **Iterate:** If something fails, research, fix, and document
- **Keep snapshots:** Take VM snapshots before major changes

**Congratulations!** Completing these capstones means you can deploy, secure, and maintain production Linux systems. You're ready for LFCS/RHCSA certifications or junior/mid-level Linux admin roles.

---

**Course Complete!** Review any modules as needed, practice regularly, and keep learning!

# Module 11: Networking Essentials

## Why it matters
Networking is the backbone of modern infrastructure. Every service depends on IP addresses, DNS resolution, routing, and firewall rules. This module teaches practical network configuration, troubleshooting, and security basics. Understanding ip, ss, tcpdump, and firewall commands prevents 90% of connectivity issues.

## Prerequisites
**Packages/Tools:**
- iproute2 (ip command) — pre-installed
- net-tools (ifconfig, netstat, deprecated but still common) — optional
- bind-utils or dnsutils (dig, nslookup)
- tcpdump, nmap
- curl, wget
- NetworkManager (Ubuntu/RHEL) or netplan (newer Ubuntu)

**Files/Labs:**
- Root/sudo access
- Network connection (will test, not break)

## Cheat-Sheet
- `ip addr show` — show IP addresses
- `ip link show` — show network interfaces
- `ip route show` — show routing table
- `ss -tulnp` — show listening ports
- `ping <host>` — test connectivity
- `dig <domain>` — DNS lookup
- `curl <url>` — HTTP request
- `tcpdump -i eth0` — capture packets
- `nmap <ip>` — scan ports
- `firewall-cmd --list-all` — show firewall rules (RHEL)
- `ufw status` — show firewall (Ubuntu)

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== VIEW NETWORK CONFIG =====
# Show all IP addresses
ip addr show
# or short form:
ip a

# Show specific interface
ip addr show eth0  # or ens33, ens192, etc.

# Show link status
ip link show

# Show only UP interfaces
ip link show up

# ===== SHOW ROUTING =====
# Show routing table
ip route show
# or:
ip r

# Show default gateway
ip route | grep default

# ===== HOSTNAME & DNS =====
# Show hostname
hostname
hostnamectl  # more detailed

# Set hostname
sudo hostnamectl set-hostname myserver.example.com

# Verify
hostnamectl

# DNS resolution
cat /etc/resolv.conf
# nameserver 8.8.8.8

# Modern Ubuntu uses systemd-resolved
resolvectl status

# Set DNS (temporary, lost on reboot)
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Set DNS permanently (Ubuntu 18.04+, netplan)
sudo nano /etc/netplan/01-netcfg.yaml
# Add:
# network:
#   version: 2
#   ethernets:
#     eth0:
#       dhcp4: true
#       nameservers:
#         addresses: [1.1.1.1, 8.8.8.8]

sudo netplan apply

# ===== CONFIGURE STATIC IP (Netplan, Ubuntu 18.04+) =====
# Backup config
sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak

# Edit netplan config
sudo nano /etc/netplan/01-netcfg.yaml

# Static IP config:
# network:
#   version: 2
#   ethernets:
#     eth0:
#       dhcp4: no
#       addresses:
#         - 192.168.1.100/24
#       gateway4: 192.168.1.1
#       nameservers:
#         addresses: [8.8.8.8, 1.1.1.1]

# Apply
sudo netplan apply

# Verify
ip addr show eth0

# Revert to DHCP if needed:
# dhcp4: yes
# (remove addresses, gateway4, nameservers)

# ===== CONFIGURE STATIC IP (NetworkManager, older Ubuntu/Desktop) =====
# Install NetworkManager
sudo apt install network-manager

# Edit connection with nmcli
nmcli con show  # list connections

# Set static IP
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.1.100/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.1.1
sudo nmcli con mod "Wired connection 1" ipv4.dns "8.8.8.8 1.1.1.1"
sudo nmcli con mod "Wired connection 1" ipv4.method manual

# Apply
sudo nmcli con up "Wired connection 1"

# ===== NETWORK TESTING =====
# Ping (test connectivity)
ping -c 4 8.8.8.8  # 4 packets
ping -c 4 google.com  # requires DNS

# Traceroute (show path to destination)
sudo apt install traceroute
traceroute google.com

# MTR (better traceroute)
sudo apt install mtr
mtr google.com

# DNS lookups
sudo apt install dnsutils

dig google.com
dig google.com +short  # just the IP

# Reverse DNS lookup
dig -x 8.8.8.8

# Query specific DNS server
dig @1.1.1.1 google.com

# nslookup (older, but still used)
nslookup google.com

# ===== PORT SCANNING & SOCKETS =====
# Show listening ports (modern, replaces netstat)
ss -tulnp
# -t = TCP, -u = UDP, -l = listening, -n = numeric, -p = process

# Show all connections
ss -tunap

# Show only TCP connections
ss -tan

# Filter by port
ss -tulnp | grep :80

# Netstat (deprecated but still common)
sudo apt install net-tools
netstat -tulnp  # same as ss

# Scan ports with nmap
sudo apt install nmap
nmap localhost  # scan own machine
sudo nmap -p 1-65535 localhost  # all ports (slow)
nmap -p 22,80,443 192.168.1.100  # specific ports

# Check if port is open (without nmap)
nc -zv localhost 22  # netcat port scan
# Or:
telnet localhost 22  # if connected, port is open

# ===== HTTP/HTTPS TESTING =====
# Download file
wget https://example.com/file.txt

# Download and save with different name
wget -O newname.txt https://example.com/file.txt

# Curl (more versatile)
curl https://example.com

# Show headers
curl -I https://google.com

# Follow redirects
curl -L https://example.com

# POST request
curl -X POST -d "key=value" https://example.com/api

# Download file
curl -O https://example.com/file.txt

# ===== TRANSFER FILES =====
# SCP (secure copy over SSH)
scp file.txt user@remote:/path/
scp user@remote:/path/file.txt ./

# Recursive copy
scp -r /local/dir user@remote:/path/

# SFTP (interactive)
sftp user@remote
# sftp> ls
# sftp> get remotefile.txt
# sftp> put localfile.txt
# sftp> quit

# Rsync over SSH (better than scp)
rsync -avz file.txt user@remote:/path/
# -a = archive (preserves permissions), -v = verbose, -z = compress

rsync -avz --delete /local/dir/ user@remote:/remote/dir/
# --delete removes files on remote not in local (sync)

# ===== FIREWALL (UFW - Ubuntu default) =====
# Install UFW
sudo apt install ufw

# Check status
sudo ufw status

# Enable firewall
sudo ufw enable

# Allow SSH (important! Lock yourself out otherwise)
sudo ufw allow ssh
# or:
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow port range
sudo ufw allow 6000:6010/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Allow from subnet
sudo ufw allow from 192.168.1.0/24

# Deny port
sudo ufw deny 23/tcp

# Delete rule
sudo ufw delete allow 80/tcp

# Show numbered rules
sudo ufw status numbered

# Delete rule by number
sudo ufw delete 3

# Disable firewall
sudo ufw disable

# Reset firewall (remove all rules)
sudo ufw reset

# ===== TCPDUMP (packet capture) =====
# Install tcpdump
sudo apt install tcpdump

# Capture packets on interface (Ctrl+C to stop)
sudo tcpdump -i eth0

# Capture 10 packets
sudo tcpdump -i eth0 -c 10

# Capture and show ASCII
sudo tcpdump -i eth0 -A

# Capture specific port
sudo tcpdump -i eth0 port 80

# Capture specific host
sudo tcpdump -i eth0 host 192.168.1.100

# Capture and save to file
sudo tcpdump -i eth0 -w capture.pcap

# Read from file
sudo tcpdump -r capture.pcap

# ===== HOSTS FILE =====
# Edit /etc/hosts for local DNS
sudo nano /etc/hosts

# Add entry:
# 192.168.1.100  myserver.local

# Verify
ping myserver.local

# ===== NETWORK MANAGER CLI =====
# Show all connections
nmcli con show

# Show active connections
nmcli con show --active

# Show devices
nmcli dev status

# Connect to WiFi (if applicable)
nmcli dev wifi list
nmcli dev wifi connect SSID password "PASSWORD"

# Disconnect
nmcli con down "connection-name"

# Reconnect
nmcli con up "connection-name"
```

### RHEL/Rocky
```bash
# ===== NETWORK CONFIG (NetworkManager) =====
# RHEL uses NetworkManager by default
nmcli con show

# Set static IP
sudo nmcli con mod eth0 ipv4.addresses 192.168.1.100/24
sudo nmcli con mod eth0 ipv4.gateway 192.168.1.1
sudo nmcli con mod eth0 ipv4.dns "8.8.8.8"
sudo nmcli con mod eth0 ipv4.method manual
sudo nmcli con up eth0

# Or edit ifcfg file (traditional method)
sudo nano /etc/sysconfig/network-scripts/ifcfg-eth0

# Static IP config:
# TYPE=Ethernet
# BOOTPROTO=static
# NAME=eth0
# DEVICE=eth0
# ONBOOT=yes
# IPADDR=192.168.1.100
# NETMASK=255.255.255.0
# GATEWAY=192.168.1.1
# DNS1=8.8.8.8

# Restart network
sudo nmcli con reload
sudo nmcli con up eth0

# ===== FIREWALL (firewalld - RHEL default) =====
# Check status
sudo systemctl status firewalld

# Start firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# List all rules
sudo firewall-cmd --list-all

# List zones
sudo firewall-cmd --get-zones
sudo firewall-cmd --get-default-zone

# Allow service
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent

# Allow port
sudo firewall-cmd --add-port=8080/tcp --permanent

# Remove service/port
sudo firewall-cmd --remove-service=http --permanent

# Reload firewall (apply --permanent rules)
sudo firewall-cmd --reload

# List services in zone
sudo firewall-cmd --zone=public --list-services

# Change default zone
sudo firewall-cmd --set-default-zone=public

# ===== ALL OTHER COMMANDS (same as Ubuntu) =====
ip addr show
ss -tulnp
ping -c 4 8.8.8.8
dig google.com
sudo dnf install tcpdump nmap
```

### SUSE
```bash
# ===== NETWORK CONFIG =====
# SUSE uses wicked or NetworkManager

# With wicked (default)
sudo wicked show all

# Edit config
sudo nano /etc/sysconfig/network/ifcfg-eth0

# Static IP:
# BOOTPROTO='static'
# IPADDR='192.168.1.100/24'
# GATEWAY='192.168.1.1'

# Restart network
sudo wicked ifreload eth0

# With NetworkManager
nmcli con show
# (same commands as Ubuntu/RHEL)

# ===== FIREWALL =====
# SUSE uses SuSEfirewall2 or firewalld
sudo systemctl status firewalld
sudo firewall-cmd --list-all
# (same as RHEL)

# ===== OTHER COMMANDS (same) =====
ip addr show
ss -tulnp
```

---

## Verify
```bash
# Check IP address
ip addr show | grep inet
# Expected: inet X.X.X.X/24

# Check default gateway
ip route | grep default
# Expected: default via X.X.X.X

# Test DNS resolution
ping -c 2 google.com
# Expected: 64 bytes from...

# Check listening ports
ss -tulnp | grep LISTEN
# Expected: list of ports

# Test firewall (if enabled)
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-all  # RHEL
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Network is unreachable` | No default gateway | `ip route add default via 192.168.1.1` |
| `Name or service not known` | DNS not configured | Check /etc/resolv.conf or resolvectl status |
| Can't SSH after firewall enable | SSH port blocked | `sudo ufw allow ssh` before enabling |
| `RTNETLINK answers: File exists` | Route already exists | Delete old route first: `ip route del` |
| Netplan apply fails | YAML syntax error | Check indentation (2 spaces, not tabs) |
| Changes revert after reboot | Not persistent | Use netplan or nmcli with --permanent for firewall |

---

## Cleanup
```bash
# Revert to DHCP if needed
sudo nano /etc/netplan/01-netcfg.yaml
# Set: dhcp4: yes
sudo netplan apply

# Or with NetworkManager:
sudo nmcli con mod eth0 ipv4.method auto
sudo nmcli con up eth0
```

---

## Quick Quiz

1. What command shows all IP addresses on your system?
2. What's the difference between `ss` and `netstat`?
3. How do you test if port 443 is reachable on a remote host?
4. What's the purpose of /etc/resolv.conf?
5. How do you allow HTTP traffic through UFW firewall?

---

**Next:** [Module 12: Networking Advanced](module-12-networking-advanced.md)

# Networking Cheatsheet

## IP - Network Configuration

### View Configuration
```bash
# Show all interfaces
ip addr show
ip a                                # short form

# Show specific interface
ip addr show eth0
ip a s eth0                         # short form

# Show only IPv4
ip -4 addr

# Show only IPv6
ip -6 addr

# Show link status
ip link show
ip l                                # short form

# Show MAC addresses
ip link show | grep link/ether
```

### Configure IP Addresses
```bash
# Add IP address
sudo ip addr add 192.168.1.100/24 dev eth0

# Remove IP address
sudo ip addr del 192.168.1.100/24 dev eth0

# Bring interface up/down
sudo ip link set eth0 up
sudo ip link set eth0 down

# Change MTU
sudo ip link set eth0 mtu 9000
```

### Routing
```bash
# Show routing table
ip route show
ip r                                # short form

# Show default gateway
ip route | grep default

# Add route
sudo ip route add 10.0.0.0/8 via 192.168.1.1 dev eth0

# Delete route
sudo ip route del 10.0.0.0/8

# Add default gateway
sudo ip route add default via 192.168.1.1

# Replace route
sudo ip route replace default via 192.168.1.254
```

---

## SS - Socket Statistics

### View Connections
```bash
# All connections
ss -a

# TCP connections
ss -t

# UDP connections
ss -u

# Listening ports
ss -l

# All listening ports (TCP + UDP)
ss -tuln
# -t = TCP, -u = UDP, -l = listening, -n = numeric (no DNS resolution)

# Show process names
ss -tulnp
# -p = process (requires root for non-owned processes)

# All established TCP connections
ss -tan state established
```

### Filter by Port/Address
```bash
# Specific port
ss -tuln sport = :80                # source port 80
ss -tuln dport = :3306              # destination port 3306

# Port range
ss -tuln sport ge :1000             # source port >= 1000

# Specific address
ss dst 192.168.1.100

# Exclude address
ss not dst 192.168.1.100
```

### Connection States
```bash
# Show states
ss -tan                             # shows state column

# Filter by state
ss state established
ss state listening
ss state time-wait
ss state close-wait

# Common states:
# LISTEN       = listening for connections
# ESTABLISHED  = active connection
# TIME-WAIT    = connection closed, waiting
# CLOSE-WAIT   = remote closed, local not
# SYN-SENT     = trying to connect
# SYN-RECV     = received connection request
```

### Statistics
```bash
# Summary
ss -s

# Show statistics
ss -tni                             # TCP info
```

---

## DNS Lookup

### Dig
```bash
# Basic lookup
dig google.com

# Short answer only
dig google.com +short

# Specific record type
dig google.com A                    # IPv4
dig google.com AAAA                 # IPv6
dig google.com MX                   # mail servers
dig google.com NS                   # name servers
dig google.com TXT                  # TXT records

# Reverse DNS
dig -x 8.8.8.8

# Query specific DNS server
dig @1.1.1.1 google.com
dig @8.8.8.8 google.com

# Trace DNS resolution
dig google.com +trace

# Show only answer section
dig google.com +noall +answer
```

### Nslookup
```bash
# Basic lookup
nslookup google.com

# Specific DNS server
nslookup google.com 8.8.8.8

# Reverse lookup
nslookup 8.8.8.8

# Interactive mode
nslookup
> set type=MX
> google.com
> exit
```

### Host
```bash
# Basic lookup
host google.com

# Specific record
host -t MX google.com
host -t NS google.com

# Reverse lookup
host 8.8.8.8
```

---

## Connectivity Testing

### Ping
```bash
# Basic ping
ping google.com

# Count packets
ping -c 4 google.com                # send 4 packets

# Interval
ping -i 2 google.com                # 2 seconds between packets

# Packet size
ping -s 1000 google.com             # 1000 byte packets

# Flood ping (root only, be careful!)
sudo ping -f google.com

# IPv4/IPv6 specific
ping -4 google.com
ping -6 google.com
```

### Traceroute
```bash
# Trace route
traceroute google.com

# Faster (use UDP)
traceroute -U google.com

# Use ICMP
traceroute -I google.com

# Max hops
traceroute -m 15 google.com

# MTR (better traceroute)
mtr google.com                      # real-time
mtr -n google.com                   # no DNS resolution
mtr -r google.com                   # report mode (10 cycles)
```

### Telnet
```bash
# Test port connectivity
telnet google.com 80
telnet 192.168.1.100 22

# If connected, Ctrl+] then 'quit' to exit
```

### Netcat (nc)
```bash
# Test port (better than telnet)
nc -zv google.com 80                # -z = scan, -v = verbose
nc -zv 192.168.1.100 22

# Port range scan
nc -zv 192.168.1.100 20-25

# Listen on port (server)
nc -l 8080                          # listen on port 8080

# Connect to listening port (client)
nc 192.168.1.100 8080

# Transfer file
# Server:
nc -l 8080 > received.txt
# Client:
nc 192.168.1.100 8080 < file.txt

# Chat
# Server:
nc -l 8080
# Client:
nc 192.168.1.100 8080
```

---

## Port Scanning

### Nmap
```bash
# Basic scan
nmap 192.168.1.100

# Scan subnet
nmap 192.168.1.0/24

# Scan specific ports
nmap -p 22,80,443 192.168.1.100

# Scan port range
nmap -p 1-1000 192.168.1.100

# All ports
nmap -p- 192.168.1.100

# Common ports (top 1000)
nmap --top-ports 1000 192.168.1.100

# TCP SYN scan (stealth, requires root)
sudo nmap -sS 192.168.1.100

# TCP connect scan
nmap -sT 192.168.1.100

# UDP scan (slow)
sudo nmap -sU 192.168.1.100

# Service version detection
nmap -sV 192.168.1.100

# OS detection
sudo nmap -O 192.168.1.100

# Aggressive scan
sudo nmap -A 192.168.1.100

# Fast scan (top 100 ports)
nmap -F 192.168.1.100

# Ping scan (check if host is up)
nmap -sn 192.168.1.0/24
```

---

## HTTP Tools

### Curl
```bash
# GET request
curl https://example.com

# Save to file
curl -O https://example.com/file.txt          # use remote filename
curl -o local.txt https://example.com/file.txt # specify filename

# Follow redirects
curl -L https://example.com

# Show headers only
curl -I https://example.com

# Verbose output
curl -v https://example.com

# POST request
curl -X POST -d "key=value" https://example.com/api

# POST JSON
curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' https://example.com/api

# Headers
curl -H "Authorization: Bearer token" https://example.com/api

# Download with progress bar
curl -# -O https://example.com/bigfile.iso

# Resume download
curl -C - -O https://example.com/bigfile.iso

# Basic auth
curl -u user:password https://example.com

# Proxy
curl -x http://proxy:8080 https://example.com
```

### Wget
```bash
# Download file
wget https://example.com/file.txt

# Specify filename
wget -O newname.txt https://example.com/file.txt

# Resume download
wget -c https://example.com/bigfile.iso

# Background download
wget -b https://example.com/file.txt

# Mirror website (careful!)
wget -m https://example.com

# Download all PDFs from page
wget -r -A.pdf https://example.com
```

---

## Packet Capture

### Tcpdump
```bash
# Capture on interface
sudo tcpdump -i eth0

# Capture N packets
sudo tcpdump -i eth0 -c 100

# Specific port
sudo tcpdump -i eth0 port 80

# Specific host
sudo tcpdump -i eth0 host 192.168.1.100

# Port range
sudo tcpdump -i eth0 portrange 20-25

# Save to file
sudo tcpdump -i eth0 -w capture.pcap

# Read from file
sudo tcpdump -r capture.pcap

# Show ASCII
sudo tcpdump -i eth0 -A

# Show hex and ASCII
sudo tcpdump -i eth0 -X

# Verbose
sudo tcpdump -i eth0 -v

# Don't resolve hostnames/ports (faster)
sudo tcpdump -i eth0 -nn

# Combine filters (AND)
sudo tcpdump -i eth0 port 80 and host 192.168.1.100

# OR condition
sudo tcpdump -i eth0 'port 80 or port 443'

# NOT condition
sudo tcpdump -i eth0 not port 22

# HTTP traffic
sudo tcpdump -i eth0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
```

---

## Firewall

### UFW (Ubuntu)
```bash
# Enable/Disable
sudo ufw enable
sudo ufw disable

# Status
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Allow port
sudo ufw allow 22/tcp
sudo ufw allow ssh
sudo ufw allow 80,443/tcp

# Deny port
sudo ufw deny 23/tcp

# Allow from IP
sudo ufw allow from 192.168.1.100

# Allow from subnet to port
sudo ufw allow from 192.168.1.0/24 to any port 22

# Delete rule
sudo ufw delete allow 80/tcp
sudo ufw delete 2                   # by number (use status numbered)

# Reset (remove all rules)
sudo ufw reset
```

### Firewalld (RHEL/Rocky)
```bash
# Start/Stop
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Status
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# Allow service
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent

# Allow port
sudo firewall-cmd --add-port=8080/tcp --permanent

# Remove service/port
sudo firewall-cmd --remove-service=http --permanent
sudo firewall-cmd --remove-port=8080/tcp --permanent

# Reload (apply permanent rules)
sudo firewall-cmd --reload

# List services
sudo firewall-cmd --list-services

# List ports
sudo firewall-cmd --list-ports

# Zones
sudo firewall-cmd --get-zones
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --set-default-zone=public
```

---

## Tips & Tricks

1. **Use `-n` flag** to avoid DNS lookups (faster)
2. **Combine `ip` commands**: `ip -c a` (colorized output)
3. **Use `ss` instead of `netstat`** (faster, more features)
4. **Always use `+short` with dig** for scripting
5. **Save tcpdump as pcap** for analysis in Wireshark
6. **Use `mtr` instead of traceroute** for ongoing monitoring
7. **Remember: root required** for most nmap scans
8. **Test firewall changes** before making permanent
9. **Use curl `-v` for debugging** HTTP issues
10. **nc (netcat) is Swiss Army knife** for network debugging

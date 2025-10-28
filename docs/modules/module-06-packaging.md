# Module 06: Packaging & Repositories

## Why it matters
Package managers install, update, and remove software while handling dependencies automatically. They're safer than manual installs and integrate with security updates. Understanding apt (Debian/Ubuntu), dnf/yum (RHEL), and zypper (SUSE) is essential for maintaining systems. Repository management ensures you get vetted, signed packages.

## Prerequisites
**Packages/Tools:**
- apt/dpkg (Ubuntu/Debian) — pre-installed
- dnf/yum/rpm (RHEL/Rocky) — pre-installed
- zypper/rpm (SUSE) — pre-installed

**Files/Labs:**
- Root/sudo access
- Internet connection for package downloads

## Cheat-Sheet
**Ubuntu/Debian:**
- `apt update` — refresh package lists
- `apt upgrade` — upgrade installed packages
- `apt install <pkg>` — install package
- `apt remove <pkg>` — remove package (keep config)
- `apt purge <pkg>` — remove package and config
- `apt search <term>` — search for packages
- `dpkg -l` — list installed packages
- `dpkg -i <file.deb>` — install .deb file

**RHEL/Rocky:**
- `dnf update` — refresh and upgrade packages
- `dnf install <pkg>` — install package
- `dnf remove <pkg>` — remove package
- `dnf search <term>` — search packages
- `rpm -qa` — list installed packages
- `rpm -ivh <file.rpm>` — install .rpm file

**SUSE:**
- `zypper refresh` — refresh repos
- `zypper update` — upgrade packages
- `zypper install <pkg>` — install package
- `zypper remove <pkg>` — remove package

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== APT BASICS =====
# Update package lists (always run first!)
sudo apt update

# Upgrade all packages
sudo apt upgrade       # upgrades packages, asks for confirmation
sudo apt upgrade -y    # auto-confirm

# Full upgrade (may remove packages)
sudo apt full-upgrade

# Install package
sudo apt install nginx
sudo apt install vim htop curl

# Install multiple packages
sudo apt install -y nginx mariadb-server php-fpm

# Install specific version
apt list -a nginx  # show available versions
sudo apt install nginx=1.18.0-0ubuntu1

# Remove package (keep config files)
sudo apt remove nginx

# Remove package and config files
sudo apt purge nginx

# Remove unused dependencies
sudo apt autoremove

# ===== SEARCHING PACKAGES =====
# Search by name or description
apt search nginx
apt search "web server"

# Show package details
apt show nginx

# List installed packages
apt list --installed
apt list --installed | grep nginx

# Check if package is installed
dpkg -l | grep nginx

# ===== REPOSITORY MANAGEMENT =====
# List repositories
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/

# Add repository (example: Docker)
# Add GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Update and install
sudo apt update
sudo apt install docker-ce

# Remove repository
sudo rm /etc/apt/sources.list.d/docker.list
sudo apt update

# Using add-apt-repository (needs software-properties-common)
sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php  # add PPA
sudo add-apt-repository --remove ppa:ondrej/php  # remove PPA

# ===== DPKG (low-level package manager) =====
# Install .deb file
wget https://example.com/package.deb
sudo dpkg -i package.deb

# If dependencies missing:
sudo apt install -f  # fix broken dependencies

# List installed packages
dpkg -l
dpkg -l | grep nginx

# List files installed by package
dpkg -L nginx

# Find which package owns a file
dpkg -S /usr/sbin/nginx

# Remove package
sudo dpkg -r nginx

# Reconfigure package
sudo dpkg-reconfigure tzdata

# ===== PACKAGE PINNING (version control) =====
# Create pin file
sudo nano /etc/apt/preferences.d/nginx-pin

# Pin nginx to specific version:
# Package: nginx
# Pin: version 1.18.0-0ubuntu1
# Pin-Priority: 1001

sudo apt update

# ===== SNAP PACKAGES (optional, Ubuntu) =====
# Snap is pre-installed on Ubuntu
snap list

# Install snap package
sudo snap install spotify
sudo snap install --classic code  # classic = full system access

# Remove snap
sudo snap remove spotify

# ===== FLATPAK (optional) =====
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.gimp.GIMP
flatpak run org.gimp.GIMP

# ===== BUILD FROM SOURCE =====
# Install build tools
sudo apt install build-essential

# Example: compile htop from source
sudo apt install libncurses-dev
wget https://github.com/htop-dev/htop/releases/download/3.2.1/htop-3.2.1.tar.gz
tar xzf htop-3.2.1.tar.gz
cd htop-3.2.1

# Configure
./configure

# Compile
make

# Install (to /usr/local/bin)
sudo make install

# Verify
which htop  # should show /usr/local/bin/htop

# Uninstall
sudo make uninstall

# ===== CHECKINSTALL (create .deb from source) =====
sudo apt install checkinstall

# Instead of 'sudo make install':
sudo checkinstall
# Creates .deb package and installs it
# Can be removed later with apt/dpkg

cd ~
rm -rf htop-3.2.1*

# ===== CACHE MANAGEMENT =====
# Show cache size
sudo du -sh /var/cache/apt/archives

# Clean package cache
sudo apt clean  # remove all cached .deb files

# Clean only outdated packages
sudo apt autoclean
```

### RHEL/Rocky
```bash
# ===== DNF BASICS (replaces yum on RHEL 8+) =====
# Update package cache and upgrade
sudo dnf update      # updates cache and upgrades packages
sudo dnf update -y   # auto-confirm

# Upgrade only (no cache update)
sudo dnf upgrade

# Install package
sudo dnf install nginx
sudo dnf install -y vim htop

# Install specific version
dnf list nginx --showduplicates
sudo dnf install nginx-1.20.0

# Remove package
sudo dnf remove nginx

# Remove unused dependencies
sudo dnf autoremove

# ===== SEARCHING PACKAGES =====
dnf search nginx
dnf info nginx

# List installed packages
dnf list installed
dnf list installed | grep nginx

# ===== REPOSITORY MANAGEMENT =====
# List enabled repos
dnf repolist

# List all repos (including disabled)
dnf repolist --all

# Enable repo
sudo dnf config-manager --enable epel

# Disable repo
sudo dnf config-manager --disable epel

# Add repository (example: EPEL)
sudo dnf install epel-release

# Add custom repo file
sudo nano /etc/yum.repos.d/custom.repo
# [custom]
# name=Custom Repository
# baseurl=https://example.com/repo
# enabled=1
# gpgcheck=1
# gpgkey=https://example.com/repo/RPM-GPG-KEY

# Import GPG key
sudo rpm --import https://example.com/RPM-GPG-KEY

# ===== DNF GROUPS =====
# List available groups
dnf group list

# Install group
sudo dnf group install "Development Tools"

# Remove group
sudo dnf group remove "Development Tools"

# ===== YUM (older RHEL 7, works on RHEL 8+ as dnf alias) =====
sudo yum update
sudo yum install nginx
# Commands same as dnf

# ===== RPM (low-level) =====
# Install .rpm file
wget https://example.com/package.rpm
sudo rpm -ivh package.rpm
# -i = install, -v = verbose, -h = hash marks (progress)

# Upgrade .rpm
sudo rpm -Uvh package.rpm

# Remove package
sudo rpm -e package

# List installed packages
rpm -qa
rpm -qa | grep nginx

# List files in package
rpm -ql nginx

# Find which package owns file
rpm -qf /usr/sbin/nginx

# Query package info
rpm -qi nginx

# List dependencies
rpm -qR nginx

# ===== BUILD FROM SOURCE =====
sudo dnf group install "Development Tools"
sudo dnf install ncurses-devel

wget https://github.com/htop-dev/htop/releases/download/3.2.1/htop-3.2.1.tar.gz
tar xzf htop-3.2.1.tar.gz
cd htop-3.2.1
./configure
make
sudo make install

# Cleanup
cd ~
rm -rf htop-3.2.1*

# ===== CACHE MANAGEMENT =====
# Clean metadata cache
sudo dnf clean metadata

# Clean all cached data
sudo dnf clean all

# Show cache size
sudo du -sh /var/cache/dnf
```

### SUSE
```bash
# ===== ZYPPER BASICS =====
# Refresh repos
sudo zypper refresh

# Update all packages
sudo zypper update
sudo zypper update -y  # auto-confirm

# Install package
sudo zypper install nginx
sudo zypper install -y vim htop

# Remove package
sudo zypper remove nginx

# Remove unused dependencies
sudo zypper packages --unneeded  # list unneeded
sudo zypper remove --clean-deps nginx  # remove with deps

# ===== SEARCHING =====
zypper search nginx
zypper info nginx

# List installed packages
zypper packages --installed-only
zypper se -i  # short form

# ===== REPOSITORIES =====
# List repos
zypper repos
zypper lr  # short form

# Add repository
sudo zypper addrepo https://example.com/repo myrepo

# Refresh specific repo
sudo zypper refresh myrepo

# Remove repo
sudo zypper removerepo myrepo

# Enable/disable repo
sudo zypper modifyrepo --disable myrepo
sudo zypper modifyrepo --enable myrepo

# ===== RPM (same as RHEL) =====
sudo rpm -ivh package.rpm
rpm -qa | grep nginx
rpm -ql nginx

# ===== PATTERNS (package groups) =====
zypper search -t pattern
sudo zypper install -t pattern devel_basis  # development tools

# ===== BUILD FROM SOURCE (same as RHEL/Ubuntu) =====
sudo zypper install -t pattern devel_basis
sudo zypper install ncurses-devel

# (same build steps as Ubuntu/RHEL)
```

---

## Verify
```bash
# Ubuntu/Debian
apt list --installed | head -5
dpkg -l | wc -l  # count installed packages

# RHEL/Rocky
dnf list installed | head -5
rpm -qa | wc -l

# SUSE
zypper packages --installed-only | head -5
rpm -qa | wc -l

# All distros: verify a package
which vim  # should show /usr/bin/vim if installed
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `E: Could not get lock /var/lib/dpkg/lock` (apt) | Another apt process running | Wait or `sudo rm /var/lib/dpkg/lock*` then `sudo dpkg --configure -a` |
| `Unable to locate package` | Package name wrong or repos not updated | `sudo apt update` or check package name |
| `Dependency hell` when installing .deb/.rpm | Missing dependencies | Use `apt install -f` or `dnf install` to resolve |
| GPG signature errors | Missing or expired GPG key | Re-import key or add `--nogpgcheck` (insecure!) |
| `dnf: command not found` on old RHEL 7 | System uses yum | Use `yum` instead of `dnf` |
| Repository not found | Repo URL changed or typo | Edit /etc/apt/sources.list.d/ or /etc/yum.repos.d/ |

---

## Cleanup
```bash
# Remove test packages if installed
sudo apt remove htop 2>/dev/null || sudo dnf remove htop 2>/dev/null || sudo zypper remove htop 2>/dev/null || true

# Clean package cache
sudo apt clean 2>/dev/null || sudo dnf clean all 2>/dev/null || sudo zypper clean 2>/dev/null || true
```

---

## Quick Quiz

1. What's the difference between `apt remove` and `apt purge`?
2. How do you search for a package without installing it?
3. What command shows which package owns /usr/bin/vim?
4. What's the low-level package manager for .deb files?
5. How do you prevent a package from being upgraded (pinning)?

---

**Next:** [Module 07: Storage, Partitions, Filesystems](module-07-storage-filesystems.md)

# Linux Administration Course
**Complete Command-First Training: Beginner → Advanced**

## 🎯 What You'll Learn
This course teaches you to manage Linux systems from the command line—no GUIs, no fluff. You'll start with basic navigation and end deploying multi-VM environments with automation. Every concept includes distro-specific commands (Ubuntu/Debian, RHEL/Rocky, SUSE), verification steps, troubleshooting guides, and hands-on labs.

## 👥 Who This Is For
- **Beginners** with basic computer skills (no prior Linux needed)
- **Windows admins** migrating to Linux environments
- **Developers** wanting infrastructure skills
- **Anyone** preparing for LFCS, RHCSA, or cloud certifications

## 🛠️ Practice Setup
You **must** have a Linux environment to follow along. Choose one:

### Option 1: Virtual Machines (Recommended)
Use VirtualBox, VMware Workstation, or KVM/libvirt:
- **Ubuntu 22.04 LTS** or **24.04 LTS** (easiest for beginners)
- **Rocky Linux 9** (RHEL-compatible)
- **openSUSE Leap 15.x** (optional)
- **Minimum specs per VM:** 2 GB RAM, 20 GB disk, 1 CPU

### Option 2: Cloud Instances
- AWS EC2 (t2.micro free tier), Azure, GCP, DigitalOcean
- SSH access required
- **Cost note:** shut down when not practicing

### Option 3: WSL2 (Windows Subsystem for Linux)
- Limited for some modules (systemd, networking, storage)
- Good for: text tools, scripting, package management

### Snapshots/Backups
**CRITICAL:** Before destructive labs (disk partitioning, LVM, RAID), take VM snapshots or backups. Commands marked **🚨 DANGER** can erase data.

## 📚 Course Map (30 Modules)

### Foundations (Modules 1–3)
1. **Foundations & Navigation** — distros, filesystem hierarchy, shell basics
2. **Help & Text Mastery** — man pages, grep, sed, awk, find, editors
3. **Users, Groups, Identity & Access** — user management, sudo, PAM

### Core System Skills (Modules 4–10)
4. **Permissions, ACLs, Attributes, SELinux/AppArmor** — chmod, ACLs, mandatory access control
5. **Processes, Jobs, and Systemd** — process management, systemd units, journalctl
6. **Packaging & Repositories** — apt, dnf, zypper; build from source
7. **Storage, Partitions, Filesystems** — disks, partitions, mkfs, fstab, quotas
8. **LVM & RAID** — logical volumes, RAID arrays, snapshots
9. **Advanced Filesystems & Encryption** — btrfs, ZFS, LUKS encryption
10. **Backup & Restore** — tar, rsync, borg, restore drills

### Networking (Modules 11–12)
11. **Networking Essentials** — IP config, DNS, DHCP, firewall basics, tcpdump
12. **Networking Advanced** — bridges, VLANs, routing, NAT, nftables/iptables

### Operations (Modules 13–18)
13. **Time, NTP, and Localization** — timedatectl, chrony
14. **Logging & Rotation** — journald, rsyslog, logrotate
15. **Kernel, Modules, and Tuning** — kernel params, sysctl, ulimit
16. **Boot & Rescue** — GRUB2, initramfs, rescue mode, chroot recovery
17. **SSH & Remote Admin** — SSH hardening, keys, jump hosts
18. **Task Scheduling** — cron, anacron, systemd timers

### Services & Applications (Modules 19–22)
19. **Services: Web, DB, Mail (Admin Basics)** — nginx, Apache, MySQL, PostgreSQL, Postfix
20. **File Sharing & Directory Services** — NFS, Samba/CIFS
21. **Containers (Admin Essentials)** — Docker/Podman, volumes, networks, compose
22. **Virtualization (KVM/libvirt)** — virt-install, virsh, cloud-init

### Advanced Topics (Modules 23–30)
23. **Monitoring & Performance** — vmstat, iostat, sar, top/htop, triage playbooks
24. **Security Hardening & Compliance** — SSH hardening, fail2ban, SELinux policies, CIS benchmarks
25. **Scripting & Automation** — bash scripting, sed/awk pipelines, admin utilities
26. **Ansible (Admin Basics)** — inventory, playbooks, roles
27. **Git for Admins** — version control for /etc, etckeeper
28. **Cloud CLI (Optional)** — AWS/Azure/GCP CLI for VM management
29. **Troubleshooting Clinic** — network down, disk full, boot loops, SELinux denials
30. **Capstones (Integrations)** — 3 real-world projects: hardened web+DB, file server, KVM+Ansible

## 📖 How to Use This Course

### Step 1: Choose Your Distro Track
Each module shows commands for **Ubuntu/Debian**, **RHEL/Rocky**, and **SUSE**. Pick one as your primary, try others for comparison.

### Step 2: Follow Module Order
Modules build on each other. Don't skip unless you're experienced.

### Step 3: Type Every Command
**Do not copy-paste blindly.** Type commands, read inline comments, understand what's happening.

### Step 4: Verify & Troubleshoot
Every module includes:
- **Verify section:** commands to confirm success
- **Troubleshooting:** common errors and fixes
- **Cleanup:** undo changes safely

### Step 5: Take Quizzes
End-of-module quizzes test understanding. No answers provided—search man pages or re-read the module.

### Step 6: Build Capstones
After Module 29, complete at least one capstone (Module 30) to integrate skills.

## 📄 Cheatsheets
Quick references for frequent tasks (found in `docs/cheatsheets/`):
- **Text processing** (grep, sed, awk, find, xargs)
- **Systemd & journald** (systemctl, journalctl)
- **Networking** (ip, ss, firewall commands)
- **Storage & LVM** (lsblk, fdisk, lvcreate, etc.)
- **SSH** (keygen, config, tunnels)

## 🧪 Labs
Downloadable scripts and sample data in `docs/labs/`:
- User creation CSVs
- Sample log files for parsing
- Test data for backup/restore
- Network config templates

## 🚨 Safety Warnings
Commands marked **🚨 DANGER** can:
- Erase disks
- Delete users
- Break boot loaders
- Lock you out of systems

**Always:**
1. Take VM snapshots before destructive labs
2. Use test VMs, never production systems
3. Read the entire command before running
4. Follow the safe alternatives provided

## 🏆 After Completing This Course
You'll be able to:
- ✅ Manage users, permissions, and security policies
- ✅ Configure storage (partitions, LVM, RAID, encryption)
- ✅ Set up networking (static IPs, VLANs, firewalls, NAT)
- ✅ Deploy and secure services (web, DB, containers)
- ✅ Automate tasks with bash and Ansible
- ✅ Troubleshoot boot, network, disk, and SELinux issues
- ✅ Pass LFCS, RHCSA, or similar certifications

## 📚 Additional Resources
- **Man pages:** Your primary reference (`man <command>`)
- **ArchWiki:** Best technical docs (applies to all distros)
- **RHEL docs:** [access.redhat.com](https://access.redhat.com/documentation/)
- **Ubuntu docs:** [help.ubuntu.com](https://help.ubuntu.com/)

## 🤝 Contributing
Found an error? Have a better example? Open an issue or PR. This course is open-source.

## 📜 License
MIT License — free to use, share, and modify.

---

## Module List (Direct Links)

1. [Foundations & Navigation](modules/module-01-foundations.md)
2. [Help & Text Mastery](modules/module-02-help-text.md)
3. [Users, Groups, Identity & Access](modules/module-03-users-groups.md)
4. [Permissions, ACLs, Attributes, SELinux/AppArmor](modules/module-04-permissions-acls.md)
5. [Processes, Jobs, and Systemd](modules/module-05-processes-systemd.md)
6. [Packaging & Repositories](modules/module-06-packaging.md)
7. [Storage, Partitions, Filesystems](modules/module-07-storage-filesystems.md)
8. [LVM & RAID](modules/module-08-lvm-raid.md)
9. [Advanced Filesystems & Encryption](modules/module-09-advanced-fs-encryption.md)
10. [Backup & Restore](modules/module-10-backup-restore.md)
11. [Networking Essentials](modules/module-11-networking-essentials.md)
12. [Networking Advanced](modules/module-12-networking-advanced.md)
13. [Time, NTP, and Localization](modules/module-13-time-ntp.md)
14. [Logging & Rotation](modules/module-14-logging-rotation.md)
15. [Kernel, Modules, and Tuning](modules/module-15-kernel-tuning.md)
16. [Boot & Rescue](modules/module-16-boot-rescue.md)
17. [SSH & Remote Admin](modules/module-17-ssh-remote.md)
18. [Task Scheduling](modules/module-18-task-scheduling.md)
19. [Services: Web, DB, Mail](modules/module-19-services.md)
20. [File Sharing & Directory Services](modules/module-20-file-sharing.md)
21. [Containers (Admin Essentials)](modules/module-21-containers.md)
22. [Virtualization (KVM/libvirt)](modules/module-22-virtualization.md)
23. [Monitoring & Performance](modules/module-23-monitoring-performance.md)
24. [Security Hardening & Compliance](modules/module-24-security-hardening.md)
25. [Scripting & Automation](modules/module-25-scripting-automation.md)
26. [Ansible (Admin Basics)](modules/module-26-ansible.md)
27. [Git for Admins](modules/module-27-git-admins.md)
28. [Cloud CLI (Optional)](modules/module-28-cloud-cli.md)
29. [Troubleshooting Clinic](modules/module-29-troubleshooting.md)
30. [Capstones (Integrations)](modules/module-30-capstones.md)

---

**Start with [Module 01: Foundations & Navigation](modules/module-01-foundations.md) →**

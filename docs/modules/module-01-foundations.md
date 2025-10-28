# Module 01: Foundations & Navigation

## Why it matters
Linux powers 90% of cloud infrastructure, most servers, Android phones, and supercomputers. Understanding the filesystem hierarchy, shell basics, and how distributions differ is foundational to everything else. This module teaches you to navigate confidently and understand what you're looking at.

## Prerequisites
**Packages/Tools:**
- bash shell (pre-installed on all distros)
- coreutils (pre-installed: ls, cd, pwd, etc.)

**Files/Labs:**
- None (exploration only)

## Cheat-Sheet
- `pwd` — print working directory (where am I?)
- `ls -lah` — list files with details, hidden files, human-readable sizes
- `cd <path>` — change directory (absolute or relative)
- `cat /etc/os-release` — show distro name and version
- `uname -a` — show kernel version and architecture
- `echo $PATH` — show executable search paths
- `which <command>` — find where a command lives
- `type <command>` — show if command is alias, function, or binary
- `history` — show command history
- `!!` — repeat last command
- `!<number>` — repeat command number from history

---

## Commands & Labs

### Ubuntu/Debian
```bash
# Check distro version
cat /etc/os-release
# Output shows: Ubuntu 22.04 LTS, Debian 12, etc.

# Check kernel version
uname -r  # e.g., 5.15.0-56-generic

# Explore filesystem hierarchy
ls -lh /       # root directory
ls -lh /bin    # essential binaries
ls -lh /etc    # configuration files
ls -lh /home   # user home directories
ls -lh /var    # variable data (logs, caches)
ls -lh /tmp    # temporary files (cleared on reboot)

# Special directories
ls -lh /proc   # process and kernel info (virtual filesystem)
ls -lh /sys    # device and driver info (virtual filesystem)
ls -lh /dev    # device files (disks, terminals, etc.)

# Navigate using absolute paths
cd /etc
pwd  # shows /etc

# Navigate using relative paths
cd sysconfig  # if it exists on RHEL-based, fails on Ubuntu
cd ..         # go up one directory
pwd           # back to /

# Home directory shortcuts
cd ~          # go to your home directory
cd            # same as cd ~
cd ~/Documents  # relative to home

# Path management
echo $PATH    # see where shell looks for commands
which ls      # find location of ls command (/usr/bin/ls)
type cd       # cd is a shell builtin

# Command history
history | tail -10  # show last 10 commands
!100          # re-run command number 100
!!            # repeat last command
!ls           # repeat last command starting with "ls"
Ctrl+R        # search history interactively (type to search, Enter to run)

# Aliases (temporary)
alias ll='ls -lah'
ll            # now works as ls -lah
alias         # list all current aliases

# Make aliases permanent (add to ~/.bashrc)
echo "alias ll='ls -lah'" >> ~/.bashrc
source ~/.bashrc  # reload config

# Globbing (wildcards)
ls *.txt      # all .txt files
ls file?.log  # file1.log, fileA.log (? = single char)
ls [abc]*     # files starting with a, b, or c
ls file[0-9]  # file0 through file9

# Hidden files (start with .)
ls -a         # show all files including hidden
ls -la ~/.bash* # show bash config files
```

### RHEL/Rocky
```bash
# Check distro version
cat /etc/os-release
cat /etc/redhat-release  # RHEL-specific file

# Check kernel version
uname -r  # e.g., 5.14.0-284.el9.x86_64

# Explore filesystem hierarchy (same as Ubuntu)
ls -lh /
ls -lh /boot   # kernel and bootloader files
ls -lh /etc
ls -lh /var/log  # system logs

# RHEL-specific directories
ls -lh /etc/sysconfig  # RHEL uses this for network configs
ls -lh /usr/lib/systemd/system  # systemd unit files

# Navigation (same commands as Ubuntu)
cd /var/log
pwd
cd ../..
pwd

# Path and commands (same as Ubuntu)
echo $PATH
which python3  # might be /usr/bin/python3 or not installed

# History and aliases (same as Ubuntu)
history
!!
alias ll='ls -lah --color=auto'
echo "alias ll='ls -lah --color=auto'" >> ~/.bashrc
source ~/.bashrc

# DNF package manager check (covered in Module 06)
which dnf  # /usr/bin/dnf
```

### SUSE
```bash
# Check distro version
cat /etc/os-release
# Shows openSUSE Leap or SUSE Linux Enterprise

# Check kernel version
uname -r  # e.g., 5.14.21-150400.24.46-default

# Explore filesystem hierarchy (same structure)
ls -lh /
ls -lh /etc/sysconfig  # SUSE also uses sysconfig
ls -lh /srv            # SUSE uses /srv for service data

# Navigation (same as other distros)
cd /etc
ls -lh sysconfig/network  # SUSE network configs
cd ~

# Path and commands
echo $PATH
which zypper  # /usr/bin/zypper (SUSE package manager)

# History and aliases (same as Ubuntu/RHEL)
history
alias ll='ls -lah'
echo "alias ll='ls -lah'" >> ~/.bashrc
source ~/.bashrc
```

---

## Verify
```bash
# Confirm you're in your home directory
pwd
# Expected output: /home/<username> or /root (if root user)

# Verify alias works
ll
# Should show detailed file listing

# Check history is saving
history | wc -l
# Should show a number > 0

# Verify PATH includes /usr/bin and /usr/local/bin
echo $PATH | grep -o '/usr/bin'
echo $PATH | grep -o '/usr/local/bin'
# Both should print the path

# Confirm you can navigate
cd /tmp && pwd && cd ~ && pwd
# Should print /tmp then /home/<username>
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `command not found` | Binary not in $PATH or not installed | Use `which <command>` to check; install package if missing |
| `cd: no such file or directory` | Path doesn't exist or typo | Use `ls` to verify path; check capitalization (Linux is case-sensitive) |
| Alias doesn't persist after logout | Not added to ~/.bashrc | Add alias to ~/.bashrc and run `source ~/.bashrc` |
| `permission denied` when cd into dir | No execute permission on directory | Check with `ls -ld <dir>`; need `x` permission (covered in Module 04) |
| Tab completion doesn't work | bash-completion not installed | Install: `apt install bash-completion` (Ubuntu) or `dnf install bash-completion` (RHEL) |

---

## Cleanup
```bash
# Remove test aliases (if you created temporary ones)
unalias ll  # removes for current session only

# To permanently remove, edit ~/.bashrc
nano ~/.bashrc  # or vim
# Delete the alias line, then save
source ~/.bashrc
```

---

## Quick Quiz

1. What directory contains system configuration files?
2. What's the difference between `cd /etc` and `cd etc`?
3. How do you list all files (including hidden) in your home directory?
4. What command shows your command history?
5. What does the `~` symbol represent in a path?

---

**Next:** [Module 02: Help & Text Mastery](module-02-help-text.md)

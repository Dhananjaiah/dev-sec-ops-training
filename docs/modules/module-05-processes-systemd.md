# Module 05: Processes, Jobs, and Systemd

## Why it matters
Every running program is a process. Managing processes means controlling CPU, memory, starting/stopping services, and troubleshooting stuck applications. Systemd is the init system on modern Linux—it manages services, handles dependencies, and provides detailed logging. Mastering ps, systemctl, and journalctl is essential for daily operations.

## Prerequisites
**Packages/Tools:**
- procps (ps, top, kill) — pre-installed
- systemd — pre-installed (standard init system)
- htop (optional but recommended)
- tmux or screen (optional for session management)

**Files/Labs:**
- Root/sudo access for service management

## Cheat-Sheet
- `ps aux` — show all processes
- `ps -ef` — show all processes (different format)
- `top` — interactive process viewer
- `htop` — better interactive viewer (install separately)
- `pgrep <name>` — find process IDs by name
- `pkill <name>` — kill processes by name
- `kill <PID>` — send signal to process (default TERM)
- `kill -9 <PID>` — force kill (SIGKILL)
- `nice -n 10 <command>` — run with lower priority
- `renice -n 5 -p <PID>` — change priority of running process
- `jobs` — list background jobs
- `fg`, `bg` — foreground/background job control
- `systemctl start <service>` — start service
- `systemctl status <service>` — check service status
- `systemctl enable <service>` — start service on boot
- `journalctl -u <service>` — view service logs

---

## Commands & Labs

### Ubuntu/Debian
```bash
# ===== VIEWING PROCESSES =====
# Show all processes (BSD syntax)
ps aux
# USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND

# Show all processes (Unix syntax)
ps -ef
# UID PID PPID C STIME TTY TIME CMD

# Show process tree
ps auxf   # forest view
pstree    # better tree visualization

# Filter processes
ps aux | grep nginx
ps aux | grep ssh

# Show processes for current user
ps u

# Show processes for specific user
ps -u alice

# ===== INTERACTIVE PROCESS MONITORING =====
# Top (pre-installed)
top
# Press 'h' for help, 'q' to quit
# Press 'M' to sort by memory, 'P' for CPU, '1' to show all CPUs
# Press 'k' then PID to kill a process

# Htop (install first, better than top)
sudo apt install htop
htop
# F5 = tree view, F6 = sort, F9 = kill, F10 = quit

# ===== PROCESS CONTROL =====
# Find process by name
pgrep ssh
pgrep -u alice  # processes owned by alice

# Find process with details
pgrep -a nginx  # shows PID and command line

# Kill process by PID
kill 1234      # send SIGTERM (graceful shutdown)
kill -15 1234  # same as above (15 = SIGTERM)
kill -9 1234   # force kill (SIGKILL, ungraceful)

# Kill process by name
pkill nginx    # kills all nginx processes
pkill -u alice # kill all alice's processes (🚨 DANGER)

# Kill specific user session
pkill -KILL -u alice  # force kill all alice's processes

# Signals reference:
# SIGTERM (15) = graceful shutdown (default)
# SIGKILL (9) = immediate kill (can't be caught)
# SIGHUP (1) = reload config (many daemons)
# SIGSTOP (19) = pause process
# SIGCONT (18) = resume process

# Pause and resume process
kill -STOP 1234  # pause
kill -CONT 1234  # resume

# ===== PROCESS PRIORITY =====
# Run command with lower priority (nice -20 to 19, higher = lower priority)
nice -n 10 tar czf backup.tar.gz /home  # runs with +10 niceness

# Run with higher priority (requires root)
sudo nice -n -10 important-task

# Change priority of running process
renice -n 5 -p 1234  # set niceness to 5 for PID 1234

# View process priorities
ps -eo pid,ni,comm  # ni = nice value

# ===== BACKGROUND JOBS =====
# Run command in background
sleep 100 &
# [1] 12345 (job number, PID)

# List background jobs
jobs
# [1]+  Running   sleep 100 &

# Bring job to foreground
fg %1  # or just 'fg' for most recent

# Send foreground job to background
# Ctrl+Z (suspends), then:
bg %1  # resume in background

# Kill background job
kill %1  # or kill <PID>

# Disown job (continues after logout)
sleep 1000 &
disown

# Run command immune to hangup (survives logout)
nohup long-running-command &
# Output goes to nohup.out

# ===== TMUX/SCREEN (persistent sessions) =====
# Install tmux
sudo apt install tmux

# Start tmux session
tmux
# Now inside tmux session

# Detach from session (Ctrl+b, then d)
# Session continues running

# List sessions
tmux ls

# Attach to session
tmux attach -t 0  # attach to session 0

# Tmux key bindings (prefix Ctrl+b):
# Ctrl+b, c = new window
# Ctrl+b, n = next window
# Ctrl+b, p = previous window
# Ctrl+b, % = split pane vertically
# Ctrl+b, " = split pane horizontally
# Ctrl+b, arrow = switch pane
# Ctrl+b, d = detach

# ===== SYSTEMD BASICS =====
# List all units (services, sockets, timers, etc.)
systemctl list-units

# List all services
systemctl list-units --type=service

# List enabled services
systemctl list-unit-files --state=enabled

# Check service status
systemctl status ssh
systemctl status nginx

# Start service
sudo systemctl start nginx

# Stop service
sudo systemctl stop nginx

# Restart service (stop then start)
sudo systemctl restart nginx

# Reload config (without stopping, if supported)
sudo systemctl reload nginx

# Enable service (start on boot)
sudo systemctl enable nginx

# Disable service (don't start on boot)
sudo systemctl disable nginx

# Enable and start in one command
sudo systemctl enable --now nginx

# Check if service is enabled
systemctl is-enabled nginx

# Check if service is active
systemctl is-active nginx

# ===== SYSTEMD UNIT FILES =====
# System units location
ls /lib/systemd/system/    # or /usr/lib/systemd/system/
ls /etc/systemd/system/    # overrides and custom units

# View service unit file
systemctl cat nginx

# Edit service (creates override)
sudo systemctl edit nginx
# Opens editor with override snippet

# Edit full service file
sudo systemctl edit --full nginx

# Reload systemd after changes
sudo systemctl daemon-reload

# ===== SYSTEMD DEPENDENCIES =====
# Show dependencies (what this service needs)
systemctl list-dependencies nginx

# Show reverse dependencies (what needs this service)
systemctl list-dependencies nginx --reverse

# ===== SYSTEMD TARGETS (runlevels) =====
# Show current target
systemctl get-default
# graphical.target or multi-user.target

# Change default target
sudo systemctl set-default multi-user.target  # no GUI
sudo systemctl set-default graphical.target   # with GUI

# Switch to target (without reboot)
sudo systemctl isolate multi-user.target

# Common targets:
# poweroff.target = shutdown
# rescue.target = single-user mode
# multi-user.target = multi-user, no GUI
# graphical.target = multi-user with GUI

# ===== JOURNALCTL (systemd logs) =====
# View all logs
journalctl

# Follow logs in real-time
journalctl -f

# Show logs for specific service
journalctl -u nginx
journalctl -u ssh

# Follow service logs
journalctl -u nginx -f

# Show logs since boot
journalctl -b

# Show logs from previous boot
journalctl -b -1

# Show logs since specific time
journalctl --since "2024-01-15 10:00:00"
journalctl --since "1 hour ago"
journalctl --since today

# Show logs until specific time
journalctl --until "2024-01-15 12:00:00"

# Combine filters
journalctl -u nginx --since "10 minutes ago"

# Show logs with priority (errors and above)
journalctl -p err
journalctl -p warning

# Show kernel messages
journalctl -k

# Show logs for specific user
journalctl _UID=1000

# Output format
journalctl -o json-pretty  # JSON format
journalctl -o short-iso    # ISO timestamps

# Limit output
journalctl -n 50  # last 50 lines
journalctl -n 100 --no-pager  # disable pager

# Disk usage
journalctl --disk-usage

# Vacuum old logs (keep last 2 weeks)
sudo journalctl --vacuum-time=2weeks

# Vacuum by size (keep last 1GB)
sudo journalctl --vacuum-size=1G

# ===== CUSTOM SYSTEMD SERVICE =====
# Create simple service
sudo nano /etc/systemd/system/myapp.service

# Paste:
# [Unit]
# Description=My Application
# After=network.target
#
# [Service]
# Type=simple
# User=myuser
# ExecStart=/usr/local/bin/myapp
# Restart=on-failure
#
# [Install]
# WantedBy=multi-user.target

# Reload systemd
sudo systemctl daemon-reload

# Start service
sudo systemctl start myapp

# Enable on boot
sudo systemctl enable myapp
```

### RHEL/Rocky
```bash
# ===== PROCESSES (same as Ubuntu) =====
ps aux
top
sudo dnf install htop
htop

pgrep nginx
pkill nginx
kill -9 <PID>

# ===== SYSTEMD (same as Ubuntu) =====
systemctl status firewalld
sudo systemctl start httpd
sudo systemctl enable --now httpd

# RHEL service names differ:
# httpd (not apache2)
# firewalld (firewall)

# ===== JOURNALCTL (same as Ubuntu) =====
journalctl -u httpd
journalctl -f
journalctl --since "1 hour ago"

# Persistent logging (enabled by default on RHEL)
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

### SUSE
```bash
# ===== PROCESSES (same) =====
ps aux
top
sudo zypper install htop

# ===== SYSTEMD (same) =====
systemctl status apache2  # SUSE uses apache2
sudo systemctl start nginx
sudo systemctl enable nginx

# ===== JOURNALCTL (same) =====
journalctl -u apache2
journalctl -f
```

---

## Verify
```bash
# Check systemd is running
systemctl status
# Expected: State: running

# Verify journalctl works
journalctl -n 10
# Expected: last 10 log entries

# Test process commands
ps aux | head -5
pgrep systemd
# Expected: PID 1 or similar

# Test job control
sleep 60 &
jobs
# Expected: [1]+ Running
kill %1
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `kill: no such process` | Process already dead | Use `ps` or `pgrep` to verify PID |
| `systemctl: command not found` | Not using systemd init | Check `ps -p 1`; if not systemd, use `service` or `init` |
| Service fails to start | Dependency missing or config error | `journalctl -xe` shows detailed errors |
| `Failed to start <service>: Unit not found` | Service not installed or typo | Use `systemctl list-units --type=service` to find correct name |
| Logs not persisting across reboots | Journal not persistent | `sudo mkdir /var/log/journal && sudo systemctl restart systemd-journald` |
| Can't kill process | Process stuck in uninterruptible sleep (D state) | Check `ps aux | grep " D "` often I/O wait; reboot may be needed |

---

## Cleanup
```bash
# Kill any background jobs
jobs
kill %1 2>/dev/null || true

# If you created test service, remove it
sudo systemctl stop myapp 2>/dev/null || true
sudo systemctl disable myapp 2>/dev/null || true
sudo rm /etc/systemd/system/myapp.service 2>/dev/null || true
sudo systemctl daemon-reload
```

---

## Quick Quiz

1. What's the difference between `kill` and `kill -9`?
2. How do you make a service start automatically on boot?
3. What command shows real-time logs for the nginx service?
4. What's the difference between `systemctl restart` and `systemctl reload`?
5. How do you run a command that survives terminal logout?

---

**Next:** [Module 06: Packaging & Repositories](module-06-packaging.md)

# Systemd & Journald Cheatsheet

## Systemctl - Service Management

### Service Operations
```bash
# Start/Stop/Restart
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx              # reload config without restart
systemctl reload-or-restart nginx   # reload if possible, else restart

# Status
systemctl status nginx
systemctl is-active nginx           # running?
systemctl is-enabled nginx          # starts on boot?
systemctl is-failed nginx           # failed?

# Enable/Disable (boot behavior)
systemctl enable nginx              # start on boot
systemctl disable nginx             # don't start on boot
systemctl enable --now nginx        # enable and start
systemctl disable --now nginx       # disable and stop

# Mask/Unmask (prevent service from starting)
systemctl mask nginx                # cannot be started
systemctl unmask nginx              # allow starting again
```

### Listing Services
```bash
# List all units
systemctl list-units
systemctl list-units --all          # include inactive

# List services only
systemctl list-units --type=service
systemctl list-units --type=service --state=running
systemctl list-units --type=service --state=failed

# List unit files
systemctl list-unit-files
systemctl list-unit-files --type=service
systemctl list-unit-files --state=enabled
systemctl list-unit-files --state=disabled

# List sockets, timers, targets
systemctl list-units --type=socket
systemctl list-units --type=timer
systemctl list-units --type=target
```

### Unit Files
```bash
# View unit file
systemctl cat nginx
systemctl cat sshd.service

# Edit unit file (creates override in /etc/systemd/system/)
systemctl edit nginx                # drop-in override
systemctl edit --full nginx         # edit entire file

# Show unit file location
systemctl show -p FragmentPath nginx

# Reload systemd (after editing unit files)
systemctl daemon-reload

# Show unit properties
systemctl show nginx
systemctl show nginx -p ActiveState,LoadState
```

### Dependencies
```bash
# Show dependencies
systemctl list-dependencies nginx
systemctl list-dependencies nginx --all
systemctl list-dependencies nginx --reverse  # what depends on this
```

### System State
```bash
# Reboot/Shutdown
systemctl reboot
systemctl poweroff
systemctl halt
systemctl suspend
systemctl hibernate

# System state
systemctl is-system-running         # running, degraded, etc.

# Rescue/Emergency mode
systemctl rescue                    # single-user mode
systemctl emergency                 # minimal shell
```

### Targets (Runlevels)
```bash
# Get current target
systemctl get-default

# Set default target
systemctl set-default multi-user.target     # CLI only
systemctl set-default graphical.target      # GUI

# Switch to target
systemctl isolate multi-user.target
systemctl isolate graphical.target

# Common targets:
# poweroff.target     = shutdown
# rescue.target       = single-user
# multi-user.target   = multi-user CLI (runlevel 3)
# graphical.target    = multi-user GUI (runlevel 5)
```

---

## Journalctl - Log Viewer

### Basic Viewing
```bash
# View all logs
journalctl

# Follow logs (real-time)
journalctl -f

# Reverse order (newest first)
journalctl -r

# Last N lines
journalctl -n 50                    # last 50 lines
journalctl -n 100 --no-pager        # disable pager
```

### Filter by Service
```bash
# Logs for specific service
journalctl -u nginx
journalctl -u nginx.service         # same
journalctl -u ssh

# Multiple services
journalctl -u nginx -u mysql

# Follow service logs
journalctl -u nginx -f
journalctl -u nginx -f -n 0         # only new entries
```

### Filter by Time
```bash
# Since/Until (absolute time)
journalctl --since "2024-01-15 10:00:00"
journalctl --until "2024-01-15 12:00:00"
journalctl --since "2024-01-15" --until "2024-01-16"

# Relative time
journalctl --since "1 hour ago"
journalctl --since "30 min ago"
journalctl --since today
journalctl --since yesterday
journalctl --since "2 days ago"

# Combine time and service
journalctl -u nginx --since "10 minutes ago"
```

### Filter by Boot
```bash
# Current boot
journalctl -b
journalctl -b 0                     # same

# Previous boot
journalctl -b -1
journalctl -b -2                    # 2 boots ago

# List boots
journalctl --list-boots

# Specific boot
journalctl -b a1b2c3d4...           # boot ID from list-boots
```

### Filter by Priority
```bash
# By priority level
journalctl -p err                   # errors and above
journalctl -p warning               # warnings and above
journalctl -p info
journalctl -p debug

# Priority levels (0-7):
# emerg (0)   = system unusable
# alert (1)   = action required
# crit (2)    = critical
# err (3)     = error
# warning (4) = warning
# notice (5)  = normal but significant
# info (6)    = informational
# debug (7)   = debug messages

# Range
journalctl -p err..warning          # errors and warnings only
```

### Filter by User/Process
```bash
# By user (UID)
journalctl _UID=1000
journalctl _UID=0                   # root

# By process
journalctl _PID=1234

# By executable
journalctl _EXE=/usr/sbin/nginx

# By command
journalctl _COMM=nginx
```

### Kernel Messages
```bash
# Kernel logs only
journalctl -k
journalctl -k -b                    # kernel logs from current boot
journalctl -k -b -1                 # kernel logs from previous boot
journalctl -k --since "10 min ago"
```

### Output Formats
```bash
# Different output formats
journalctl -o short                 # default
journalctl -o short-iso             # ISO 8601 timestamps
journalctl -o short-precise         # precise timestamps
journalctl -o json                  # JSON (one per line)
journalctl -o json-pretty           # formatted JSON
journalctl -o verbose               # all fields
journalctl -o cat                   # message only (no metadata)

# Export for analysis
journalctl -o json > logs.json
```

### Disk Usage
```bash
# Show disk usage
journalctl --disk-usage

# Vacuum (clean old logs)
journalctl --vacuum-time=2weeks     # keep last 2 weeks
journalctl --vacuum-size=1G         # keep last 1GB
journalctl --vacuum-files=10        # keep 10 newest files

# Verify journal integrity
journalctl --verify
```

### Advanced Filters
```bash
# Combine multiple filters (AND)
journalctl -u nginx -p err --since "1 hour ago"

# Multiple boots
journalctl -b -b -1                 # current and previous boot

# Follow multiple services
journalctl -u nginx -u mysql -f

# Grep within journalctl
journalctl -u nginx | grep ERROR
journalctl -u nginx --grep ERROR    # more efficient (journald filters)

# Case-insensitive grep
journalctl -u nginx --grep=error -i
```

### Persistent Logs
```bash
# Make logs persistent (survive reboot)
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald

# Configure persistence (edit journald.conf)
sudo nano /etc/systemd/journald.conf
# Set: Storage=persistent

# Restart journald
sudo systemctl restart systemd-journald

# Verify persistence
ls /var/log/journal/
```

---

## Common Workflows

### Debug Service Failure
```bash
# Check service status
systemctl status nginx

# View recent logs
journalctl -u nginx -n 50

# View errors only
journalctl -u nginx -p err

# Follow logs while restarting
journalctl -u nginx -f
# In another terminal:
systemctl restart nginx
```

### Find Boot Issues
```bash
# Check last boot
journalctl -b -p err

# Compare current vs previous boot
journalctl -b 0 -p warning
journalctl -b -1 -p warning
```

### Monitor System
```bash
# Watch all errors system-wide
journalctl -f -p err

# Watch specific service
journalctl -u nginx -f

# Watch kernel messages
journalctl -kf
```

### Investigate Performance Issues
```bash
# High-priority messages since boot
journalctl -b -p warning

# Messages from specific time when issue occurred
journalctl --since "14:30" --until "14:35"

# All errors in last hour
journalctl -p err --since "1 hour ago"
```

---

## Tips & Tricks

1. **Always use `-f` carefully** - can be overwhelming on busy systems
2. **Combine filters** for precise results: `-u service -p err --since "10m ago"`
3. **Use `--no-pager`** for scripting: `journalctl --no-pager | grep ...`
4. **Export to file** for analysis: `journalctl -u nginx > nginx.log`
5. **Check disk usage** regularly: `journalctl --disk-usage`
6. **Vacuum old logs** to save space: `journalctl --vacuum-time=1month`
7. **Use ISO timestamps** for clarity: `journalctl -o short-iso`
8. **Follow before restarting** service to catch startup errors
9. **Remember: `-b -1` is previous boot**, `-b 0` is current
10. **Priority filters are inclusive**: `-p err` shows err, crit, alert, emerg

---

## Quick Reference

| Task | Command |
|------|---------|
| Start service | `systemctl start nginx` |
| Enable service | `systemctl enable nginx` |
| Service status | `systemctl status nginx` |
| Service logs | `journalctl -u nginx` |
| Follow logs | `journalctl -u nginx -f` |
| Errors only | `journalctl -u nginx -p err` |
| Last hour | `journalctl --since "1 hour ago"` |
| Previous boot | `journalctl -b -1` |
| Kernel logs | `journalctl -k` |
| Disk usage | `journalctl --disk-usage` |
| Clean old logs | `journalctl --vacuum-time=2weeks` |

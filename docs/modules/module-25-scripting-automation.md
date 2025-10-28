# Module 25: Scripting & Automation

## Why it matters
Bash scripting automates repetitive tasks, standardizes procedures, and saves hours of manual work. A 10-line script can replace 100 manual commands. This module teaches practical scripting: loops, conditionals, functions, and real-world admin utilities.

## Prerequisites
**Packages/Tools:**
- bash — pre-installed
- Text editor (vim, nano)

**Files/Labs:**
- Root/sudo access for some examples

## Cheat-Sheet
- `#!/bin/bash` — shebang (first line of script)
- `chmod +x script.sh` — make executable
- `./script.sh` — run script
- `$1, $2, $3` — positional arguments
- `$#` — number of arguments
- `$@` — all arguments
- `if [ condition ]; then ... fi` — conditional
- `for i in list; do ... done` — loop
- `function name() { ... }` — function definition

---

## Commands & Labs

### All Distros (Bash is universal)

```bash
# ===== SCRIPT BASICS =====
# Create first script
cat > hello.sh <<'EOF'
#!/bin/bash
# Simple hello world script
echo "Hello, World!"
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "Today is: $(date +%Y-%m-%d)"
EOF

# Make executable
chmod +x hello.sh

# Run script
./hello.sh

# Run with bash (doesn't need +x)
bash hello.sh

# ===== VARIABLES =====
cat > variables.sh <<'EOF'
#!/bin/bash

# Define variables
NAME="Alice"
AGE=30
CITY="New York"

# Use variables
echo "Name: $NAME"
echo "Age: $AGE"
echo "City: ${CITY}"  # curly braces optional but safer

# Command substitution
TODAY=$(date +%Y-%m-%d)
USER_COUNT=$(who | wc -l)

echo "Today: $TODAY"
echo "Logged in users: $USER_COUNT"

# Environment variables
echo "Home directory: $HOME"
echo "Current user: $USER"
echo "Shell: $SHELL"
echo "Path: $PATH"

# Read user input
echo -n "Enter your name: "
read USERNAME
echo "Hello, $USERNAME!"
EOF

chmod +x variables.sh
./variables.sh

# ===== ARGUMENTS & PARAMETERS =====
cat > args.sh <<'EOF'
#!/bin/bash

# Positional parameters
echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "All arguments: $@"
echo "Number of arguments: $#"

# Check if arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <arg1> <arg2> ..."
    exit 1
fi

# Loop through arguments
echo "Arguments:"
for arg in "$@"; do
    echo "  - $arg"
done
EOF

chmod +x args.sh
./args.sh one two three

# ===== CONDITIONALS (IF/ELSE) =====
cat > conditionals.sh <<'EOF'
#!/bin/bash

# File tests
if [ -f /etc/passwd ]; then
    echo "/etc/passwd exists"
fi

if [ ! -f /tmp/nonexistent ]; then
    echo "/tmp/nonexistent does not exist"
fi

if [ -d /var/log ]; then
    echo "/var/log is a directory"
fi

# String comparisons
NAME="Alice"
if [ "$NAME" = "Alice" ]; then
    echo "Name is Alice"
fi

if [ "$NAME" != "Bob" ]; then
    echo "Name is not Bob"
fi

if [ -z "$EMPTY_VAR" ]; then
    echo "EMPTY_VAR is empty or unset"
fi

# Numeric comparisons
AGE=25
if [ $AGE -gt 18 ]; then
    echo "Adult"
elif [ $AGE -eq 18 ]; then
    echo "Just turned 18"
else
    echo "Minor"
fi

# Multiple conditions (AND/OR)
if [ $AGE -gt 18 ] && [ $AGE -lt 65 ]; then
    echo "Working age"
fi

if [ "$NAME" = "Alice" ] || [ "$NAME" = "Bob" ]; then
    echo "Name is Alice or Bob"
fi
EOF

chmod +x conditionals.sh
./conditionals.sh

# ===== LOOPS =====
cat > loops.sh <<'EOF'
#!/bin/bash

# For loop (list)
echo "Counting 1 to 5:"
for i in 1 2 3 4 5; do
    echo "  Number: $i"
done

# For loop (range)
echo "Counting 1 to 10:"
for i in {1..10}; do
    echo -n "$i "
done
echo

# For loop (files)
echo "Log files in /var/log:"
for file in /var/log/*.log; do
    if [ -f "$file" ]; then
        echo "  $(basename $file)"
    fi
done

# While loop
echo "While loop countdown:"
COUNT=5
while [ $COUNT -gt 0 ]; do
    echo "  $COUNT"
    COUNT=$((COUNT - 1))
done
echo "  Blast off!"

# Until loop (opposite of while)
echo "Until loop:"
NUM=1
until [ $NUM -gt 5 ]; do
    echo "  $NUM"
    NUM=$((NUM + 1))
done

# Break and continue
echo "Break example:"
for i in {1..10}; do
    if [ $i -eq 6 ]; then
        break
    fi
    echo -n "$i "
done
echo
EOF

chmod +x loops.sh
./loops.sh

# ===== FUNCTIONS =====
cat > functions.sh <<'EOF'
#!/bin/bash

# Define function
greet() {
    echo "Hello, $1!"
}

# Call function
greet "Alice"
greet "Bob"

# Function with return value
add() {
    local result=$(($1 + $2))
    echo $result
}

sum=$(add 5 3)
echo "5 + 3 = $sum"

# Function with local variables
calculate() {
    local num1=$1
    local num2=$2
    local operation=$3
    
    case $operation in
        add)
            echo $(($num1 + $num2))
            ;;
        subtract)
            echo $(($num1 - $num2))
            ;;
        multiply)
            echo $(($num1 * $num2))
            ;;
        *)
            echo "Unknown operation"
            return 1
            ;;
    esac
}

echo "10 + 5 = $(calculate 10 5 add)"
echo "10 - 5 = $(calculate 10 5 subtract)"
echo "10 * 5 = $(calculate 10 5 multiply)"
EOF

chmod +x functions.sh
./functions.sh

# ===== CASE STATEMENTS =====
cat > case.sh <<'EOF'
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <start|stop|restart|status>"
    exit 1
fi

ACTION=$1

case $ACTION in
    start)
        echo "Starting service..."
        ;;
    stop)
        echo "Stopping service..."
        ;;
    restart)
        echo "Restarting service..."
        ;;
    status)
        echo "Checking status..."
        ;;
    *)
        echo "Unknown action: $ACTION"
        echo "Valid actions: start, stop, restart, status"
        exit 1
        ;;
esac
EOF

chmod +x case.sh
./case.sh start
./case.sh unknown

# ===== GETOPTS (Command-line options) =====
cat > getopts.sh <<'EOF'
#!/bin/bash

# Default values
VERBOSE=false
OUTPUT_FILE=""
MODE="default"

# Parse options
while getopts "vo:m:h" opt; do
    case $opt in
        v)
            VERBOSE=true
            ;;
        o)
            OUTPUT_FILE=$OPTARG
            ;;
        m)
            MODE=$OPTARG
            ;;
        h)
            echo "Usage: $0 [-v] [-o output_file] [-m mode]"
            echo "  -v: Verbose mode"
            echo "  -o: Output file"
            echo "  -m: Mode (default, advanced)"
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Display parsed options
echo "Verbose: $VERBOSE"
echo "Output file: ${OUTPUT_FILE:-none}"
echo "Mode: $MODE"
EOF

chmod +x getopts.sh
./getopts.sh -v -o output.txt -m advanced
./getopts.sh -h

# ===== PRACTICAL EXAMPLE 1: Log Cleaner =====
cat > log-cleaner.sh <<'EOF'
#!/bin/bash
# Clean old log files

LOG_DIR="/var/log"
DAYS_OLD=30
DRY_RUN=false

# Parse options
while getopts "d:n" opt; do
    case $opt in
        d)
            DAYS_OLD=$OPTARG
            ;;
        n)
            DRY_RUN=true
            ;;
    esac
done

echo "Cleaning logs older than $DAYS_OLD days in $LOG_DIR"

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN - no files will be deleted"
    find "$LOG_DIR" -name "*.log" -type f -mtime +$DAYS_OLD -ls
else
    echo "Deleting files..."
    find "$LOG_DIR" -name "*.log" -type f -mtime +$DAYS_OLD -delete
    echo "Done"
fi
EOF

chmod +x log-cleaner.sh
./log-cleaner.sh -n -d 30  # dry run

# ===== PRACTICAL EXAMPLE 2: Bulk User Creator =====
cat > create-users.sh <<'EOF'
#!/bin/bash
# Create users from CSV file
# CSV format: username,fullname,group

if [ $# -eq 0 ]; then
    echo "Usage: $0 <users.csv>"
    exit 1
fi

CSV_FILE=$1

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: File $CSV_FILE not found"
    exit 1
fi

# Read CSV line by line
while IFS=, read -r username fullname group; do
    # Skip header line
    if [ "$username" = "username" ]; then
        continue
    fi
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists, skipping"
        continue
    fi
    
    # Create user
    sudo useradd -m -c "$fullname" -G "$group" "$username"
    
    # Set temp password (user must change on first login)
    echo "$username:TempPass123!" | sudo chpasswd
    sudo chage -d 0 "$username"
    
    echo "Created user: $username ($fullname) in group $group"
done < "$CSV_FILE"

echo "User creation complete"
EOF

# Create sample CSV
cat > users.csv <<'EOF'
username,fullname,group
alice,Alice Smith,developers
bob,Bob Jones,developers
charlie,Charlie Brown,admins
EOF

chmod +x create-users.sh
# ./create-users.sh users.csv  # run with sudo

# ===== PRACTICAL EXAMPLE 3: System Health Check =====
cat > health-check.sh <<'EOF'
#!/bin/bash
# System health check script

echo "===== System Health Check ====="
echo "Date: $(date)"
echo

# CPU Load
echo "CPU Load:"
uptime
echo

# Memory Usage
echo "Memory Usage:"
free -h
echo

# Disk Usage
echo "Disk Usage:"
df -h | grep -vE '^Filesystem|tmpfs|cdrom'
echo

# Check for disks > 80% full
echo "Disks > 80% full:"
df -h | awk '$5 > 80 {print $0}'
echo

# Top 5 processes by CPU
echo "Top 5 CPU processes:"
ps aux --sort=-%cpu | head -6
echo

# Top 5 processes by Memory
echo "Top 5 Memory processes:"
ps aux --sort=-%mem | head -6
echo

# Check critical services
echo "Critical Services:"
for service in ssh nginx mysql; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo "  $service: ✓ running"
    else
        echo "  $service: ✗ not running or not installed"
    fi
done
echo

# Failed systemd services
echo "Failed Services:"
systemctl list-units --state=failed --no-pager
EOF

chmod +x health-check.sh
./health-check.sh

# ===== ERROR HANDLING =====
cat > error-handling.sh <<'EOF'
#!/bin/bash
# Exit on error
set -e  # exit if any command fails
set -u  # exit if using undefined variable
set -o pipefail  # exit if any command in pipe fails

# Error function
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run as root"
fi

# Check if file exists
FILE="/etc/passwd"
[ -f "$FILE" ] || error_exit "File $FILE not found"

echo "All checks passed"
EOF

chmod +x error-handling.sh
# ./error-handling.sh  # will fail if not root
```

---

## Verify
```bash
# Test basic script
cat > test.sh <<'EOF'
#!/bin/bash
echo "Script works!"
EOF
chmod +x test.sh
./test.sh
# Expected: Script works!

# Test arguments
cat > test-args.sh <<'EOF'
#!/bin/bash
echo "Args: $#"
echo "First: $1"
EOF
chmod +x test-args.sh
./test-args.sh hello world
# Expected: Args: 2, First: hello
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Permission denied` | Script not executable | `chmod +x script.sh` |
| `No such file or directory` | Wrong path or shebang | Check `#!/bin/bash` line; use absolute path |
| `Syntax error near unexpected token` | Missing quotes, brackets | Check syntax; use `bash -n script.sh` to test |
| Variables empty | Not exported or wrong scope | Use `export VAR=value` for subshells |
| Script runs but does nothing | Logic error | Add `set -x` at top for debug output |

---

## Cleanup
```bash
rm -f hello.sh variables.sh args.sh conditionals.sh loops.sh functions.sh case.sh getopts.sh log-cleaner.sh create-users.sh health-check.sh error-handling.sh test.sh test-args.sh users.csv
```

---

## Quick Quiz

1. What's the purpose of the shebang (`#!/bin/bash`)?
2. How do you access the first command-line argument in a script?
3. What's the difference between `$@` and `$*`?
4. How do you make a script exit immediately if any command fails?
5. What does `local` do in a function?

---

**Next:** [Module 26: Ansible (Admin Basics)](module-26-ansible.md)

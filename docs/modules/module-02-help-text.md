# Module 02: Help & Text Mastery

## Why it matters
Linux administration is 80% text processing: reading logs, parsing configs, extracting data. Mastering grep, sed, awk, and find makes you 10x faster. Learning to use man pages and built-in help means you never get stuck. These are the most-used commands after ls and cd.

## Prerequisites
**Packages/Tools:**
- coreutils (pre-installed: cat, head, tail, sort, cut, etc.)
- grep, sed, awk (pre-installed)
- findutils (find, locate)
- less, nano, vim
- Optional: ripgrep (faster grep)

**Files/Labs:**
- Create sample text files for practice

## Cheat-Sheet
- `man <command>` — show manual page (press q to quit)
- `<command> --help` — quick help summary
- `apropos <keyword>` — search man pages by keyword
- `grep <pattern> <file>` — search for pattern in file
- `grep -r <pattern> <dir>` — recursive search in directory
- `sed 's/old/new/' <file>` — replace text (stream editor)
- `awk '{print $1}' <file>` — extract columns
- `find <dir> -name <pattern>` — find files by name
- `head -n 10 <file>` — show first 10 lines
- `tail -f <file>` — follow file in real-time (logs)
- `wc -l <file>` — count lines

---

## Commands & Labs

### Ubuntu/Debian
```bash
# Install optional tools
sudo apt update
sudo apt install ripgrep vim-nox  # ripgrep (rg) is optional but fast

# Create test data
mkdir -p ~/labs/text-practice
cd ~/labs/text-practice
cat > sample.log <<'EOF'
2024-01-15 10:23:45 INFO User alice logged in
2024-01-15 10:24:12 ERROR Failed to connect to database
2024-01-15 10:24:50 INFO User bob logged in
2024-01-15 10:25:33 ERROR Disk space low on /var
2024-01-15 10:26:15 WARN High memory usage detected
EOF

cat > users.csv <<'EOF'
alice,alice@example.com,Developer
bob,bob@example.com,Admin
charlie,charlie@example.com,Manager
EOF

# ===== MAN PAGES =====
man ls        # full documentation for ls (press q to quit)
man -k user   # search for man pages about "user"
apropos file  # same as man -k file

# Navigate man pages: arrow keys, PgUp/PgDn, / to search, n for next match, q to quit

# ===== GREP (search text) =====
grep ERROR sample.log         # lines containing ERROR
grep -i error sample.log      # case-insensitive
grep -v INFO sample.log       # invert match (exclude INFO lines)
grep -c ERROR sample.log      # count matching lines
grep -n ERROR sample.log      # show line numbers
grep -A 2 ERROR sample.log    # show 2 lines After match
grep -B 1 ERROR sample.log    # show 1 line Before match
grep -C 1 ERROR sample.log    # show 1 line of Context (before and after)

# Recursive search
grep -r "database" /var/log   # search all files in /var/log (needs sudo for some logs)
sudo grep -r "Failed" /var/log/

# Regular expressions
grep '^ERROR' sample.log      # lines starting with ERROR
grep 'logged in$' sample.log  # lines ending with "logged in"
grep 'User [a-z]*' sample.log # User followed by any lowercase letters

# Extended regex (egrep or grep -E)
grep -E 'ERROR|WARN' sample.log  # lines with ERROR or WARN
grep -E '[0-9]{2}:[0-9]{2}' sample.log  # times like 10:23

# ===== SED (stream editor - find and replace) =====
sed 's/ERROR/CRITICAL/' sample.log          # replace first ERROR per line (doesn't modify file)
sed 's/ERROR/CRITICAL/g' sample.log         # replace all occurrences (g = global)
sed -i 's/ERROR/CRITICAL/g' sample.log      # modify file in-place (🚨 careful!)
sed -n '2,4p' sample.log                    # print lines 2–4 only
sed '/INFO/d' sample.log                    # delete lines containing INFO

# Restore sample.log
cat > sample.log <<'EOF'
2024-01-15 10:23:45 INFO User alice logged in
2024-01-15 10:24:12 ERROR Failed to connect to database
2024-01-15 10:24:50 INFO User bob logged in
2024-01-15 10:25:33 ERROR Disk space low on /var
2024-01-15 10:26:15 WARN High memory usage detected
EOF

# ===== AWK (column processing) =====
awk '{print $1}' sample.log               # print first column (date)
awk '{print $1, $2}' sample.log           # print date and time
awk '{print $4, $5, $6, $7}' sample.log   # print from 4th column onward
awk '/ERROR/ {print $0}' sample.log       # print full lines with ERROR (like grep)
awk -F, '{print $1, $2}' users.csv        # use comma as delimiter, print columns 1–2
awk -F, 'NR>1 {print $1}' users.csv       # skip header line, print usernames

# Sum numbers (example: calculate total size)
echo -e "100\n200\n300" > sizes.txt
awk '{sum+=$1} END {print sum}' sizes.txt  # prints 600

# ===== FIND (search files) =====
find /etc -name "*.conf"                   # find all .conf files (needs sudo for full access)
sudo find /etc -name "*.conf"
find ~ -name "*.log"                       # find .log files in home
find /var/log -type f -name "*.log"        # files only (not directories)
find /tmp -type d                          # directories only
find ~ -mtime -7                           # modified in last 7 days
find ~ -size +10M                          # files larger than 10 MB
find /var/log -name "*.log" -exec grep -l ERROR {} \;  # find logs with ERROR

# LOCATE (faster but needs updated database)
sudo updatedb          # update locate database (run weekly via cron)
locate passwd          # find all files named passwd
locate -i readme       # case-insensitive

# ===== HEAD / TAIL =====
head sample.log              # first 10 lines
head -n 3 sample.log         # first 3 lines
tail sample.log              # last 10 lines
tail -n 2 sample.log         # last 2 lines
tail -f /var/log/syslog      # follow log in real-time (Ctrl+C to stop)

# ===== WC (word count) =====
wc sample.log                # lines, words, bytes
wc -l sample.log             # lines only
wc -w sample.log             # words only

# ===== SORT / UNIQ =====
sort sample.log              # alphabetical sort
sort -r sample.log           # reverse sort
sort -k 3 sample.log         # sort by 3rd column
sort -u sample.log           # sort and remove duplicates
awk '{print $4}' sample.log | sort | uniq  # unique log levels

# ===== CUT / PASTE / JOIN =====
cut -d, -f1 users.csv        # extract 1st field (delimiter = comma)
cut -d, -f1,2 users.csv      # extract fields 1 and 2
awk '{print $1}' sample.log | paste -sd ','  # join dates with commas

# ===== TR (translate/delete characters) =====
echo "HELLO" | tr 'A-Z' 'a-z'  # convert to lowercase
cat users.csv | tr ',' '\t'     # replace commas with tabs
echo "hello  world" | tr -s ' ' # squeeze multiple spaces to one

# ===== XARGS (build commands from input) =====
find ~ -name "*.tmp" | xargs rm           # delete all .tmp files (🚨 DANGER)
echo "file1.txt file2.txt" | xargs touch  # create files
ls *.txt | xargs -I {} cp {} {}.bak       # backup all .txt files

# ===== EDITORS =====
# Nano (beginner-friendly)
nano sample.log
# Ctrl+O to save, Ctrl+X to exit, Ctrl+K to cut line, Ctrl+U to paste

# Vim (powerful but steep learning curve)
vim sample.log
# Press 'i' to enter insert mode, Esc to exit insert mode
# :w to save, :q to quit, :wq to save and quit, :q! to quit without saving
# /searchterm to search, n for next match
# dd to delete line, yy to copy line, p to paste

# Learn vim interactively
vimtutor  # built-in tutorial (30 minutes)
```

### RHEL/Rocky
```bash
# Install optional tools
sudo dnf install ripgrep vim-enhanced

# All commands identical to Ubuntu section above
# RHEL uses /var/log/messages instead of /var/log/syslog for general logs
tail -f /var/log/messages  # follow system log (needs sudo)
sudo tail -f /var/log/messages

# Example: search for SELinux denials
sudo grep -i 'avc.*denied' /var/log/audit/audit.log

# Example: find all systemd service files
find /usr/lib/systemd/system -name "*.service"
```

### SUSE
```bash
# Install optional tools
sudo zypper install ripgrep vim

# All commands same as Ubuntu/RHEL
# SUSE also uses /var/log/messages
tail -f /var/log/messages

# Example: find YaST configs
find /etc/sysconfig -name "network*"
```

---

## Verify
```bash
# Test grep
grep ERROR sample.log | wc -l
# Expected: 2

# Test sed
sed 's/ERROR/CRITICAL/' sample.log | grep CRITICAL | wc -l
# Expected: 2

# Test awk
awk -F, '{print $1}' users.csv | wc -l
# Expected: 3

# Test find
find ~/labs/text-practice -name "*.log" | wc -l
# Expected: 1

# Test head/tail
head -n 1 sample.log
# Expected: first line with alice

tail -n 1 sample.log
# Expected: last line with WARN

# Verify man pages work
man ls | head -n 5
# Should show LS(1) manual page header
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `grep: invalid option` | Using GNU grep syntax on BSD systems | Check `man grep` for your system's syntax |
| `sed -i` corrupts file | Syntax error in sed command | Always test without `-i` first; use `sed 's/old/new/' file > newfile` |
| `find: permission denied` | No access to directories | Use `sudo` or add `2>/dev/null` to hide errors: `find / -name "*.conf" 2>/dev/null` |
| `tail -f` shows nothing | File not being written to | Check file path; use `tail -n 20 -f` to see last 20 lines first |
| Vim won't quit | In insert mode or unsaved changes | Press `Esc` then `:q!` to force quit without saving |
| `locate` finds nothing | Database not updated | Run `sudo updatedb` then try again |

---

## Cleanup
```bash
# Remove test files
rm -rf ~/labs/text-practice
```

---

## Quick Quiz

1. How do you search for "error" (case-insensitive) in all files under /var/log?
2. What's the difference between `grep ERROR file` and `grep -v ERROR file`?
3. How do you replace all occurrences of "foo" with "bar" in file.txt without modifying the file?
4. What command shows the last 15 lines of a file?
5. How do you exit Vim without saving changes?

---

**Next:** [Module 03: Users, Groups, Identity & Access](module-03-users-groups.md)

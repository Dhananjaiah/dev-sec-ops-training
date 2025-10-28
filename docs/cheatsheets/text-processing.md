# Text Processing Cheatsheet

## Grep - Search Text

```bash
# Basic search
grep "pattern" file.txt
grep -i "pattern" file.txt        # case-insensitive
grep -v "pattern" file.txt        # invert match (exclude)
grep -r "pattern" /path           # recursive search
grep -n "pattern" file.txt        # show line numbers
grep -c "pattern" file.txt        # count matches

# Context
grep -A 3 "pattern" file.txt      # 3 lines after
grep -B 2 "pattern" file.txt      # 2 lines before
grep -C 2 "pattern" file.txt      # 2 lines context (before & after)

# Regular expressions
grep "^ERROR" file.txt            # lines starting with ERROR
grep "error$" file.txt            # lines ending with error
grep "ERROR|WARN" file.txt        # ERROR or WARN (use -E)
grep -E "[0-9]{3}" file.txt       # 3 digits

# Multiple files
grep "pattern" *.log
grep -l "pattern" *.log           # list filenames only
grep -h "pattern" *.log           # hide filenames in output

# Practical examples
grep -r "TODO" .                  # find all TODOs in code
sudo grep -i "failed" /var/log/auth.log  # failed logins
ps aux | grep nginx               # find nginx processes
```

## Sed - Stream Editor

```bash
# Substitute (find & replace)
sed 's/old/new/' file.txt                 # first occurrence per line
sed 's/old/new/g' file.txt                # all occurrences (global)
sed 's/old/new/2' file.txt                # 2nd occurrence per line
sed -i 's/old/new/g' file.txt             # modify file in-place

# Case-insensitive replace
sed 's/error/ERROR/gi' file.txt

# Delete lines
sed '/pattern/d' file.txt                 # delete matching lines
sed '3d' file.txt                         # delete line 3
sed '2,5d' file.txt                       # delete lines 2-5
sed '/^$/d' file.txt                      # delete empty lines
sed '/^#/d' file.txt                      # delete comments

# Print specific lines
sed -n '10p' file.txt                     # print line 10
sed -n '5,10p' file.txt                   # print lines 5-10
sed -n '/ERROR/p' file.txt                # print matching lines

# Multiple commands
sed -e 's/foo/bar/' -e 's/old/new/' file.txt
sed 's/foo/bar/; s/old/new/' file.txt

# Practical examples
sed 's/#.*$//' config.conf                # remove comments
sed '/^$/d' file.txt                      # remove blank lines
sed -n '/START/,/END/p' file.txt          # print between patterns
```

## Awk - Column Processing

```bash
# Print columns
awk '{print $1}' file.txt                 # first column
awk '{print $1, $3}' file.txt             # columns 1 and 3
awk '{print $NF}' file.txt                # last column
awk '{print $0}' file.txt                 # entire line

# Custom delimiter
awk -F: '{print $1}' /etc/passwd          # use : as delimiter
awk -F, '{print $1, $2}' file.csv         # CSV file

# Pattern matching
awk '/ERROR/ {print $0}' file.txt         # lines with ERROR
awk '/ERROR/ {print $2}' file.txt         # 2nd column of ERROR lines
awk '$3 > 100 {print $1}' file.txt        # where 3rd column > 100

# Built-in variables
awk '{print NR, $0}' file.txt             # NR = line number
awk '{print NF}' file.txt                 # NF = number of fields
awk 'NR==5 {print}' file.txt              # print 5th line
awk 'NR>1 {print}' file.txt               # skip header line

# Math operations
awk '{sum += $1} END {print sum}' file.txt  # sum of column 1
awk '{sum += $1} END {print sum/NR}' file.txt  # average

# Format output
awk '{printf "%-10s %s\n", $1, $2}' file.txt  # formatted columns

# Practical examples
awk -F: '$3 >= 1000 {print $1}' /etc/passwd   # users with UID >= 1000
df -h | awk '$5 > 80 {print $1, $5}'          # disks > 80% full
ps aux | awk '{sum+=$4} END {print sum"%"}'   # total memory usage
```

## Find - Search Files

```bash
# By name
find /path -name "*.txt"                  # .txt files
find /path -iname "*.TXT"                 # case-insensitive
find /path -name "file*"                  # wildcard

# By type
find /path -type f                        # files only
find /path -type d                        # directories only
find /path -type l                        # symlinks

# By size
find /path -size +100M                    # files > 100MB
find /path -size -10k                     # files < 10KB
find /path -size 50M                      # exactly 50MB

# By time
find /path -mtime -7                      # modified in last 7 days
find /path -mtime +30                     # modified > 30 days ago
find /path -mmin -60                      # modified in last 60 minutes
find /path -atime -1                      # accessed in last day

# By permissions
find /path -perm 644                      # exactly 644
find /path -perm -644                     # at least 644
find /path -perm /u+w                     # owner writable

# By owner
find /path -user alice                    # owned by alice
find /path -group developers              # owned by group

# Combine conditions (AND)
find /path -name "*.log" -mtime -7        # .log files from last 7 days

# OR condition
find /path \( -name "*.txt" -o -name "*.log" \)

# NOT condition
find /path -not -name "*.txt"
find /path ! -name "*.txt"                # same as above

# Execute command on results
find /path -name "*.tmp" -delete          # delete .tmp files
find /path -name "*.txt" -exec chmod 644 {} \;
find /path -name "*.log" -exec grep ERROR {} \;

# Practical examples
find /var/log -name "*.log" -mtime +30 -delete  # delete old logs
find ~ -type f -size +100M                      # find large files
find /etc -name "*.conf" -exec grep -l "server" {} \;  # configs with "server"
```

## Xargs - Build Commands

```bash
# Basic usage
find /path -name "*.tmp" | xargs rm       # delete files
echo "file1 file2 file3" | xargs touch   # create files

# With placeholder
find /path -name "*.txt" | xargs -I {} cp {} /backup/  # copy files
find /path -name "*.log" | xargs -I {} mv {} {}.old    # rename files

# Limit commands (-n)
echo {1..10} | xargs -n 3                 # process 3 args at a time

# Parallel execution (-P)
find /path -name "*.jpg" | xargs -P 4 -I {} convert {} {}.png  # 4 parallel jobs

# Handle spaces in filenames (-0 with find -print0)
find /path -name "*.txt" -print0 | xargs -0 rm

# Interactive confirmation (-p)
find /path -name "*.tmp" | xargs -p rm    # ask before each delete

# Practical examples
cat urls.txt | xargs -I {} curl -O {}     # download URLs
ls *.log | xargs -I {} gzip {}            # compress log files
find /var/log -name "*.log" | xargs grep -l "ERROR"  # logs with errors
```

## Quick Command Combinations

```bash
# Find and count lines in all .py files
find . -name "*.py" | xargs wc -l

# Search all logs for errors, show unique ones
grep -r ERROR /var/log | awk '{print $NF}' | sort | uniq

# Top 10 largest files in directory
du -ah /path | sort -rh | head -10

# Find files modified today
find /path -type f -mtime 0

# Replace text in all files
find /path -name "*.txt" -exec sed -i 's/old/new/g' {} \;

# List files by modification time
find /path -type f -printf '%T@ %p\n' | sort -n | tail -10

# Delete empty directories
find /path -type d -empty -delete

# Count files by extension
find /path -type f | sed 's/.*\.//' | sort | uniq -c
```

## Tips & Tricks

1. **Always test without `-i` or `-delete`** first
2. **Use `--` to separate options from filenames**: `rm -- -badfilename`
3. **Escape special chars in regex**: `grep '\$' file.txt`
4. **Combine with pipes**: `grep ERROR log | awk '{print $1}' | sort | uniq -c`
5. **Use `-print0` and `-0` for filenames with spaces**
6. **Test sed/awk on small sample first**
7. **Remember: grep uses basic regex, use `-E` for extended**

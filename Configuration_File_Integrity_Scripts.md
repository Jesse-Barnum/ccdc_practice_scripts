These instructions detail the fulfillment for the ClamAV installation inject, detailing the steps for installation and configuration. Please note that these steps must be done using an **Administrator Command Prompt (CMD), NOT POWERSHELL**.

## File Integrity Baseline Script (baseline.sh)
**This scripts creates a 'database' of the hashes of each of the config files in a specified directory. This database will be checked against when the other script is run to identify changes in the configuration file.**

Here is the script: 
<pre> #!/bin/bash
# generate_baseline.sh - Creates a file integrity database for a given directory

TARGET_DIR=$1

# Ensure a directory was provided and exists
if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Define the hidden database file name
DB_FILE="$TARGET_DIR/.fim_database.txt"

echo "[*] Generating baseline for $TARGET_DIR..."

# Find all files (excluding the DB file itself to prevent hash loops) and calculate hashes
find "$TARGET_DIR" -type f ! -name ".fim_database.txt" -exec sha256sum {} + > "$DB_FILE"

echo "[+] Baseline successfully saved to $DB_FILE"</pre>


## File Integrtiy Monitoring Script (monitor.sh)
**This script checks the current hashes of each of the config files in /etc, /bin, and /var/www/html to verify that none of the files have changed. It will send an alert to /var/log/syslog or /var/log/messages if a file has been changed.** 

<pre> #!/bin/bash
# monitor_fim.sh - Compares current directory state against baseline and alerts via SYSLOG

# Define the list of directories to monitor (Update this list as needed)
DIRS_TO_MONITOR=("/etc" "/bin" "/var/www/html")

for DIR in "${DIRS_TO_MONITOR[@]}"; do
    DB_FILE="$DIR/.fim_database.txt"
    
    # Check if the baseline exists for this directory
    if [ ! -f "$DB_FILE" ]; then
        logger -p user.err "FIM ERROR: Baseline database missing for $DIR"
        continue
    fi

    # Create temporary files for comparison
    TEMP_CURRENT_DB=$(mktemp)
    TEMP_OLD_DB=$(mktemp)

    # Generate current state hashes
    find "$DIR" -type f ! -name ".fim_database.txt" -exec sha256sum {} + | sort -k 2 > "$TEMP_CURRENT_DB"
    sort -k 2 "$DB_FILE" > "$TEMP_OLD_DB"

    # 1. Identify NEW files (Present in current state, missing in baseline)
    awk 'NR==FNR{a[$2]; next} !($2 in a) {print $2}' "$TEMP_OLD_DB" "$TEMP_CURRENT_DB" | while read -r new_file; do
        logger -p user.alert "FIM ALERT: [NEW FILE DETECTED] $new_file in $DIR"
    done

    # 2. Identify MISSING files (Present in baseline, missing in current state)
    awk 'NR==FNR{a[$2]; next} !($2 in a) {print $2}' "$TEMP_CURRENT_DB" "$TEMP_OLD_DB" | while read -r missing_file; do
        logger -p user.alert "FIM ALERT: [FILE DELETED] $missing_file missing from $DIR"
    done

    # 3. Identify MODIFIED files (Paths match, but hashes differ)
    awk 'NR==FNR{hash[$2]=$1; next} ($2 in hash) && (hash[$2] != $1) {print $2}' "$TEMP_OLD_DB" "$TEMP_CURRENT_DB" | while read -r mod_file; do
        logger -p user.alert "FIM ALERT: [FILE MODIFIED] Hash changed for $mod_file in $DIR"
    done

    # Clean up temporary files
    rm -f "$TEMP_CURRENT_DB" "$TEMP_OLD_DB"
done
</pre>

**Running this script:**


| Step | Description |
| --- | --- |
| **1** | 1. create a Cron Job `sudo crontab -e` <br> 2. Add this line: `*/5 * * * * /path-to-script/monitor.sh` |
| **2** | 1. Verify the script accurately functions by changing a config file. I would suggest /etc/fuse.conf (just add any line). <br> 2. Run the script: `sudo ./monitor.sh`. <br> 3. Check the logs to verify it functioned correctly. `sudo tail -f /var/log/syslog \| grep FIM` If you see a `FIM ALERT: [FILE MODIFIED] Hash changed for $mod_file in $DIR` then you are good to go. Make sure to take a screenshot.   |
| **Troubleshooting** | If your scripts are not running, or getting a syntax error when running, run these commands: `sudo apt install dos2unix`, `dos2unix baseline.sh` `dos2unix monitor.sh` |



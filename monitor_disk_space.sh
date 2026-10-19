#!/bin/bash

# ==============================================================================
# SYNOPSIS
#   Self-installing disk space monitor that triggers terminal broadcasts (wall) 
#   and syslog alerts at 50%, 80%, and 90% utilization.
# ==============================================================================

# 1. Self-Installation Logic (Run once to set up persistence)
SCRIPT_PATH=$(readlink -f "$0")

# Ensure the script is executable
chmod +x "$SCRIPT_PATH"

# Check if the cron job already exists in the root crontab
if ! crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo -e "\e[32mScheduled task not found. Installing cron job to run every 3 minutes...\e[0m"
    
    # Append the job, redirecting output to null so cron doesn't email the instruction block
    (crontab -l 2>/dev/null; echo "*/3 * * * * $SCRIPT_PATH > /dev/null 2>&1") | crontab -
    
    echo -e "\e[32mInstallation complete. The script will now run automatically.\e[0m"
fi

# 2. Disk Monitoring Logic
df -P | grep '^/dev/' | while read -r line; do
    percentUsed=$(echo "$line" | awk '{print $5}' | sed 's/%//g')
    mountPoint=$(echo "$line" | awk '{print $6}')
    
    alertMessage=""
    syslogLevel=""

    if [ "$percentUsed" -ge 90 ]; then
        alertMessage="CRITICAL: Drive $mountPoint is currently at ${percentUsed}% used capacity! This is above the 90% threshold! Immediate action is required to free up space."
        syslogLevel="emerg"
    elif [ "$percentUsed" -ge 80 ]; then
        alertMessage="WARNING: Drive $mountPoint is currently at ${percentUsed}% used capacity. This is above the 80% threshold! Please consider freeing up space soon."
        syslogLevel="warning"
    elif [ "$percentUsed" -ge 50 ]; then
        alertMessage="NOTICE: Drive $mountPoint is currently at ${percentUsed}% used capacity. This is above the 50% threshold!"
        syslogLevel="info"
    fi

    if [ -n "$alertMessage" ]; then
        logger -t "CCDC_Disk_Monitor" -p "user.$syslogLevel" "$alertMessage"
        echo "$alertMessage" | wall
    fi
done

# 3. Interactive Testing Instructions
# Only print if running in an interactive terminal (prevents cron job spam)
if [ -t 1 ]; then
    echo -e "\n\e[36m=======================================================================\e[0m"
    echo -e "\e[36m                  DISK MONITOR TESTING INSTRUCTIONS                    \e[0m"
    echo -e "\e[36m=======================================================================\e[0m"
    echo -e "To test the thresholds, instantly fill disk space with a dummy file:"
    echo -e "  \e[33msudo fallocate -l 30G /dummy.img\e[0m"
    echo -e "  *(Adjust '30G' based on your free space to reach 50%, 80%, or 90%)"
    echo -e ""
    echo -e "Run this script again to trigger the alert, then reclaim your space:"
    echo -e "  \e[33msudo rm /dummy.img\e[0m"
    echo -e ""
    echo -e "To capture screenshot evidence of the syslog alert for the inject:"
    echo -e "  \e[33msudo grep \"CCDC_Disk_Monitor\" /var/log/syslog\e[0m"
    echo -e "  *(Use /var/log/messages instead on RHEL/CentOS/Fedora systems)"
    echo -e ""
    echo -e "To capture screenshot evidence of the CronJob set up properly for the inject:"
    echo -e "  \e[33msudo crontab -l\e[0m"
    echo -e "\e[36m=======================================================================\e[0m\n"
fi

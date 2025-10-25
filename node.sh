#!/bin/bash
#this script installs both CLamAV and Wazuh on Linux distributions. 

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

sudo timedatectl set-ntp on

sudo apt update && sudo apt install clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam # initial DB pull
sudo systemctl enable --now clamav-freshclam clamav-daemon



    # Install Wazuh Agent
    echo "Installing Wazuh Agent..."
WAZUH_MANAGER_IP="10.0.0.5"
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
    apt-get update
    WAZUH_MANAGER=$WAZUH_MANAGER_IP apt-get install wazuh-agent -y
    
    # Enable and start Wazuh agent
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent

sudo ss -a | grep clamd
sudo service clamav-daemon status
systemctl status wazuh-agent


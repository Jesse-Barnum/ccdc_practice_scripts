#!/bin/bash
# This script installs and configures ClamAV and the Wazuh agent on Debian/Ubuntu systems.

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# 2. Sync System Time
# This prevents repository errors caused by an incorrect system clock.
echo "--- Syncing system time..."
sudo timedatectl set-ntp on


# 3. Install ClamAV
echo "--- Installing ClamAV..."
sudo apt-get update
sudo apt-get install -y clamav clamav-daemon

echo "--- Updating ClamAV virus definitions..."
sudo systemctl stop clamav-freshclam
sudo freshclam # Initial DB pull
sudo systemctl enable --now clamav-freshclam clamav-daemon

# 4. Install Wazuh Agent
echo "--- Installing Wazuh Agent..."
WAZUH_MANAGER_IP="10.0.0.5" # IMPORTANT: Change this if your manager IP is different

sudo mkdir -p /etc/apt/keyrings
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/keyrings/wazuh.gpg --import && sudo chmod 644 /etc/apt/keyrings/wazuh.gpg

# Add the Wazuh repository GPG key and sources
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

# Install the agent package
sudo apt-get update
sudo WAZUH_MANAGER=$WAZUH_MANAGER_IP apt-get install -y wazuh-agent

# Enable and start the Wazuh agent service
echo "--- Starting Wazuh agent..."
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# 5. Verification
# Prints the status of the installed services.
echo "--- Installation Complete. Verifying services... ---"
echo "--- ClamAV Status: ---"
sudo ss -a | grep clamd
sudo systemctl status clamav-daemon


echo "" # Add a space for readability
echo "--- Wazuh Agent Status: ---"
systemctl status wazuh-agent

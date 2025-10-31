#!/bin/bash
# This script installs and configures ClamAV and the Wazuh agent on Oracle Linux / RHEL / CentOS systems.

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
# Note: ClamAV is in the EPEL (Extra Packages for Enterprise Linux) repository.
echo "--- Installing EPEL repository for ClamAV..."
sudo yum install -y epel-release

echo "--- Installing ClamAV..."
sudo yum install -y clamav clamav-daemon

echo "--- Updating ClamAV virus definitions..."
sudo systemctl stop clamav-freshclam
sudo freshclam # Initial DB pull
sudo systemctl enable --now clamav-freshclam clamav-daemon

# 4. Install Wazuh Agent
echo "--- Installing Wazuh Agent..."
WAZUH_MANAGER_IP="10.0.0.5" # IMPORTANT: Change this if your manager IP is different

# Add the Wazuh repository
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
sudo tee /etc/yum.repos.d/wazuh.list > /dev/null <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

# Install the agent package
sudo WAZUH_MANAGER=$WAZUH_MANAGER_IP yum install -y wazuh-agent

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

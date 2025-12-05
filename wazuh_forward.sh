#!/bin/bash
# This script installs and configures the Wazuh agent on Debian/Ubuntu systems.

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# 2. Sync System Time
echo "--- Syncing system time..."
timedatectl set-ntp on

# 3. Add Wazuh Repository
echo "--- Adding Wazuh Repository..."
WAZUH_MANAGER_IP="192.168.220.240"

# Install GPG tools if missing
apt-get update && apt-get install -y gnupg apt-transport-https

# Import the GPG key
mkdir -p /usr/share/keyrings
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

# Add the repository source
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# 4. Install Wazuh Agent
echo "--- Installing Wazuh Agent pointing to $WAZUH_MANAGER_IP..."
apt-get update
# We pass the variable directly to the installer to auto-configure the agent
WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y wazuh-agent

# 5. Enable and Start Service
echo "--- Starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# 6. Verification
echo "--- Installation Complete. Verifying services... ---"
echo "" 
echo "--- Wazuh Agent Status: ---"
# --no-pager prevents the script from hanging on an interactive screen
systemctl status wazuh-agent --no-pager

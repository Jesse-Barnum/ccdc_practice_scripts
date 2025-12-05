#!/bin/bash

# --- Configuration ---
WAZUH_MANAGER="<WAZUH_MANAGER_IP_OR_HOSTNAME>"

# --- Check for root privileges ---
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root. Use sudo." 1>&2
   exit 1
fi

echo "Starting Wazuh agent installation on Ubuntu..."

# 1. Install required packages for repository management
apt-get update && apt-get install -y gnupg apt-transport-https software-properties-common curl

# 2. Import the Wazuh GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

# 3. Add the Wazuh repository (for version 4.x)
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

# 4. Update the package information
apt-get update

# 5. Install the Wazuh agent package and configure the manager IP
# The WAZUH_MANAGER environment variable is used during installation/configuration
WAZUH_MANAGER="$WAZUH_MANAGER" apt-get install -y wazuh-agent

# 6. Enable and start the Wazuh agent service
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "Wazuh agent installation and enrollment complete."
echo "Check the agent status with: systemctl status wazuh-agent"

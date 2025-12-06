#!/bin/bash
# This script installs and configures the Wazuh agent specifically for CentOS 8.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
WAZUH_MANAGER_IP="192.168.220.240"

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root. Please use sudo." >&2
  exit 1
fi

echo "--- Starting Installation Process (CentOS 8) ---"

# 2. Import the GPG Key
# We import the key directly into the RPM database
echo "--- Importing GPG Key..."
rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

# 3. Add Wazuh Repository
echo "--- Adding Wazuh Repository..."
# Create the repo file in /etc/yum.repos.d/
cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

# 4. Install Wazuh Agent
echo "--- Installing Wazuh Agent pointing to $WAZUH_MANAGER_IP..."
# CentOS 8 uses 'dnf' as the default package manager
WAZUH_MANAGER="$WAZUH_MANAGER_IP" dnf install -y wazuh-agent

# 5. Enable and Start Wazuh Service
echo "--- Starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# 6. Verification
echo ""
echo "--- Installation Complete! ---"
echo "Verifying Wazuh Agent connection..."
# --no-pager prevents the script from hanging on an interactive screen
systemctl status wazuh-agent --no-pager

echo ""
echo "Done."

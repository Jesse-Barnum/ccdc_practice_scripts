#!/bin/bash
# This script installs and configures the Wazuh agent on Debian/Ubuntu systems.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
WAZUH_MANAGER_IP="192.168.220.240"

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root. Please use sudo." >&2
  exit 1
fi

echo "--- Starting Installation Process ---"

# 2. Sync System Time
# Critical for SSL verification and log timestamps
echo "--- Syncing system time..."
if command -v timedatectl &> /dev/null; then
    timedatectl set-ntp on
else
    echo "Note: timedatectl not found. Ensure time is synced manually if needed."
fi

# 3. Install Prerequisites (Fixes the GPG/SSL Error)
echo "--- Installing necessary dependencies (curl, gnupg, ca-certificates)..."
apt-get update
# 'ca-certificates' fixes the SSL error when downloading the key
# 'gnupg' fixes the "no valid OpenPGP data" error
apt-get install -y curl gnupg apt-transport-https ca-certificates lsb-release

# 4. Add Wazuh Repository
echo "--- Adding Wazuh Repository..."

# Create the keyrings directory if it doesn't exist
mkdir -p /usr/share/keyrings

# Download the key to a temp file first (more robust than piping)
curl -sSLo /tmp/wazuh.key https://packages.wazuh.com/key/GPG-KEY-WAZUH

# Import the key
gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import /tmp/wazuh.key && chmod 644 /usr/share/keyrings/wazuh.gpg
rm /tmp/wazuh.key

# Add the repository source
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# 5. Install Wazuh Agent
echo "--- Installing Wazuh Agent pointing to $WAZUH_MANAGER_IP..."
apt-get update
# We pass the variable directly to the installer to auto-configure the agent
WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y wazuh-agent

# 6. Enable and Start Wazuh Service
echo "--- Starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# 7. Verification
echo ""
echo "--- Installation Complete! ---"
echo "Verifying Wazuh Agent connection..."
# using --no-pager ensures the script doesn't hang here
systemctl status wazuh-agent --no-pager

echo ""
echo "Done."

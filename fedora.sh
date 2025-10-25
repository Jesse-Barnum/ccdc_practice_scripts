#!/bin/bash
# This script installs both ClamAV and the Wazuh agent on Fedora.

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# --- Install ClamAV for Fedora ---
echo "Installing ClamAV..."
# Enable the EPEL repository which contains ClamAV
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %fedora).noarch.rpm
# Install ClamAV packages
sudo dnf install -y clamav clamd

# Update the virus database
echo "Updating ClamAV database..."
sudo freshclam

# Enable and start the ClamAV daemon
# On Fedora, the service is typically clamd@scan
echo "Starting ClamAV service..."
sudo systemctl enable --now clamd@scan


# --- Install Wazuh Agent for Fedora ---
echo "Installing Wazuh Agent..."
WAZUH_MANAGER_IP="10.0.0.5"

# Add the Wazuh repository for RPM-based systems
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
sudo tee /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

# Install the Wazuh agent using dnf
sudo WAZUH_MANAGER=$WAZUH_MANAGER_IP dnf install -y wazuh-agent

# Enable and start the Wazuh agent service
echo "Starting Wazuh agent..."
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent


# --- Verification Steps ---
echo "--- Verification ---"
echo "ClamAV Status:"
sudo systemctl status clamd@scan

echo "Wazuh Agent Status:"
sudo systemctl status wazuh-agent

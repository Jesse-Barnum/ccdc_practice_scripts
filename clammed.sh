#!/bin/bash
# This script installs and configures ClamAV on Debian-based systems
# (Ubuntu, Mint, etc.) and includes checks for success.

# --- 1. Root Check ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# --- 2. Installation ---
echo "Updating package lists..."
apt-get update -y

echo "Installing ClamAV and ClamAV daemon..."
apt-get install -y clamav clamav-daemon

# --- 3. Configuration ---
echo "Stopping all ClamAV services AND sockets for configuration..."
# This is the critical fix: stop the socket to prevent auto-starting.
systemctl stop clamav-daemon.service
systemctl stop clamav-daemon.socket
systemctl stop clamav-freshclam.service

echo "Updating ClamAV virus definitions..."
if sudo freshclam; then
    echo "Virus definitions updated successfully."
else
    echo "ERROR: freshclam failed to update definitions." >&2
    echo "The ClamAV daemon will not be able to start." >&2
    echo "Please check your network connection and try again." >&2
    exit 1
fi

# --- 4. Start Services ---
echo "Starting and enabling ClamAV services..."
# Now that definitions exist, we can start everything.
systemctl start clamav-daemon.socket
systemctl start clamav-daemon.service
systemctl enable clamav-daemon.service

systemctl start clamav-freshclam.service
systemctl enable clamav-freshclam.service

# --- 5. Verification ---
echo "Verifying ClamAV services..."
# Give the service a moment to start
sleep 3
systemctl status clamav-daemon.service
clamscan --version

echo "ClamAV installation and setup complete."

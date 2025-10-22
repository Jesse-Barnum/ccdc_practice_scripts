#!/bin/bash

# Update package lists
echo "Updating package lists..."
sudo apt-get update -y

# Install ClamAV and ClamAV daemon
echo "Installing ClamAV and ClamAV daemon..."
sudo apt-get install -y clamav clamav-daemon

# Stop ClamAV daemon to update virus definitions safely
echo "Stopping ClamAV daemon..."
sudo systemctl stop clamav-freshclam
sudo systemctl stop clamav-daemon

# Update virus definitions
echo "Updating ClamAV virus definitions..."
sudo freshclam

# Start and enable ClamAV daemon
echo "Starting and enabling ClamAV daemon..."
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-freshclam
sudo systemctl start clamav-daemon
sudo systemctl enable clamav-daemon

# Verify ClamAV installation
echo "Verifying ClamAV installation..."
clamscan --version

echo "ClamAV installation and setup complete."
echo "You can now use 'clamscan' to scan files and directories."

#!/bin/bash

# A script to install ClamAV on a Linux system.
# This script will attempt to detect the package manager and install ClamAV accordingly.

# --- Function to print messages ---
print_message() {
    echo "Looking For ClamAV downloadable file"
    echo "$1"
    echo "----------------------------------------"
}

# --- Detect Package Manager ---
if [ -x "$(command -v apt-get)" ]; then
    # Debian, Ubuntu, Mint
    PKG_MANAGER="apt-get"
    UPDATE_CMD="$PKG_MANAGER update"
    INSTALL_CMD="$PKG_MANAGER install -y clamav clamav-daemon"
    FRESHCLAM_SERVICE="clamav-freshclam"
    DAEMON_SERVICE="clamav-daemon"
elif [ -x "$(command -v dnf)" ]; then
    # Fedora, CentOS 8+, RHEL 8+
    PKG_MANAGER="dnf"
    UPDATE_CMD="$PKG_MANAGER makecache"
    INSTALL_CMD="$PKG_MANAGER install -y clamav clamav-daemon clamav-update"
    FRESHCLAM_SERVICE="clamav-freshclam"
    DAEMON_SERVICE="clamav-daemon"
elif [ -x "$(command -v yum)" ]; then
    # CentOS 7, RHEL 7
    PKG_MANAGER="yum"
    # EPEL repository is often needed for ClamAV on older RHEL/CentOS
    print_message "Ensuring EPEL repository is available..."
    yum install -y epel-release
    UPDATE_CMD="$PKG_MANAGER makecache fast"
    INSTALL_CMD="$PKG_MANAGER install -y clamav clamav-daemon clamav-update"
    FRESHCLAM_SERVICE="clamav-freshclam"
    DAEMON_SERVICE="clamav-daemon"
elif [ -x "$(command -v pacman)" ]; then
    # Arch Linux
    PKG_MANAGER="pacman"
    UPDATE_CMD="$PKG_MANAGER -Sy"
    INSTALL_CMD="$PKG_MANAGER -S --noconfirm clamav"
    FRESHCLAM_SERVICE="clamav-freshclam"
    DAEMON_SERVICE="clamd" # Note the different service name for Arch
else
    echo "Unsupported package manager. Cannot install ClamAV."
    exit 1
fi

# --- Installation Process ---

# 1. Update package lists
print_message "Updating package lists using $PKG_MANAGER..."
sudo $UPDATE_CMD
if [ $? -ne 0 ]; then
    echo "Failed to update package lists. Please check your repository configuration."
    exit 1
fi

# 2. Install ClamAV
print_message "Installing ClamAV..."
sudo $INSTALL_CMD
if [ $? -ne 0 ]; then
    echo "Failed to install ClamAV packages."
    exit 1
fi

# 3. Stop services to update definitions
print_message "Stopping ClamAV services to update definitions..."
sudo systemctl stop $FRESHCLAM_SERVICE
sudo systemctl stop $DAEMON_SERVICE

# 4. Update Virus Definitions
print_message "Updating virus definitions with freshclam..."
# Run freshclam manually. It can take some time.
sudo freshclam
if [ $? -ne 0 ]; then
    echo "Failed to update virus definitions. You may need to run 'sudo freshclam' manually."
    # We won't exit here, as the installation is complete, but we'll warn the user.
fi

# 5. Enable and Start Services
print_message "Enabling and starting ClamAV services..."

# Enable freshclam to run automatically
sudo systemctl enable $FRESHCLAM_SERVICE
sudo systemctl start $FRESHCLAM_SERVICE

# Enable and start the scanning daemon
sudo systemctl enable $DAEMON_SERVICE
sudo systemctl start $DAEMON_SERVICE

# --- Verification ---
print_message "Verifying service status..."
sudo systemctl status $FRESHCLAM_SERVICE --no-pager
sudo systemctl status $DAEMON_SERVICE --no-pager

print_message "ClamAV installation and setup complete!"
echo "You can perform a manual scan with a command like: clamscan -r /home"

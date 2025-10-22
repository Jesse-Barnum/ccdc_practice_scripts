#!/bin/bash
#
# install_clamav_universal.sh
#
# This script installs and configures ClamAV on a Linux system.
# It automatically detects the package manager and handles the
# specific configurations for Debian, RHEL/Fedora, and Arch-based systems,
# making it compatible with Ubuntu, Mint, Fedora, CentOS, and more.
#

# --- 1. Root Check ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# --- 2. Package Manager Detection and Installation ---
echo "Detecting package manager..."

if [ -x "$(command -v apt-get)" ]; then
    # --- DEBIAN/UBUNTU/MINT ---
    echo "Found apt-get (Debian-based system like Ubuntu or Mint)."
    
    echo "Updating package lists..."
    apt-get update -y
    
    echo "Installing ClamAV packages..."
    apt-get install -y clamav clamav-daemon
    
    echo "Stopping services for initial configuration..."
    systemctl stop clamav-daemon
    systemctl stop clamav-freshclam
    
    echo "Updating virus definitions..."
    freshclam
    
    echo "Starting and enabling services..."
    systemctl start clamav-daemon
    systemctl enable clamav-daemon
    systemctl start clamav-freshclam
    systemctl enable clamav-freshclam

elif [ -x "$(command -v dnf)" ]; then
    # --- FEDORA / RHEL 9+ ---
    echo "Found dnf (Fedora/RHEL-based system)."
    
    echo "Installing ClamAV packages..."
    dnf install -y clamav clamd clamav-freshclam
    
    echo "Configuring ClamAV..."
    # RHEL/Fedora requires commenting out the 'Example' line
    sed -i 's/^Example/# Example/' /etc/clamd.conf
    sed -i 's/^Example/# Example/' /etc/freshclam.conf
    
    echo "Updating virus definitions..."
    freshclam
    
    echo "Enabling SELinux boolean for antivirus scanning..."
    # This is CRITICAL for Fedora/RHEL
    setsebool -P antivirus_can_scan 1
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to set SELinux boolean. 'setsebool' might not be installed."
        echo "Please install 'policycoreutils-python-utils' and run: setsebool -P antivirus_can_scan 1"
    fi

    echo "Starting and enabling services..."
    systemctl start clamd.service
    systemctl enable clamd.service
    systemctl start clamav-freshclam.service
    systemctl enable clamav-freshclam.service

elif [ -x "$(command -v yum)" ]; then
    # --- CENTOS 7 / RHEL 7 ---
    echo "Found yum (RHEL/CentOS 7 system)."
    
    echo "Installing EPEL repository..."
    yum install -y epel-release
    
    echo "Installing ClamAV packages..."
    yum install -y clamav clamd clamav-freshclam
    
    echo "Configuring ClamAV..."
    sed -i 's/^Example/# Example/' /etc/clamd.conf
    sed -i 's/^Example/# Example/' /etc/freshclam.conf
    
    echo "Updating virus definitions..."
    freshclam
    
    echo "Enabling SELinux boolean for antivirus scanning..."
    setsebool -P antivirus_can_scan 1
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to set SELinux boolean. 'setsebool' might not be installed."
        echo "Please install 'policycoreutils-python' and run: setsebool -P antivirus_can_scan 1"
    fi

    echo "Starting and enabling services..."
    systemctl start clamd.service
    systemctl enable clamd.service
    systemctl start clamav-freshclam.service
    systemctl enable clamav-freshclam.service

elif [ -x "$(command -v pacman)" ]; then
    # --- ARCH LINUX ---
    echo "Found pacman (Arch-based system)."
    
    echo "Installing ClamAV packages..."
    pacman -Syu --noconfirm clamav
    
    echo "Configuring ClamAV..."
    sed -i 's/^Example/# Example/' /etc/clamd.conf
    sed -i 's/^Example/# Example/' /etc/freshclam.conf
    
    echo "Updating virus definitions..."
    freshclam
    
    echo "Starting and enabling services..."
    systemctl start clamd.service
    systemctl enable clamd.service
    systemctl start clamav-freshclam.service
    systemctl enable clamav-freshclam.service
    
else
    echo "Error: Could not find a supported package manager (apt, dnf, yum, pacman)." >&2
    exit 1
fi

echo "----------------------------------------"
echo " ClamAV installation and setup complete!"
echo "----------------------------------------"

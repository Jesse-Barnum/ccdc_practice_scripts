#!/bin/bash
#
# install_clamav_universal.sh (v3)
#
# This script installs and configures ClamAV on a Linux system.
# It automatically detects the package manager and handles the
# specific configurations for Debian, RHEL/Fedora, and Arch-based systems.
#
# ----- V3 UPDATE -----
# - Added 'epel-release' to the DNF block. This is critical for
#   RHEL 9 derivatives (like Oracle 9) which use DNF but
#   do not have ClamAV in their base repositories.
# ---------------------

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
    systemctl stop clamav-daemon.service
    systemctl stop clamav-daemon.socket
    systemctl stop clamav-freshclam.service
    
    echo "Updating virus definitions..."
    # Run freshclam. If it fails, exit with an error.
    if ! freshclam; then
        echo "ERROR: freshclam failed to download definitions." >&2
        echo "This can be a network issue or a server block (e.g., on old OS)." >&2
        exit 1
    fi
    
    echo "Starting and enabling services..."
    systemctl start clamav-daemon.socket
    systemctl start clamav-daemon.service
    systemctl enable clamav-daemon.service
    systemctl start clamav-freshclam.service
    systemctl enable clamav-freshclam.service

elif [ -x "$(command -v dnf)" ]; then
    # --- FEDORA / RHEL 9+ (Oracle 9) ---
    echo "Found dnf (Fedora/RHEL-based system)."
    
    echo "Installing EPEL repository (needed for ClamAV)..."
    # This is the critical fix for Oracle 9 / RHEL 9
    dnf install -y epel-release
    
    echo "Installing ClamAV packages..."
    dnf install -y clamav clamd clamav-freshclam
    
    echo "Configuring ClamAV..."
    sed -i 's/^Example/# Example/' /etc/clamd.conf
    sed -i 's/^Example/# Example/' /etc/freshclam.conf
    
    echo "Updating virus definitions..."
    if ! freshclam; then
        echo "ERROR: freshclam failed to download definitions." >&2
        exit 1
    fi
    
    echo "Enabling SELinux boolean for antivirus scanning..."
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
    if ! freshclam; then
        echo "ERROR: freshclam failed to download definitions." >&2
        exit 1
    fi
    
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
    if ! freshclam; then
        echo "ERROR: freshclam failed to download definitions." >&2
        exit 1
    fi
    
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


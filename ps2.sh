#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: install_powershell.sh
# Description: Identifies the Linux distro and installs PowerShell Core (pwsh).
# Supported: Ubuntu, Debian, CentOS, RHEL, Fedora, Rocky, AlmaLinux.
# -----------------------------------------------------------------------------

# 1. Check for Root Privileges
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root. Please use sudo."
   exit 1
fi

echo "Checking system information..."

# 2. Identify the Operating System
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Error: /etc/os-release not found. Cannot identify OS."
    exit 1
fi

echo "Detected Operating System: $PRETTY_NAME ($OS)"

# 3. Define Installation Functions

install_snap_fallback() {
    echo "-----------------------------------------------------"
    echo "APT/YUM installation failed or package not found."
    echo "Attempting to install via Snap (universal package manager)..."
    echo "-----------------------------------------------------"
    
    if command -v snap &> /dev/null; then
        snap install powershell --classic
    else
        echo "Error: Snap is not installed, and native package manager failed."
        echo "Please ensure 'snapd' is installed and try again."
        exit 1
    fi
}

install_ubuntu_debian() {
    echo "Starting installation for Debian/Ubuntu based system..."

    # Install prerequisites
    apt-get update
    apt-get install -y wget apt-transport-https software-properties-common

    # Register the Microsoft repository GPG keys
    echo "Downloading Microsoft repository configuration..."
    
    # Attempt to download specific version config
    wget -q "https://packages.microsoft.com/config/$OS/$VERSION/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
    
    # Check if download succeeded (size > 0)
    if [ ! -s packages-microsoft-prod.deb ]; then
        echo "Warning: Specific repo for $OS $VERSION not found. Trying generic LTS fallback..."
        # Fallback for Ubuntu (Use 22.04 LTS as a safe anchor)
        if [[ "$OS" == "ubuntu" ]]; then
             wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
        # Fallback for Debian (Use 11 as a safe anchor)
        elif [[ "$OS" == "debian" ]]; then
             wget -q "https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
        fi
    fi

    # Install the repo configuration
    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Update package list
    apt-get update
    
    # Check if powershell is actually available now
    if apt-cache show powershell &> /dev/null; then
        echo "Installing PowerShell via APT..."
        apt-get install -y powershell
    else
        echo "Error: 'powershell' package not found in the configured repositories."
        install_snap_fallback
    fi
}

install_rhel_fedora() {
    echo "Starting installation for RHEL/CentOS/Fedora based system..."
    
    # Register the Microsoft RedHat repository
    curl https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo

    echo "Installing PowerShell..."
    if command -v dnf &> /dev/null; then
        dnf install -y powershell || install_snap_fallback
    else
        yum install -y powershell || install_snap_fallback
    fi
}

# 4. Execution Logic based on Detected OS

case "$OS" in
    ubuntu|debian|kali|linuxmint|pop)
        install_ubuntu_debian
        ;;
    rhel|centos|fedora|rocky|almalinux)
        install_rhel_fedora
        ;;
    *)
        echo "OS not natively supported by specific blocks. Defaulting to Snap..."
        install_snap_fallback
        ;;
esac

# 5. Verification
echo "-----------------------------------------------------"
if command -v pwsh &> /dev/null; then
    echo "Success! PowerShell has been installed."
    echo "Type 'pwsh' to start."
    pwsh --version
else
    echo "Installation failed. Please check the error logs above."
    exit 1
fi

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
# Most modern Linux distros have this file
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

install_ubuntu_debian() {
    echo "Starting installation for Debian/Ubuntu based system..."

    # Install prerequisites
    apt-get update
    apt-get install -y wget apt-transport-https software-properties-common

    # Register the Microsoft repository GPG keys
    # We use a generic logic here, but for specific versions, MS has specific .deb files.
    # This block dynamically grabs the version to build the URL.
    
    # NOTE: If the specific version repo doesn't exist, it often works to fall back to a major LTS version (like 22.04 or 20.04)
    # but for this script, we will try to match the detected version.
    
    wget -q "https://packages.microsoft.com/config/$OS/$VERSION/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
    
    if [ $? -ne 0 ]; then
        echo "Warning: Could not find specific repo for $OS $VERSION. Trying generic fallback..."
        # Fallback for Ubuntu
        if [[ "$OS" == "ubuntu" ]]; then
             wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
        # Fallback for Debian
        elif [[ "$OS" == "debian" ]]; then
             wget -q "https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
        fi
    fi

    # Install the repo configuration
    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Update and Install
    apt-get update
    echo "Installing PowerShell..."
    apt-get install -y powershell
}

install_rhel_fedora() {
    echo "Starting installation for RHEL/CentOS/Fedora based system..."
    
    # Register the Microsoft RedHat repository
    # Using RHEL 8/9 repo is standard for modern RPM distros
    curl https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo

    echo "Installing PowerShell..."
    if command -v dnf &> /dev/null; then
        dnf install -y powershell
    else
        yum install -y powershell
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
        echo "-----------------------------------------------------"
        echo "Alert: The detected OS ($OS) is not natively supported by this script logic."
        echo "Attempting to install via Snap (universal package manager)..."
        echo "-----------------------------------------------------"
        
        if command -v snap &> /dev/null; then
            snap install powershell --classic
        else
            echo "Error: Snap is not installed, and native package manager is not supported."
            echo "Please install 'snapd' or install PowerShell manually."
            exit 1
        fi
        ;;
esac

# 5. Verification
echo "-----------------------------------------------------"
if command -v pwsh &> /dev/null; then
    echo "Success! PowerShell has been installed."
    echo "Type 'pwsh' to start."
    pwsh --version
else
    echo "Installation may have failed. Please check the error logs above."
    exit 1
fi

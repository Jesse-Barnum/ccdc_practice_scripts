#!/bin/bash

# 1. Root Check
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)"
  exit 1
fi

# 2. Identify Package Manager and Set Variables
if command -v apt &> /dev/null; then
    PM="apt"
    SERVICE="clamav-daemon"
elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
    PM="yum"
    SERVICE="clamd@scan"
elif command -v pacman &> /dev/null; then
    PM="pacman"
    SERVICE="clamd"
elif command -v zypper &> /dev/null; then
    PM="zypper"
    SERVICE="clamd"
else
    echo "Unsupported distribution."
    exit 1
fi

echo "Detected $PM. Installing ClamAV..."

# 3. Execution Phase
case $PM in
    apt)
        apt update && apt install -y clamav clamav-daemon
        systemctl stop clamav-daemon
        freshclam
        ;;
    yum)
        # Handle RHEL/Fedora/Oracle
        yum install -y epel-release 2>/dev/null
        yum install -y clamav clamav-update clamav-scanner-systemd
        # Fix RHEL-specific 'Example' config blockers
        sed -i 's/^Example/#Example/' /etc/freshclam.conf
        sed -i 's/^Example/#Example/' /etc/clamd.d/scan.conf
        sed -i 's/^#LocalSocket /LocalSocket /' /etc/clamd.d/scan.conf
        freshclam
        ;;
    pacman)
        pacman -Syu --noconfirm clamav
        freshclam
        ;;
    zypper)
        zypper install -y clamav
        freshclam
        ;;
esac

# 4. Universal Startup
mkdir -p /var/log/clamav
systemctl enable --now "$SERVICE"

echo "Success! ClamAV is installed and running as $SERVICE."

#!/bin/bash

# CCDC INJECT AUTOMATION SCRIPT
# This script installs and configures ClamAV and the Wazuh agent on
# Debian-based (Ubuntu) and RHEL-based (Fedora, Oracle Linux) systems.

# --- USER CONFIGURATION ---
# IMPORTANT: Change this IP address to your Wazuh Manager's IP.
WAZUH_MANAGER_IP="10.0.0.5"

# --- SCRIPT START ---

# 1. Check for Root Privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# 2. Detect Operating System
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect the operating system."
    exit 1
fi

echo "Detected Operating System: $OS"

# 3. Installation and Configuration Functions

# Function for Debian/Ubuntu
setup_debian() {
    echo "--- Starting setup for Debian/Ubuntu ---"
    
    # Update package lists
    apt-get update
    
    # Install ClamAV
    echo "Installing ClamAV..."
    apt-get install clamav clamav-daemon -y
    systemctl stop clamav-freshclam
    freshclam
    systemctl start clamav-freshclam
    systemctl enable --now clamav-daemon
    
    # Configure ClamAV On-Access Scanning
    echo "Configuring ClamAV On-Access Scanning..."
    sed -i 's/^#OnAccessPrevention .*/OnAccessPrevention yes/' /etc/clamav/clamd.conf
    sed -i 's|^#OnAccessIncludePath .*|OnAccessIncludePath /home|' /etc/clamav/clamd.conf
    sed -i 's/^#OnAccessMaxFileSize .*/OnAccessMaxFileSize 5M/' /etc/clamav/clamd.conf
    systemctl restart clamav-daemon
    
    # Install Wazuh Agent
    echo "Installing Wazuh Agent..."
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
    apt-get update
    WAZUH_MANAGER=$WAZUH_MANAGER_IP apt-get install wazuh-agent -y
    
    # Enable and start Wazuh agent
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
    
    echo "--- Debian/Ubuntu setup complete ---"
}

# Function for Fedora/Oracle Linux/RHEL
setup_rhel() {
    echo "--- Starting setup for RHEL-based systems (Fedora/Oracle) ---"
    
    # Enable EPEL repository for ClamAV
    echo "Enabling EPEL repository..."
    if [[ "$OS" == "fedora" ]]; then
        dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %fedora).noarch.rpm
    else
        # For Oracle Linux and other RHEL derivatives
        dnf install -y epel-release
    fi
    
    # Install ClamAV
    echo "Installing ClamAV..."
    dnf install -y clamav clamav-devel clamd
    systemctl stop clamav-freshclam
    freshclam
    systemctl start clamav-freshclam
    systemctl enable --now clamd@scan
    
    # Configure ClamAV On-Access Scanning
    echo "Configuring ClamAV On-Access Scanning..."
    sed -i 's/^#OnAccessPrevention .*/OnAccessPrevention yes/' /etc/clamd.d/scan.conf
    sed -i 's|^#OnAccessIncludePath .*|OnAccessIncludePath /home|' /etc/clamd.d/scan.conf
    sed -i 's/^#OnAccessMaxFileSize .*/OnAccessMaxFileSize 5M/' /etc/clamd.d/scan.conf
    systemctl restart clamd@scan

    # Install Wazuh Agent
    echo "Installing Wazuh Agent..."
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    echo -e '[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=Wazuh repository\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh.repo
    WAZUH_MANAGER=$WAZUH_MANAGER_IP dnf install -y wazuh-agent
    
    # Enable and start Wazuh agent
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
    
    echo "--- RHEL-based setup complete ---"
}

# 4. Configure Wazuh Agent Modules (Common to all systems)
configure_wazuh_agent() {
    echo "--- Configuring Wazuh Agent Modules ---"
    # Wait a moment for the agent to potentially create the file
    sleep 10
    
    OSSEC_CONF="/var/ossec/etc/ossec.conf"
    if [ ! -f "$OSSEC_CONF" ]; then
        echo "Wazuh config file not found at $OSSEC_CONF. Aborting module configuration."
        return
    fi
    
    # Enable Syscollector
    sed -i 's|<syscollector>.*</syscollector>|<syscollector><disabled>no</disabled></syscollector>|' $OSSEC_CONF
    
    # Enable FIM (File Integrity Monitoring) for /home directories
    sed -i 's|<fim>.*</fim>|<fim><disabled>no</disabled><directories realtime="yes">/home</directories></fim>|' $OSSEC_CONF
    
    echo "Restarting Wazuh agent to apply changes..."
    systemctl restart wazuh-agent
}

# 5. Main Execution Logic
case $OS in
    ubuntu)
        setup_debian
        ;;
    fedora|ol)
        setup_rhel
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

# Common configuration step
configure_wazuh_agent

echo "--- Script finished ---"
echo "Verification Steps:"
echo "1. Check ClamAV Service: systemctl status clamd"
echo "2. Check Wazuh Agent Service: systemctl status wazuh-agent"
echo "3. Check Wazuh Agent Connection (check for logs): tail -f /var/ossec/logs/ossec.log"
echo "4. On the Wazuh Manager, run '/var/ossec/bin/agent_control -l' to see if this agent is active."

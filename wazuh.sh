#!/bin/bash

# An interactive script to install and configure the Wazuh agent on a Linux system.
# It prompts for the manager's IP, detects the package manager, adds the Wazuh
# repository, and sets up the agent.

# --- Function to print styled messages ---
print_message() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# --- Prompt for Wazuh Manager IP Address ---
WAZUH_MANAGER_IP=""
while [ -z "$WAZUH_MANAGER_IP" ]; do
    read -p "Please enter the Wazuh Manager IP address: " WAZUH_MANAGER_IP
    if [ -z "$WAZUH_MANAGER_IP" ]; then
        echo "The IP address cannot be empty. Please try again."
    fi
done

echo "Using '$WAZUH_MANAGER_IP' as the Wazuh Manager IP."
echo ""

# --- Main Installation Logic ---

print_message "Starting Wazuh agent installation..."

# 1. Update system packages and install prerequisites
if [ -x "$(command -v apt-get)" ]; then
    # Debian/Ubuntu
    print_message "Detected Debian/Ubuntu based system (apt)."
    sudo apt-get update
    sudo apt-get install -y curl gpg lsb-release

    # Add Wazuh repository
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list
    sudo apt-get update
    INSTALL_CMD="sudo apt-get install -y wazuh-agent"

elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v yum)" ]; then
    # RHEL/CentOS/Fedora
    print_message "Detected Red Hat based system (yum/dnf)."
    # Add Wazuh repository
    sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    echo -e '[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=Wazuh repository\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1' | sudo tee /etc/yum.repos.d/wazuh.repo
    INSTALL_CMD="sudo yum install -y wazuh-agent" # yum works as a link to dnf

else
    echo "Unsupported package manager. This script supports apt and yum/dnf."
    exit 1
fi


# 2. Install the Wazuh agent
print_message "Installing the Wazuh agent package..."
$INSTALL_CMD
if [ $? -ne 0 ]; then
    echo "Failed to install the wazuh-agent package. Please check for errors above."
    exit 1
fi


# 3. Configure the agent to connect to the manager
print_message "Configuring agent to connect to manager at $WAZUH_MANAGER_IP..."
OSSEC_CONF="/var/ossec/etc/ossec.conf"
# Use sed to replace the manager IP address in the configuration file
sudo sed -i "s/<address>MANAGER_IP<\/address>/<address>$WAZUH_MANAGER_IP<\/address>/g" $OSSEC_CONF

if ! grep -q "<address>$WAZUH_MANAGER_IP</address>" "$OSSEC_CONF"; then
    echo "Error: Failed to update the manager IP in $OSSEC_CONF."
    echo "Please check the file permissions and path."
    exit 1
fi


# 4. Enable and Start the Wazuh agent service
print_message "Enabling and starting the Wazuh agent service..."
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent


# 5. Verify service status
print_message "Verifying service status..."
sudo systemctl status wazuh-agent --no-pager
if [ $? -eq 0 ]; then
    print_message "Wazuh agent installation and setup complete!"
    echo "The agent is now running and should attempt to register with the manager."
    echo "You can check agent logs at: /var/ossec/logs/ossec.log"
else
    echo "The wazuh-agent service failed to start. Please check the status output above for errors."
fi

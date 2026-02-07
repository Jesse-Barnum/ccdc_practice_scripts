#!/bin/sh
# FreeBSD Wazuh Agent Install Script

# 1. Root Check
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# 2. Input Manager IP
echo "Enter the Wazuh Manager IP address: "
read WAZUH_MANAGER_IP

if [ -z "$WAZUH_MANAGER_IP" ]; then
    echo "Error: No IP provided."
    exit 1
fi

# 3. Install the Agent (using the official FreeBSD repo)
echo "--- Installing Wazuh Agent..."
pkg install -y security/wazuh-agent

# 4. Configure the Manager IP
# FreeBSD pkg doesn't auto-configure via ENV vars like Linux debs/rpms.
# We must edit the XML config directly.
echo "--- Configuring Manager IP..."
sed -i '' "s/<address>127.0.0.1<\/address>/<address>$WAZUH_MANAGER_IP<\/address>/" /var/ossec/etc/ossec.conf

# 5. Enable and Start the Service
echo "--- Starting Service..."
sysrc wazuh_agent_enable="YES"
service wazuh-agent start

# 6. Verify
echo "--- Status ---"
service wazuh-agent status

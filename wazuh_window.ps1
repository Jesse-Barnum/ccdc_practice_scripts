# Define the Wazuh Manager IP address
$wazuhManagerIp = "<WAZUH_MANAGER_IP>"

# Define the local path for the installer
$installerPath = "C:\Temp\wazuh-agent-installer.msi"

# Create the Temp directory if it doesn't exist
if (-not (Test-Path C:\Temp)) {
    New-Item -Path C:\Temp -ItemType Directory | Out-Null
}

# Download the latest Wazuh agent MSI installer (ensure you use the correct version URL)
# The URL below is an example, find the latest version on the official Wazuh documentation
$downloadUrl = "packages.wazuh.com" # Example URL
Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

# Define installation arguments for an unattended installation
# The /q argument is for quiet (unattended) installation
# WAZUH_MANAGER is the IP/hostname of the manager
# WAZUH_AGENT_NAME specifies the agent name (optional, defaults to computer name)
# WAZUH_AGENT_GROUP specifies an agent group (optional)
$installArgs = "/q WAZUH_MANAGER=`"$wazuhManagerIp`" WAZUH_AGENT_NAME=`"$env:COMPUTERNAME`" "

# Execute the MSI installer
Start-Process -FilePath msiexec.exe -ArgumentList "$installArgs /i $installerPath" -Wait

# Note: The agent service starts automatically after installation by default.
# If needed, you can manually start the service with:
# Start-Service -Name wazuh-agent

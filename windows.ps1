<#
.SYNOPSIS
    Installs and configures both ClamAV and the Wazuh agent on a Windows server.
.DESCRIPTION
    This script automates the following tasks:
    1. Downloads and installs ClamAV.
    2. Configures ClamAV for on-access scanning and scheduled hourly scans.
    3. Downloads and installs the Wazuh agent.
    4. Configures the Wazuh agent to connect to the manager and enables required modules.
    5. Starts all services and provides a final verification check.
#>

# --- Configuration Variables ---
$ClamAV_Installer = "clamav-1.3.1.win.x64.msi" # Change this if you download a different version
$Wazuh_Installer = "wazuh-agent-4.7.3.msi" # Change this if needed
$Wazuh_Manager_IP = "10.0.0.5" # IMPORTANT: Set your Wazuh Manager IP here

# --- SCRIPT START ---

# --- Section 1: ClamAV Installation & Configuration ---
Write-Host "--- Starting ClamAV Setup ---" -ForegroundColor Yellow

# Download ClamAV
$clamavDownloadUrl = "https://www.clamav.net/downloads/production/$ClamAV_Installer"
Write-Host "Downloading ClamAV from $clamavDownloadUrl..."
Invoke-WebRequest -Uri $clamavDownloadUrl -OutFile $ClamAV_Installer

# Install ClamAV silently
Write-Host "Installing ClamAV..."
Start-Process msiexec.exe -ArgumentList "/i `"$ClamAV_Installer`" /qn" -Wait

# Configure ClamAV for real-time and scheduled scanning
Write-Host "Configuring ClamAV..."
$clamConfigFile = "C:\ProgramData\ClamAV\clamd.conf"
Add-Content -Path $clamConfigFile -Value "`nOnAccessPrevention yes"

# Update virus definitions
Write-Host "Updating Virus Definitions..."
& "C:\Program Files\ClamAV\freshclam.exe"

# Schedule hourly scans
Write-Host "Scheduling Hourly Scan Task..."
$action = New-ScheduledTaskAction -Execute 'C:\Program Files\ClamAV\clamscan.exe' -Argument '--infected --recursive C:\Users'
$trigger = New-ScheduledTaskTrigger -Hourly
Register-ScheduledTask -TaskName "ClamAV Hourly Scan" -Action $action -Trigger $trigger -User "SYSTEM" -Force

# Start ClamAV services
Write-Host "Starting ClamAV services..."
Start-Service -Name "ClamAV ClamD"
Start-Service -Name "ClamAV FreshClam"

Write-Host "--- ClamAV Setup Complete ---" -ForegroundColor Green

# --- Section 2: Wazuh Agent Installation & Configuration ---
Write-Host "`n--- Starting Wazuh Agent Setup ---" -ForegroundColor Yellow

# Download Wazuh Agent
$wazuhDownloadUrl = "https://packages.wazuh.com/4.x/windows/$Wazuh_Installer"
Write-Host "Downloading Wazuh Agent from $wazuhDownloadUrl..."
Invoke-WebRequest -Uri $wazuhDownloadUrl -OutFile $Wazuh_Installer

# Install Wazuh Agent silently and register with the manager
Write-Host "Installing Wazuh Agent..."
Start-Process msiexec.exe -ArgumentList "/i `"$Wazuh_Installer`" /qn WAZUH_MANAGER=`"$Wazuh_Manager_IP`"" -Wait

# Configure Wazuh Agent modules
Write-Host "Configuring Wazuh Agent modules..."
$wazuhConfigFile = "C:\Program Files (x86)\ossec-agent\ossec.conf"
$configContent = Get-Content -Path $wazuhConfigFile -Raw
$configContent = $configContent -replace "<syscollector><disabled>yes</disabled></syscollector>", "<syscollector><disabled>no</disabled></syscollector>"
$configContent = $configContent -replace '<fim><disabled>yes</disabled></fim>', '<fim><disabled>no</disabled><directories realtime="yes">C:\Users</directories></fim>'
Set-Content -Path $wazuhConfigFile -Value $configContent

# Restart the Wazuh agent to apply the new configuration
Write-Host "Restarting Wazuh Agent..."
Restart-Service -Name "Wazuh"

Write-Host "--- Wazuh Agent Setup Complete ---" -ForegroundColor Green

# --- Section 3: Final Verification ---
Write-Host "`n--- Verifying All Services ---" -ForegroundColor Cyan
Get-Service -Name "ClamAV*", "Wazuh" | Select-Object Status, Name, DisplayName

Write-Host "`n--- Full Installation Complete ---" -ForegroundColor Green

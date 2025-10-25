# --- Step 2: Install and Configure ClamAV ---
Write-Host "Installing ClamAV..."
# 1. This is the installation command from the PDF
msiexec /i ".\clamav-1.4.3.win.x64.msi" ADDLOCAL="ClamAV,FreshClam" /qn

# 2. NECESSARY commands to fulfill the "on-access" and "hourly" requirements
Write-Host "Configuring ClamAV..."
$clamConfigFile = "C:\ProgramData\ClamAV\clamd.conf"
Add-Content -Path $clamConfigFile -Value "`nOnAccessPrevention yes"
& "C:\Program Files\ClamAV\freshclam.exe" # Necessary to get definitions
$action = New-ScheduledTaskAction -Execute 'C:\Program Files\ClamAV\clamscan.exe' -Argument '--infected --recursive C:\Users'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 9999)
Register-ScheduledTask -TaskName "ClamAV Hourly Scan" -Action $action -Trigger $trigger -User "SYSTEM" -Force
Start-Service -Name "ClamAV ClamD"
Start-Service -Name "ClamAV FreshClam"

# --- Step 3: Install and Configure Wazuh Agent ---
Write-Host "Installing Wazuh Agent..."
# 1. This is the installation command from the PDF
msiexec /i ".\wazuh-agent-4.7.3.msi" WAZUH_MANAGER="10.0.0.5" WAZUH_REGISTRATION_PASSWORD="MyStrongKey" /qn

# 2. NECESSARY commands to enable the modules from the PDF
Write-Host "Configuring Wazuh Agent..."
$wazuhConfigFile = "C:\Program Files (x86)\ossec-agent\ossec.conf"
$configContent = Get-Content -Path $wazuhConfigFile -Raw
$configContent = $configContent -replace "<syscollector><disabled>yes</disabled></syscollector>", "<syscollector><disabled>no</disabled></syscollector>"
$configContent = $configContent -replace '<fim><disabled>yes</disabled></fim>', '<fim><disabled>no</disabled><directories realtime="yes">C:\Users</directories></fim>'
Set-Content -Path $wazuhConfigFile -Value $configContent

# 3. NECESSARY command, as implied by "Don't forget to restart"
Write-Host "Restarting Wazuh Agent..."
Restart-Service -Name "Wazuh"

Write-Host "--- Script Complete ---"

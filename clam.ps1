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


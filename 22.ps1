# ==========================================
# INJECT_22.ps1 (Run as Administrator)
# ==========================================
Write-Host "Installing Vulnerable Windows Features (SMBv1, PowerShell v2)..."
Install-WindowsFeature -Name FS-SMB1, PowerShell-V2 -IncludeManagementTools -ErrorAction SilentlyContinue

Write-Host "Injecting 22 Advanced Configuration Vulnerabilities..."

# Helper to safely create registry paths if they don't exist
function Set-RegKey {
    param([string]$Path, [string]$Name, [int]$Value, [string]$Type="DWord")
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force | Out-Null
}

# 1. AlwaysInstallElevated Enabled
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" "AlwaysInstallElevated" 1
Set-RegKey "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer" "AlwaysInstallElevated" 1

# 2. Blank Password Network Logon Allowed
Set-RegKey "HKLM:\System\CurrentControlSet\Control\Lsa" "LimitBlankPasswordUse" 0

# 3 & 4. UAC Elevates Without Prompting & Secure Desktop Disabled
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 0
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 0

# 5. LM Hash Generation Enabled
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "NoLMHash" 0

# 7. LLMNR Enabled
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" "EnableMulticast" 1

# 8. NetBIOS over TCP/IP Enabled
Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Invoke-WmiMethod -Name SetTCPIPNetbios -ArgumentList 1 | Out-Null

# 9. SMB Signing Disabled
Set-RegKey "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters" "RequireSecuritySignature" 0

# 10. IPv6 Transition Technologies Active (Teredo/ISATAP)
netsh interface teredo set state enterpriseclient | Out-Null
netsh interface isatap set state enabled | Out-Null

# 11. AutoPlay Globally Enabled
Set-RegKey "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 0
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 0

# 12 & 13. Screen Saver Password Lock Disabled & Timeout Excessive
Set-RegKey "HKCU:\Control Panel\Desktop" "ScreenSaverIsSecure" 0 "String"
Set-RegKey "HKCU:\Control Panel\Desktop" "ScreenSaveTimeOut" 14400 "String"

# 14. Shutdown Without Logon
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "shutdownwithoutlogon" 1

# 15. Remote Registry Service Running
Set-Service -Name RemoteRegistry -StartupType Automatic
Start-Service RemoteRegistry -ErrorAction SilentlyContinue

# 16. Remote Assistance Enabled
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 1
netsh advfirewall firewall set rule group="Remote Assistance" new enable=Yes | Out-Null

# 18. IE Enhanced Security Configuration (ESC) Disabled for Admins & Users
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" "IsInstalled" 0
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" "IsInstalled" 0

# 19. LSA Protection Disabled
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPL" 0

# 20. Idle RDP Sessions Never Disconnect
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" "MaxIdleTime" 0

# 21. Windows Defender C:\ Exclusion
Add-MpPreference -ExclusionPath "C:\" -ErrorAction SilentlyContinue

# 22. Event Viewer Logon Logging Disabled
auditpol /set /category:"Logon/Logoff" /success:disable /failure:disable | Out-Null

Write-Host "Injection Complete. Note: Some group policy and registry changes may require a server reboot to fully take effect."

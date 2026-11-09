# ==========================================
# INJECT_37.ps1 (Run as Administrator)
# ==========================================
Write-Host "Installing Windows Features (IIS, FTP, Telnet, TFTP, SNMP, RRAS)..."
Install-WindowsFeature -Name Web-Server, Web-Mgmt-Console, Web-Dir-Browsing, Web-DAV-Publishing, Web-Ftp-Server, Web-Ftp-Service, Telnet-Client, TFTP-Client, Print-Services, SNMP-Service, Routing -IncludeManagementTools

Write-Host "Configuring 37 Vulnerabilities..."

# 1-4. IIS & FTP Config
Import-Module WebAdministration
Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -Value $true -PSPath IIS:\
# Enable WebDAV
Set-WebConfigurationProperty -Filter /system.webServer/webdav/authoring -Name enabled -Value $true -PSPath IIS:\
# Change DefaultAppPool to LocalSystem
Set-ItemProperty "IIS:\AppPools\DefaultAppPool" -Name processModel.identityType -Value "LocalSystem"
# Disable FTP User Isolation
Set-WebConfigurationProperty -Filter /system.applicationHost/sites/siteDefaults/ftpServer/userIsolation -Name mode -Value "None" -PSPath IIS:\

# 5. WinRM Cleartext
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# 6-10. Mock Third-Party Software (Simulated for fast deployment)
$mockApps = @(
    "C:\Program Files\TightVNC\tvnserver.exe",
    "C:\Program Files\Wireshark\wireshark.exe",
    "C:\Program Files\Npcap\npcap.sys",
    "C:\Program Files\Webex\webex.exe",
    "C:\Program Files (x86)\Steam\steam.exe"
)
foreach ($app in $mockApps) {
    $dir = Split-Path $app
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    New-Item -ItemType File -Path $app -Force | Out-Null
}

# 11-14. Unnecessary Services
Set-Service -Name Spooler -StartupType Automatic; Start-Service Spooler
Set-Service -Name RemoteAccess -StartupType Automatic; Start-Service RemoteAccess
Set-Service -Name upnphost -StartupType Automatic; Start-Service upnphost
Set-Service -Name SNMP -StartupType Automatic; Start-Service SNMP

# 15-21. Local Security Policy & Account Policies (via Registry and Net.exe)
# Net accounts for password age/length
net accounts /minpwlen:0 /maxpwage:unlimited /minpwage:0 /uniquepw:0
# Registry settings for LSA, NTLMv1, and Anonymous
$LsaPath = "HKLM:\System\CurrentControlSet\Control\Lsa"
Set-ItemProperty -Path $LsaPath -Name "LmCompatibilityLevel" -Value 1 # NTLMv1
Set-ItemProperty -Path $LsaPath -Name "RestrictAnonymous" -Value 0
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters" -Name "NullSessionPipes" -Value @("srvsvc", "browser")
# Disable CAD
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DisableCAD" -Value 1

# 22-24. Firewall Modifications
New-NetFirewallRule -DisplayName "Allow ICMP In" -Protocol ICMPv4 -Action Allow -Profile Any
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -RemoteAddress Any
# Local subnet bypass simulated by enabling a broad inbound rule
New-NetFirewallRule -DisplayName "Local Subnet Bypass" -Direction Inbound -Action Allow -RemoteAddress "LocalSubnet"

# 25. Poisoned Hosts File
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "192.168.1.100 update.microsoft.com"

# 26. RDP Clipboard Allowed (Ensure it's NOT disabled)
$RdpPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
if (!(Test-Path $RdpPol)) { New-Item -Path $RdpPol -Force | Out-Null }
Set-ItemProperty -Path $RdpPol -Name "fDisableClip" -Value 0

# 27. Windows Script Host (WSH) Enabled
$WshPath = "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"
if (!(Test-Path $WshPath)) { New-Item -Path $WshPath -Force | Out-Null }
Set-ItemProperty -Path $WshPath -Name "Enabled" -Value 1

# 28. Command Prompt Disabled
$CmdPol = "HKCU:\Software\Policies\Microsoft\Windows\System"
if (!(Test-Path $CmdPol)) { New-Item -Path $CmdPol -Force | Out-Null }
Set-ItemProperty -Path $CmdPol -Name "DisableCMD" -Value 1

# 29. Temp Directory Executable
$Acl = Get-Acl "C:\Windows\Temp"
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ExecuteFile", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl "C:\Windows\Temp" $Acl

# 30. SAM File Backup Exposed
New-Item -ItemType File -Path "C:\Users\Public\Desktop\SAM.bak" -Force | Out-Null

# 31. Admin Shares Exposed
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Value 1

# 32. Hidden File Extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1

# 33. Pagefile Not Cleared on Shutdown
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 0

# 34. RDP Certificate Checking Disabled
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "SecurityLayer" -Value 0

# 35. IPv4 Source Routing Allowed
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters" -Name "DisableIPSourceRouting" -Value 1

# 36. Cleartext LDAP Authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\ldap" -Name "LDAPClientIntegrity" -Value 0

# 37. Sticky Notes Plaintext Passwords
New-Item -ItemType File -Path "C:\Users\Public\Desktop\StickyNote_Passwords.txt" -Value "Administrator: platypus123" -Force | Out-Null

Write-Host "Injection Complete."

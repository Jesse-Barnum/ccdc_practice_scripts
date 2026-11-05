# --- 0. PRE-REQUISITES & SLA SETUP ---
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<h1>O.W.C.A. Secure Portal</h1>"

# --- 1. ACCOUNT CREATION & MISCONFIGURATION ---
$Authorized = @("Phineas", "Ferb", "Isabella", "Buford", "Candice", "Baljeet", "Perry")
foreach ($user in $Authorized) { Net user $user "SecurePass123!" /add }
Net localgroup administrators Phineas /add; Net localgroup administrators Ferb /add

Net user guest /active:yes                                                  # Vuln 1: Guest Active
Net user Doofensmirtz "CurseYouPerryThePlatypus!" /add                      
Net localgroup administrators Doofensmirtz /add                             # Vuln 2: Rogue Admin
Net user Norm "RobotPass!" /add                                             # Vuln 3: Rogue Local User
Net localgroup administrators Candice /add                                  # Vuln 4: Misconfigured Auth User

# --- 2. POLICY DEGRADATION ---
secedit /export /cfg C:\secpol.cfg
(Get-Content C:\secpol.cfg).Replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg # Vuln 5: No Complexity
(Get-Content C:\secpol.cfg).Replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 0") | Out-File C:\secpol.cfg # Vuln 6: Min Length 0
(Get-Content C:\secpol.cfg).Replace("LockoutBadCount = 0", "LockoutBadCount = 0") | Out-File C:\secpol.cfg # Vuln 7: No Lockout
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY; Remove-Item C:\secpol.cfg -Force

# --- 3. NETWORK & PROTOCOL VULNERABILITIES ---
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False        # Vuln 8: Firewall Disabled
New-NetFirewallRule -DisplayName "Inator-Uplink" -Direction Inbound -LocalPort 4444 -Protocol TCP -Action Allow # Vuln 9: Malicious Rule
Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force                 # Vuln 10: SMBv1 Enabled
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0 # Vuln 11: RDP NLA Disabled
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Value 1 # Vuln 12: WDigest Cleartext

# --- 4. OS & MALWARE ARTIFACTS ---
Set-MpPreference -DisableRealtimeMonitoring $true                           # Vuln 13: Defender Disabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 # Vuln 14: UAC Disabled

# Benign Malware Simulator (inator.exe) - An infinite sleep loop that looks like a running process
$MalwareCode = "using System.Threading; class Inator { static void Main() { while(true) { Thread.Sleep(60000); } } }"
Add-Type -TypeDefinition $MalwareCode -Language CSharp -OutputAssembly "C:\Windows\System32\inator.exe" # Vuln 15: Malicious Executable

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Doof-Update" -Value "C:\Windows\System32\inator.exe" # Vuln 16: Registry Run Key
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\inator.exe"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "TriStateAreaTakeover" -Action $action -Trigger $trigger -User "SYSTEM" # Vuln 17: Scheduled Task

New-Item -ItemType File -Force -Path "C:\Users\Public\Desktop\LoveHandel_Song.mp3" # Vuln 18: Prohibited Media

# --- 5. FORENSICS SETUP ---
$FDir = "C:\Users\Public\Desktop\Forensics"; New-Item -ItemType Directory -Force -Path $FDir
"Q1: Which unauthorized user from Doofenshmirtz Evil Incorporated was improperly added to the local Administrators group?" | Out-File "$FDir\Q1_Prompt.txt"
"Q2: A rogue executable was planted in the System32 directory to maintain persistence. What is the exact filename of this inator?" | Out-File "$FDir\Q2_Prompt.txt"
"Q3: Doofenshmirtz hid a secret blueprint IP address inside an Alternate Data Stream (ADS) attached to C:\Users\Public\Desktop\OWCA_Regulations.txt. What is the hidden IP address?" | Out-File "$FDir\Q3_Prompt.txt"
New-Item -ItemType File -Force -Path "$FDir\Q1_Answer.txt"; New-Item -ItemType File -Force -Path "$FDir\Q2_Answer.txt"; New-Item -ItemType File -Force -Path "$FDir\Q3_Answer.txt"

# Q3 Hidden File Generation
New-Item -ItemType File -Force -Path "C:\Users\Public\Desktop\OWCA_Regulations.txt" -Value "O.W.C.A. Top Secret Regulations."
Set-Content -Path "C:\Users\Public\Desktop\OWCA_Regulations.txt" -Stream "blueprint" -Value "203.0.113.85"


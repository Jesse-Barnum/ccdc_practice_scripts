$DesktopPath = "$env:PUBLIC\Desktop\ScoreReport.html"

while ($true) {
    $Score = 0; $MaxScore = 21; $Penalties = 0
    $Html = "<html><style>body{font-family: Arial;} .g{color: green;} .r{color: red;}</style><body><h2>O.W.C.A. Windows Scoring</h2><ul>"

    # Accounts (4 points)
    if ((Get-WmiObject Win32_UserAccount -Filter "Name='Guest'").Disabled) { $Score++; $Html += "<li class='g'>[+] Guest disabled</li>" }
    if ((Get-WmiObject Win32_UserAccount -Filter "Name='Administrator'").Disabled) { $Score++; $Html += "<li class='g'>[+] Default Admin disabled</li>" }
    if (-not (Get-WmiObject Win32_UserAccount -Filter "Name='Doofensmirtz'")) { $Score++; $Html += "<li class='g'>[+] Doofensmirtz removed</li>" }
    if (-not (Get-WmiObject Win32_UserAccount -Filter "Name='Norm'")) { $Score++; $Html += "<li class='g'>[+] Norm removed</li>" }
    if (-not ((Get-LocalGroupMember -Group "Administrators").Name -match "Candice")) { $Score++; $Html += "<li class='g'>[+] Candice demoted</li>" }

    # Policies (3 points)
    secedit /export /cfg C:\temp_secpol.cfg | Out-Null; $Pol = Get-Content C:\temp_secpol.cfg
    if ($Pol -match "PasswordComplexity = 1") { $Score++; $Html += "<li class='g'>[+] Password complexity enforced</li>" }
    if ($Pol -match "MinimumPasswordLength = 14") { $Score++; $Html += "<li class='g'>[+] Secure password length set</li>" }
    if (-not ($Pol -match "LockoutBadCount = 0")) { $Score++; $Html += "<li class='g'>[+] Account lockout enabled</li>" }
    Remove-Item C:\temp_secpol.cfg -ErrorAction SilentlyContinue

    # Network (5 points)
    if (((Get-NetFirewallProfile -Profile Domain,Public,Private).Enabled -eq $true).Count -eq 3) { $Score++; $Html += "<li class='g'>[+] Firewall active</li>" }
    if (-not (Get-NetFirewallRule -DisplayName "Inator-Uplink" -ErrorAction SilentlyContinue)) { $Score++; $Html += "<li class='g'>[+] Malicious rule removed</li>" }
    if (-not (Get-SmbServerConfiguration).EnableSMB1Protocol) { $Score++; $Html += "<li class='g'>[+] SMBv1 Disabled</li>" }
    if ((Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication") -eq 1) { $Score++; $Html += "<li class='g'>[+] RDP NLA Enforced</li>" }
    if ((Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -ErrorAction SilentlyContinue) -eq 0) { $Score++; $Html += "<li class='g'>[+] WDigest credentials secured</li>" }
    
    # OS & Files (5 points)
    if ((Get-MpPreference).DisableRealtimeMonitoring -eq $false) { $Score++; $Html += "<li class='g'>[+] Defender enabled</li>" }
    if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue) -eq 1) { $Score++; $Html += "<li class='g'>[+] UAC Enabled</li>" }
    if (-not (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Doof-Update" -ErrorAction SilentlyContinue)) { $Score++; $Html += "<li class='g'>[+] Malicious Run key removed</li>" }
    if (-not (Get-ScheduledTask -TaskName "TriStateAreaTakeover" -ErrorAction SilentlyContinue)) { $Score++; $Html += "<li class='g'>[+] Scheduled task removed</li>" }
    if (-not (Test-Path "C:\Windows\System32\inator.exe")) { $Score++; $Html += "<li class='g'>[+] Malicious executable deleted</li>" }
    if (-not (Test-Path "C:\Users\Public\Desktop\LoveHandel_Song.mp3")) { $Score++; $Html += "<li class='g'>[+] Prohibited media removed</li>" }

    # Forensics (3 points)
    $FDir = "C:\Users\Public\Desktop\Forensics"
    if ((Get-Content "$FDir\Q1_Answer.txt" -ErrorAction SilentlyContinue) -match "Doofensmirtz") { $Score++; $Html += "<li class='g'>[+] Forensics Q1 Correct</li>" }
    if ((Get-Content "$FDir\Q2_Answer.txt" -ErrorAction SilentlyContinue) -match "inator.exe") { $Score++; $Html += "<li class='g'>[+] Forensics Q2 Correct</li>" }
    if ((Get-Content "$FDir\Q3_Answer.txt" -ErrorAction SilentlyContinue) -match "203.0.113.85") { $Score++; $Html += "<li class='g'>[+] Forensics Q3 Correct</li>" }

    # SLA Checks
    if ((Get-Service -Name W3SVC).Status -ne 'Running') { 
        $Penalties += 3; $Html += "<li class='r'>[-] PENALTY: Web Server SLA is DOWN</li>" 
    }

    $Html += "</ul><h3>Score: $Score / $MaxScore | Penalties: -$Penalties</h3></body></html>"
    $Html | Out-File $DesktopPath -Force
    Start-Sleep -Seconds 30
}

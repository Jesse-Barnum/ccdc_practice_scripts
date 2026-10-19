<#
.SYNOPSIS
    Configures Password and Account Lockout Security Policies.
.DESCRIPTION
    Detects if the executing machine is an Active Directory Domain Controller. 
    If it is, it updates the Default Domain Password Policy for the entire AD environment. 
    If it is a standalone or domain-joined client/server, it configures the Local Security Policy.
#>

# Check the WMI DomainRole property (4 = Backup Domain Controller, 5 = Primary Domain Controller)
$isDC = (Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4

if ($isDC) {
    Write-Host "Domain Controller detected. Applying AD Default Domain Password Policy..." -ForegroundColor Cyan
    
    # Load the AD module (available by default on DCs)
    Import-Module ActiveDirectory
    $domain = (Get-ADDomain).DistinguishedName
    
    # AD requires TimeSpan formatting for ages and durations (Days.Hours:Minutes:Seconds)
    Set-ADDefaultDomainPasswordPolicy -Identity $domain `
        -PasswordHistoryCount 3 `
        -MinPasswordAge "00:00:00" `
        -MaxPasswordAge "365.00:00:00" `
        -MinPasswordLength 12 `
        -ComplexityEnabled $true `
        -LockoutThreshold 5 `
        -LockoutDuration "01:00:00" `
        -LockoutObservationWindow "01:00:00"
        
    Write-Host "Domain policy successfully updated." -ForegroundColor Green

} else {
    Write-Host "Local machine detected. Applying Local Security Policy..." -ForegroundColor Cyan
    
    # Secedit requires a specifically formatted .inf file saved with Unicode encoding
    $templatePath = "$env:TEMP\CustomSecPol.inf"
    
    # Windows Local Policy uses minutes for lockout durations and days for password ages
    $secpol = @"
[Unicode]
Unicode=yes
[System Access]
MinimumPasswordAge = 0
MaximumPasswordAge = 365
MinimumPasswordLength = 12
PasswordComplexity = 1
PasswordHistorySize = 3
LockoutBadCount = 5
ResetLockoutCount = 60
LockoutDuration = 60
"@

    $secpol \vert{} Out-File -FilePath$templatePath -Encoding Unicode
    
    # Merge the custom template into the active local security database
    secedit.exe /configure /db "$env:windir\security\database\secedit.sdb" /cfg $templatePath /areas SECURITYPOLICY /quiet
    
    # Force the local machine to immediately apply the database changes
    gpupdate /force /quiet
    Write-Host "Local policy successfully updated." -ForegroundColor Green
    
    # Clean up the temporary template
    Remove-Item -Path $templatePath -Force
}

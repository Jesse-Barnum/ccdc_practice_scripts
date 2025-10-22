# PowerShell Script to Install ClamAV on Windows
#
# This script will:
# 1. Ensure it is running with Administrator privileges (self-elevate).
# 2. Check for 'winget' or 'choco' package managers.
# 3. If neither is found, it will AUTOMATICALLY install Chocolatey.
# 4. Use the available package manager to install ClamAV.
# 5. Configure ClamAV, update definitions, and start services.

# --- 1. Self-Elevation: Check for Admin rights and re-launch if necessary ---
function Start-Elevated {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "This script requires Administrator privileges. Attempting to re-launch as an Administrator..."
        $arguments = "& '" + $myinvocation.mycommand.definition + "'"
        Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
        exit
    }
}
Start-Elevated

# --- Script Header ---
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host " ClamAV Installation Process..." -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host ""

# --- 2. Check for Package Managers and Install Chocolatey if Needed ---
$packageManager = $null
if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    $packageManager = "winget"
    Write-Host "Found package manager: winget" -ForegroundColor Cyan
}
elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
    $packageManager = "choco"
    Write-Host "Found package manager: choco" -ForegroundColor Cyan
}
else {
    Write-Warning "No supported package manager (winget or choco) found."
    Write-Host "Attempting to install Chocolatey... This may take a few minutes." -ForegroundColor Yellow
    
    try {
        # Set execution policy to allow installation script to run
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        
        # Download and run the Chocolatey installation script
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; # Tls 1.2
        $installScript = Invoke-WebRequest -Uri "https://community.chocolatey.org/install.ps1" -UseBasicParsing
        Invoke-Expression $installScript.Content

        # Refresh environment variables to find 'choco'
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Get-Command "choco" -ErrorAction SilentlyContinue) {
            Write-Host "Chocolatey installed successfully." -ForegroundColor Green
            $packageManager = "choco"
        } else {
            throw "Chocolatey installation appeared to succeed, but the 'choco' command is still not found."
        }
    }
    catch {
        Write-Error "Failed to automatically install Chocolatey. Cannot proceed."
        Write-Error $_.Exception.Message
        exit 1
    }
}
Write-Host ""

# --- 3. Install ClamAV using the determined package manager ---
Write-Host "Starting ClamAV installation using $packageManager..." -ForegroundColor Yellow
try {
    if ($packageManager -eq "winget") {
        Start-Process "winget" -ArgumentList "install --id=Cisco.ClamAV --silent --accept-source-agreements --accept-package-agreements" -Wait
    }
    elseif ($packageManager -eq "choco") {
        Start-Process "choco" -ArgumentList "install clamav -y --force" -Wait
    }
    
    # Verify installation by checking the directory
    $clamDir = "C:\Program Files\ClamAV"
    if (-not (Test-Path $clamDir)) {
        throw "Installation command ran, but ClamAV directory was not found at '$clamDir'."
    }
    Write-Host "ClamAV package installed successfully." -ForegroundColor Green
}
catch {
    Write-Error "ClamAV installation failed."
    Write-Error $_.Exception.Message
    exit 1
}
Write-Host ""

# --- 4. Post-Installation Configuration ---
Write-Host "Running post-installation configuration..." -ForegroundColor Yellow
try {
    # ClamAV's config files are in a different location when installed via choco/winget
    $configDir = "C:\Program Files\ClamAV"
    
    # Rename/copy example config files
    Copy-Item "$configDir\conf_examples\freshclam.conf.sample" "$configDir\freshclam.conf" -Force
    Copy-Item "$configDir\conf_examples\clamd.conf.sample" "$configDir\clamd.conf" -Force
    
    # Comment out the "Example" line in both config files
    (Get-Content "$configDir\freshclam.conf") -replace "Example", "# Example" | Set-Content "$configDir\freshclam.conf"
    (Get-Content "$configDir\clamd.conf") -replace "Example", "# Example" | Set-Content "$configDir\clamd.conf"
    
    # Add a line to clamd.conf to specify the database directory
    Add-Content "$configDir\clamd.conf" "`nDatabaseDirectory $configDir\database"
    
    Write-Host "Configuration files created." -ForegroundColor Green
}
catch {
    Write-Error "Failed to create configuration files."
    Write-Error $_.Exception.Message
    exit 1
}
Write-Host ""

# --- 5. Update Virus Definitions ---
Write-Host "Updating virus definitions with freshclam..." -ForegroundColor Yellow
try {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "$configDir\freshclam.exe"
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($processInfo)
    $process.WaitForExit()
    
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    
    Write-Host $stdout
    if ($process.ExitCode -ne 0) {
        throw "freshclam update failed.`n$stderr"
    }
    Write-Host "Virus definitions updated." -ForegroundColor Green
}
catch {
    Write-Error "Failed to update virus definitions."
    Write-Error $_.Exception.Message
    exit 1
}
Write-Host ""

# --- 6. Install, Register, and Start Services ---
Write-Host "Registering and starting ClamAV services..." -ForegroundColor Yellow
try {
    # Install clamd as a service
    Start-Process "$configDir\clamd.exe" -ArgumentList "--install" -Wait
    # Install freshclam as a service
    Start-Process "$configDir\freshclam.exe" -ArgumentList "--install" -Wait
    
    # Start the services
    Start-Service -Name "ClamAV Clamd" -ErrorAction Stop
    Start-Service -Name "ClamAV FreshClam" -ErrorAction Stop
    
    Write-Host "ClamAV services (ClamAV Clamd, ClamAV FreshClam) are now running." -ForegroundColor Green
}
catch {
    Write-Error "Failed to start ClamAV services."
    Write-Warning "This can sometimes happen on the first run. Please try rebooting."
    Write-Error $_.Exception.Message
}
Write-Host ""

# --- Final Message ---
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host " ClamAV installation and setup complete!" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green


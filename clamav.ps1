#requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs and configures ClamAV for Windows.
.DESCRIPTION
    This script automates the installation and initial setup of ClamAV on a Windows system.
    It prioritizes using the 'winget' package manager, falling back to 'Chocolatey' if needed.
    Post-installation, it configures the necessary files, updates virus definitions,
    and sets up the ClamAV services to run in the background.
.NOTES
    Author: Gemini
    Version: 1.0
#>

# --- Function to print messages in a consistent format ---
function Write-Log {
    param(
        [string]$Message
    )
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host ""
}

# --- Main Script ---

# 1. Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as an Administrator. Please re-launch in an elevated PowerShell session."
    # The '#requires -RunAsAdministrator' line at the top should prevent this, but this is a fallback check.
    Exit
}

Write-Log "Starting ClamAV installation process..."

# 2. Detect Package Manager and Install
$clamavInstalled = $false
# Prioritize winget (modern, built-in)
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if ($null -ne $wingetPath) {
    Write-Log "Detected 'winget'. Attempting installation..."
    try {
        winget install --id Cisco.ClamAV -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            $clamavInstalled = $true
            Write-Host "ClamAV installed successfully via winget." -ForegroundColor Green
        } else {
            throw "Winget installation failed with exit code $LASTEXITCODE."
        }
    } catch {
        Write-Error "An error occurred during winget installation: $_"
        Exit
    }
} else {
    # Fallback to Chocolatey
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if ($null -ne $chocoPath) {
        Write-Log "Detected 'Chocolatey'. Attempting installation..."
        try {
            choco install clamav -y
            if ($LASTEXITCODE -eq 0) {
                $clamavInstalled = $true
                Write-Host "ClamAV installed successfully via Chocolatey." -ForegroundColor Green
            } else {
                throw "Chocolatey installation failed with exit code $LASTEXITCODE."
            }
        } catch {
            Write-Error "An error occurred during Chocolatey installation: $_"
            Exit
        }
    }
}

# If neither was found, exit
if (-not $clamavInstalled) {
    Write-Error "No supported package manager (winget or choco) found. Cannot proceed with installation."
    Exit
}


# 3. Post-Installation Configuration
Write-Log "Configuring ClamAV..."
# Define default installation path
$clamavPath = "C:\Program Files\ClamAV"
if (-not (Test-Path $clamavPath)) {
    Write-Error "ClamAV installation directory not found at '$clamavPath'. Aborting configuration."
    Exit
}

$confFiles = @{
    "clamd.conf" = "$clamavPath\clamd.conf.sample";
    "freshclam.conf" = "$clamavPath\freshclam.conf.sample";
}

foreach ($conf in $confFiles.GetEnumerator()) {
    $targetFile = "$clamavPath\$($conf.Name)"
    $sampleFile = $conf.Value

    Write-Host "Configuring $($conf.Name)..."
    Copy-Item -Path $sampleFile -Destination $targetFile -Force
    # Remove the "Example" line to make the config file valid
    (Get-Content $targetFile).Replace('Example', '# Example') | Set-Content $targetFile
}


# 4. Update Virus Definitions
Write-Log "Updating virus definitions with freshclam. This may take several minutes..."
# We need to execute freshclam from its directory
Push-Location $clamavPath
try {
    .\freshclam.exe
} catch {
    Write-Warning "Freshclam update failed. This can sometimes happen on the first run. You may need to run it manually."
}
Pop-Location


# 5. Install and Start Services
Write-Log "Installing and starting ClamAV services..."
Push-Location $clamavPath

# Install the services
try {
    Write-Host "Installing clamd (scanning daemon) service..."
    .\clamd.exe --install
    Write-Host "Installing freshclam (updater) service..."
    .\freshclam.exe --install
} catch {
    Write-Error "Failed to install ClamAV services: $_"
    Pop-Location
    Exit
}

# Start the services
$serviceClamD = "ClamAV Clamd Service"
$serviceFreshclam = "ClamAV Freshclam Service"

Start-Service -Name $serviceClamD -ErrorAction SilentlyContinue
Start-Service -Name $serviceFreshclam -ErrorAction SilentlyContinue

Pop-Location


# 6. Verification
Write-Log "Verifying service status..."
try {
    Get-Service -Name $serviceClamD, $serviceFreshclam | Format-Table -AutoSize
    Write-Log "ClamAV for Windows installation and setup complete!"
    Write-Host "You can perform a manual scan with a command like: & 'C:\Program Files\ClamAV\clamscan.exe' -r C:\Users" -ForegroundColor Yellow
} catch {
    Write-Error "Could not retrieve ClamAV service status. Please check the Services application manually."
}


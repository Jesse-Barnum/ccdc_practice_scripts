# PowerShell Script to Interactively Install the Wazuh Agent on Windows from a Local File
#
# This script will:
# 1. Ensure it is running with Administrator privileges (self-elevate).
# 2. Prompt the user for the path to the local Wazuh agent MSI file.
# 3. Prompt the user for the Wazuh Manager's IP address.
# 4. Install the agent silently, configured to connect to the provided manager IP.
# 5. Start the Wazuh service.

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
Write-Host "---------------------------------------------------" -ForegroundColor Green
Write-Host " Wazuh Agent Interactive Installer (from Local File)" -ForegroundColor Green
Write-Host "---------------------------------------------------" -ForegroundColor Green
Write-Host ""

# --- 2. Prompt for Local MSI File Path ---
$msiPath = ""
while (-not $msiPath) {
    $msiPath = Read-Host "Please enter the full path to the Wazuh agent .msi installer file (e.g., C:\Users\Admin\Downloads\wazuh-agent.msi)"
    if (-not (Test-Path $msiPath -PathType Leaf)) {
        Write-Warning "File not found at the specified path. Please check the path and try again."
        $msiPath = "" # Reset variable to loop again
    }
}
Write-Host "Using installer located at '$msiPath'." -ForegroundColor Cyan
Write-Host ""


# --- 3. Prompt for Wazuh Manager IP Address ---
$wazuhManagerIp = ""
while (-not $wazuhManagerIp) {
    $wazuhManagerIp = Read-Host "Please enter the Wazuh Manager IP address"
    if (-not $wazuhManagerIp) {
        Write-Warning "The IP address cannot be empty. Please try again."
    }
}
Write-Host "Configuration: Agent will report to manager at '$wazuhManagerIp'." -ForegroundColor Cyan
Write-Host ""


# --- 4. Install the Agent Silently ---
try {
    Write-Host "Installing the Wazuh agent from the local file. This may take a moment..." -ForegroundColor Yellow
    # Construct the arguments for msiexec
    $msiArgs = @(
        "/i", "`"$msiPath`"",   # Specify the installer path
        "/qn",                   # Quiet, no UI
        "WAZUH_MANAGER=`"$wazuhManagerIp`"" # Pass the manager IP as a property
    )

    # Start the installation process and wait for it to complete
    $installProcess = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
    
    if ($installProcess.ExitCode -ne 0) {
        throw "MSI installer exited with a non-zero status code: $($installProcess.ExitCode). Installation may have failed."
    }

    Write-Host "Wazuh agent installed successfully." -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Error "An error occurred during installation."
    Write-Error $_.Exception.Message
    exit 1
}

# --- 5. Start the Wazuh Service ---
try {
    Write-Host "Starting the Wazuh agent service..." -ForegroundColor Yellow
    Start-Service -Name "Wazuh"
    Write-Host "Service 'WazuhSvc' started." -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Warning "Could not start the Wazuh service automatically. It may already be running or the installation failed."
    Write-Warning $_.Exception.Message
}

# --- Final Message ---
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host " Wazuh Agent setup is complete!" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green


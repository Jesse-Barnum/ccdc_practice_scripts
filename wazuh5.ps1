# PowerShell Script to Interactively Install the Wazuh Agent on Windows
#
# This script will:
# 1. Ensure it is running with Administrator privileges (self-elevate).
# 2. Prompt the user for the Wazuh Manager's IP address.
# 3. Download the latest Wazuh agent MSI installer using the robust curl.exe command.
# 4. Install the agent silently, configured to connect to the provided manager IP.
# 5. Start the Wazuh service and clean up the installer file.

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
Write-Host " Wazuh Agent Interactive Installer" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host ""

# --- 2. Prompt for Wazuh Manager IP Address ---
$wazuhManagerIp = ""
while (-not $wazuhManagerIp) {
    $wazuhManagerIp = Read-Host "Please enter the Wazuh Manager IP address"
    if (-not $wazuhManagerIp) {
        Write-Warning "The IP address cannot be empty. Please try again."
    }
}
Write-Host "Configuration: Agent will report to manager at '$wazuhManagerIp'." -ForegroundColor Cyan
Write-Host ""

# --- 3. Download the Wazuh Agent using curl.exe ---
try {
    $wazuhUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-latest.msi"
    $tempPath = "$env:TEMP\wazuh-agent.msi"
    
    Write-Host "Downloading Wazuh agent from '$wazuhUrl' using curl.exe..." -ForegroundColor Yellow
    
    # Use the native curl.exe command which is more robust for downloads.
    $curlArgs = @("-L", "--silent", "--show-error", "-o", $tempPath, $wazuhUrl)
    
    # Execute curl.exe and check for errors
    $curlProcess = Start-Process -FilePath "curl.exe" -ArgumentList $curlArgs -Wait -PassThru -WindowStyle Hidden
    
    if ($curlProcess.ExitCode -ne 0) {
        throw "curl.exe failed to download the file. Exit code: $($curlProcess.ExitCode)."
    }

    if (-not (Test-Path $tempPath -PathType Leaf)) {
        throw "Download failed. The installer file was not created."
    }

    Write-Host "Download complete. Installer saved to '$tempPath'." -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Error "Failed to download the Wazuh agent. Please check your internet connection and the URL."
    Write-Error $_.Exception.Message
    exit 1
}

# --- 4. Install the Agent Silently with Verbose Logging ---
try {
    Write-Host "Installing the Wazuh agent. This may take a moment..." -ForegroundColor Yellow
    
    # Define a path for the installation log file.
    $logPath = "$env:TEMP\wazuh_install_log.txt"
    Write-Host "A detailed installation log will be saved to '$logPath'." -ForegroundColor Cyan

    $msiArgs = @(
        "/i", "`"$tempPath`"",
        "/qn",
        "WAZUH_MANAGER=`"$wazuhManagerIp`"",
        "/L*v", "`"$logPath`""  # Add verbose logging parameter
    )

    $installProcess = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
    
    if ($installProcess.ExitCode -ne 0) {
        throw "MSI installer exited with a non-zero status code: $($installProcess.ExitCode). Installation may have failed."
    }

    Write-Host "Wazuh agent installed successfully." -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Error "An error occurred during installation."
    $logPath = "$env:TEMP\wazuh_install_log.txt"
    if (Test-Path $logPath) {
        Write-Error "Please check the detailed installation log for more information: $logPath"
    }
    Write-Error $_.Exception.Message
    exit 1
}

# --- 5. Start the Wazuh Service ---
try {
    Write-Host "Starting the Wazuh agent service..." -ForegroundColor Yellow
    Start-Service -Name "Wazuh"
    Write-Host "Service 'Wazuh' started." -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Warning "Could not start the Wazuh service automatically. It may already be running or the installation failed."
    Write-Warning $_.Exception.Message
}

# --- 6. Clean Up ---
try {
    Write-Host "Cleaning up installer file..." -ForegroundColor Yellow
    Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup complete." -ForegroundColor Green
    Write-Host ""
}
catch {}

# --- Final Message ---
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host " Wazuh Agent setup is complete!" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green


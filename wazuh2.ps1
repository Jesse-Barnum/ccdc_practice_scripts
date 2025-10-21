# PowerShell Script to Interactively Install the Wazuh Agent on Windows
#
# This script will:
# 1. Ensure it is running with Administrator privileges (self-elevate).
# 2. Prompt the user for the Wazuh Manager's IP address.
# 3. Download the latest Wazuh agent MSI installer.
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

# --- 3. Download the Wazuh Agent ---
try {
    $wazuhUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-latest.msi"
    $tempPath = "$env:TEMP\wazuh-agent.msi"
    # Define a common browser User-Agent string to avoid 403 Forbidden errors.
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    
    # Force PowerShell to use TLS 1.2 for the connection. This is a common fix for download errors on some systems.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    Write-Host "Downloading Wazuh agent from '$wazuhUrl'..." -ForegroundColor Yellow
    # Add the -UserAgent parameter to the download command
    Invoke-WebRequest -Uri $wazuhUrl -OutFile $tempPath -UserAgent $userAgent
    
    Write-Host "Download complete. Installer saved to '$tempPath'." -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Error "Failed to download the Wazuh agent. Please check your internet connection and the URL."
    Write-Error $_.Exception.Message
    exit 1
}

# --- 4. Install the Agent Silently ---
try {
    Write-Host "Installing the Wazuh agent. This may take a moment..." -ForegroundColor Yellow
    # Construct the arguments for msiexec
    $msiArgs = @(
        "/i", "`"$tempPath`"",   # Specify the installer path
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


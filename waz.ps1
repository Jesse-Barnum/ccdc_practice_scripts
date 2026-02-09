# Wazuh Agent Installer for Windows (Version 4.7.5)
# Run this script as Administrator

# ---------------- CONFIGURATION ----------------

$wazuhVersion = "4.7.5"
$downloadUrl  = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.5-1.msi"
$installerPath = "C:\Temp\wazuh-agent.msi"
$logPath = "C:\Temp\wazuh-install.log"

# ---------------- INPUT ----------------

$wazuhManagerIp = Read-Host "Enter the Wazuh Manager IP Address"

if ([string]::IsNullOrWhiteSpace($wazuhManagerIp)) {
    Write-Error "No Wazuh Manager IP provided. Exiting."
    exit 1
}

# ---------------- ADMIN CHECK ----------------

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# ---------------- WORKSPACE ----------------

if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
}

# ---------------- DOWNLOAD ----------------

Write-Host "Downloading Wazuh Agent $wazuhVersion..." -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
}
catch {
    Write-Error "Failed to download Wazuh agent MSI."
    exit 1
}

# ---------------- INSTALL (NO ENROLLMENT) ----------------

Write-Host "Installing Wazuh Agent (service creation only)..." -ForegroundColor Cyan

$installArgs = "/i `"$installerPath`" /q /L*V `"$logPath`" WAZUH_MANAGER=`"$wazuhManagerIp`""

$process = Start-Process -FilePath "msiexec.exe" `
    -ArgumentList $installArgs `
    -Wait -PassThru

if ($process.ExitCode -ne 0) {
    Write-Error "MSI install failed (exit code $($process.ExitCode)). Check $logPath"
    exit 1
}

# ---------------- VERIFY SERVICE ----------------

Write-Host "Verifying Wazuh service exists..." -ForegroundColor Cyan

$service = Get-Service -Name "WazuhSvc" -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Error "Wazuh service was not created. Check MSI log: $logPath"
    exit 1
}

# ---------------- ENROLL AGENT ----------------

Write-Host "Enrolling agent with manager $wazuhManagerIp..." -ForegroundColor Cyan

$agentAuthPath = "C:\Program Files (x86)\ossec-agent\agent-auth.exe"

if (-not (Test-Path $agentAuthPath)) {
    Write-Error "agent-auth.exe not found. Installation is incomplete."
    exit 1
}

$enroll = & $agentAuthPath -m $wazuhManagerIp 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Agent enrollment failed:"
    Write-Error $enroll
    exit 1
}

Write-Host "Enrollment successful." -ForegroundColor Green

# ---------------- START SERVICE ----------------

Write-Host "Starting Wazuh service..." -ForegroundColor Cyan
Start-Service -Name "WazuhSvc"

Get-Service -Name "WazuhSvc"

Write-Host "Wazuh Agent installation and enrollment complete." -ForegroundColor Green

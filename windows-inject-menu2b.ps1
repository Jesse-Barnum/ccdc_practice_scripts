<#
.SYNOPSIS
    Standalone Windows CCDC inject menu.

.DESCRIPTION
    This file embeds the Windows injects from the uploaded injects archive:
    login banner, ClamAV configuration, and Wazuh Agent installation.
#>

[CmdletBinding()]
param(
    [int]$Inject = 0,
    [switch]$List,
    [switch]$DryRun,
    [string]$ClamAVPath = 'C:\Program Files\ClamAV',
    [string]$ClamAVVersion = '1.5.1',
    [string]$WazuhManagerIp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
    if (-not (Test-Administrator)) {
        throw 'This inject must be run from an elevated PowerShell session.'
    }
}

function Invoke-LoginBanner {
    if ($DryRun) {
        Write-Host 'DRY RUN: would set the Windows legal notice login banner.' -ForegroundColor Yellow
        return
    }

    Assert-Administrator
    $bannerText = @"
******** WARNING ********
This system is the property of a private organization and is for authorized use only. By accessing this system, users agree to comply with the company's Acceptable Use Policy.

All activities on this system may be monitored, recorded, and disclosed to authorized personnel for security purposes. There is no expectation of privacy while using this system.

Unauthorized or improper use may result in disciplinary action or legal penalties. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use.

**************************
"@

    $registryKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    Set-ItemProperty -Path $registryKey -Name 'legalnoticecaption' -Value 'WARNING'
    Set-ItemProperty -Path $registryKey -Name 'legalnoticetext' -Value $bannerText
    Write-Host 'Login banner installed successfully.' -ForegroundColor Green
}

function Invoke-ClamAVConfiguration {
    if ($DryRun) {
        Write-Host "DRY RUN: would download/install ClamAV $ClamAVVersion, configure databases under $ClamAVPath, run a sample scan, and create ClamAV_Hourly_Scan." -ForegroundColor Yellow
        return
    }

    Assert-Administrator
    $downloadRoot = Join-Path $env:TEMP 'CCDC-ClamAV'
    $msiPath = Join-Path $downloadRoot ("clamav-{0}.win.x64.msi" -f $ClamAVVersion)
    $msiUrl = "https://www.clamav.net/downloads/production/clamav-$ClamAVVersion.win.x64.msi"
    $freshclamPath = Join-Path $ClamAVPath 'freshclam.exe'
    $clamscanPath = Join-Path $ClamAVPath 'clamscan.exe'

    if (-not (Test-Path -LiteralPath $freshclamPath) -or -not (Test-Path -LiteralPath $clamscanPath)) {
        New-Item -Path $downloadRoot -ItemType Directory -Force | Out-Null
        Write-Host "Downloading ClamAV $ClamAVVersion MSI..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing -ErrorAction Stop
        } catch {
            throw "Could not download $msiUrl. Try -ClamAVVersion 1.5.4 if this older release is no longer hosted."
        }
        if (-not (Test-Path -LiteralPath $msiPath) -or (Get-Item -LiteralPath $msiPath).Length -lt 1MB) {
            throw "The downloaded ClamAV MSI is missing or unexpectedly small: $msiPath"
        }

        Write-Host 'Installing ClamAV silently...' -ForegroundColor Cyan
        $msiArguments = '/i "{0}" /qn /norestart INSTALLDIR="{1}"' -f $msiPath, $ClamAVPath
        $install = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArguments -Wait -PassThru
        if ($install.ExitCode -notin @(0, 3010)) {
            throw "ClamAV MSI installation failed with exit code $($install.ExitCode)."
        }
        if (-not (Test-Path -LiteralPath $freshclamPath)) {
            throw "ClamAV installed, but freshclam.exe was not found at $freshclamPath"
        }
    } else {
        Write-Host "ClamAV already installed at $ClamAVPath; skipping MSI installation." -ForegroundColor DarkCyan
    }

    $examples = Join-Path $ClamAVPath 'conf_examples'
    $freshclamSample = Join-Path $examples 'freshclam.conf.sample'
    $clamdSample = Join-Path $examples 'clamd.conf.sample'
    if (-not (Test-Path -LiteralPath $freshclamSample) -or -not (Test-Path -LiteralPath $clamdSample)) {
        throw "ClamAV configuration samples were not found under $examples"
    }

    $freshclamConfig = Join-Path $ClamAVPath 'freshclam.conf'
    $clamdConfig = Join-Path $ClamAVPath 'clamd.conf'
    Copy-Item -LiteralPath $freshclamSample -Destination $freshclamConfig -Force
    Copy-Item -LiteralPath $clamdSample -Destination $clamdConfig -Force

    (Get-Content -LiteralPath $freshclamConfig) -replace '^Example', '#Example' |
        Set-Content -LiteralPath $freshclamConfig
    (Get-Content -LiteralPath $clamdConfig) -replace '^Example', '#Example' |
        Set-Content -LiteralPath $clamdConfig

    $databasePath = Join-Path $ClamAVPath 'database'
    New-Item -Path $databasePath -ItemType Directory -Force | Out-Null
    $freshclamLines = @(Get-Content -LiteralPath $freshclamConfig)
    $freshclamLines = @($freshclamLines -replace '^\s*#?\s*DatabaseDirectory\s+.*$', "DatabaseDirectory $databasePath")
    if (-not ($freshclamLines -match '^\s*DatabaseDirectory\s+')) {
        $freshclamLines += "DatabaseDirectory $databasePath"
    }
    $freshclamLines | Set-Content -LiteralPath $freshclamConfig

    $clamdLines = @(Get-Content -LiteralPath $clamdConfig)
    $clamdLines = @($clamdLines -replace '^\s*#?\s*DatabaseDirectory\s+.*$', "DatabaseDirectory $databasePath")
    if (-not ($clamdLines -match '^\s*DatabaseDirectory\s+')) {
        $clamdLines += "DatabaseDirectory $databasePath"
    }
    $clamdLines | Set-Content -LiteralPath $clamdConfig

    Write-Host 'Initializing ClamAV signature databases with freshclam...' -ForegroundColor Cyan
    Push-Location -LiteralPath $ClamAVPath
    try {
        & $freshclamPath
        $freshclamExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    $databaseFiles = @('main.cvd', 'daily.cvd', 'bytecode.cvd')
    $databaseUrls = @{
        'main.cvd' = 'https://database.clamav.net/main.cvd'
        'daily.cvd' = 'https://database.clamav.net/daily.cvd'
        'bytecode.cvd' = 'https://database.clamav.net/bytecode.cvd'
    }
    $missingDatabase = @($databaseFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $databasePath $_)) })
    if ($freshclamExit -ne 0 -or $missingDatabase.Count -gt 0) {
        Write-Warning 'freshclam did not produce a complete database set; downloading official CVD files as a recovery step.'
        foreach ($databaseFile in $databaseFiles) {
            $destination = Join-Path $databasePath $databaseFile
            try {
                Invoke-WebRequest -Uri $databaseUrls[$databaseFile] -OutFile $destination -UseBasicParsing -ErrorAction Stop
            } catch {
                throw "Failed to download $databaseFile from $($databaseUrls[$databaseFile])."
            }
        }
        Push-Location -LiteralPath $ClamAVPath
        try {
            & $freshclamPath
            if ($LASTEXITCODE -ne 0) { throw 'freshclam could not validate the recovered CVD files.' }
        } finally {
            Pop-Location
        }
    }

    Write-Host 'Running a sample scan of the current directory...' -ForegroundColor Cyan
    & $clamscanPath --recursive (Get-Location).Path
    $scanExit = $LASTEXITCODE
    if ($scanExit -gt 1) {
        throw "ClamScan failed with exit code $scanExit."
    }
    if ($scanExit -eq 1) {
        Write-Warning 'ClamScan reported a detection in the sample scan. Review the output above.'
    }

    $logDirectory = Join-Path $env:ProgramData 'ClamAV'
    $logPath = Join-Path $logDirectory 'scheduled-scan.log'
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    $taskRun = '"{0}" --recursive "C:\Windows\System32" --log-file="{1}"' -f $clamscanPath, $logPath
    Write-Host 'Creating or updating the hourly ClamAV scheduled task...' -ForegroundColor Cyan
    $taskResult = & schtasks.exe /Create /TN 'ClamAV_Hourly_Scan' /TR $taskRun /SC HOURLY /MO 1 /RU SYSTEM /RL HIGHEST /F 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create ClamAV_Hourly_Scan: $($taskResult -join ' ')"
    }
    $task = Get-ScheduledTask -TaskName 'ClamAV_Hourly_Scan' -ErrorAction SilentlyContinue
    if (-not $task) {
        throw 'The ClamAV_Hourly_Scan task was not found after creation.'
    }

    Write-Host 'ClamAV installation, database initialization, sample scan, and hourly task setup completed.' -ForegroundColor Green
    Write-Host "Scheduled task: $($task.TaskName) [$($task.State)]"
}

function Invoke-WazuhAgent {
    $managerIp = if ([string]::IsNullOrWhiteSpace($WazuhManagerIp)) {
        Read-Host 'Enter the Wazuh Manager IP Address'
    } else {
        $WazuhManagerIp
    }
    if ([string]::IsNullOrWhiteSpace($managerIp)) {
        throw 'No Wazuh Manager IP was provided.'
    }

    if ($DryRun) {
        Write-Host "DRY RUN: would download and install Wazuh Agent 4.7.5 enrolled to $managerIp." -ForegroundColor Yellow
        return
    }

    Assert-Administrator
    $wazuhVersion = '4.7.5'
    $downloadUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-$wazuhVersion-1.msi"
    $tempFolder = 'C:\Temp'
    $installerPath = Join-Path $tempFolder 'wazuh-agent.msi'
    $logPath = Join-Path $tempFolder 'wazuh-install.log'

    if (-not (Test-Path -LiteralPath $tempFolder)) {
        New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
    }

    Write-Host "Downloading Wazuh Agent $wazuhVersion..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Start-BitsTransfer -Source $downloadUrl -Destination $installerPath -ErrorAction Stop
    } catch {
        Write-Host 'BITS transfer failed; falling back to Invoke-WebRequest.' -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
        } catch {
            throw 'Failed to download the Wazuh Agent MSI.'
        }
    }

    $installArgs = '/i "{0}" /q /L*V "{1}" WAZUH_MANAGER="{2}"' -f $installerPath, $logPath, $managerIp
    $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $installArgs -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "MSI installation failed with exit code $($process.ExitCode). Check $logPath"
    }

    $agentPath = $null
    $programFiles = [Environment]::GetEnvironmentVariable('ProgramFiles')
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($programFiles -and (Test-Path -LiteralPath (Join-Path $programFiles 'ossec-agent'))) {
        $agentPath = Join-Path $programFiles 'ossec-agent'
    } elseif ($programFilesX86 -and (Test-Path -LiteralPath (Join-Path $programFilesX86 'ossec-agent'))) {
        $agentPath = Join-Path $programFilesX86 'ossec-agent'
    }
    if (-not $agentPath) {
        throw 'Wazuh installation directory was not found after MSI installation.'
    }

    Start-Sleep -Seconds 2
    $service = Get-Service -Name 'WazuhSvc' -ErrorAction SilentlyContinue
    if (-not $service) {
        throw "Wazuh service was not found. Check $logPath"
    }
    if ($service.Status -ne 'Running') {
        Start-Service -Name 'WazuhSvc'
    }
    Write-Host 'Wazuh Agent is installed and running.' -ForegroundColor Green
}

$actions = @(
    [pscustomobject]@{ Id = 1; Name = 'Install Windows login banner'; Description = 'Set the registry legal notice' },
    [pscustomobject]@{ Id = 2; Name = 'Install and configure ClamAV'; Description = 'Install, initialize databases, scan, and create hourly task' },
    [pscustomobject]@{ Id = 3; Name = 'Install Wazuh Agent'; Description = 'Download, enroll, and start the Wazuh Windows agent' }
)

function Show-Menu {
    Write-Host ''
    Write-Host 'Windows CCDC Injects' -ForegroundColor Cyan
    Write-Host '====================' -ForegroundColor Cyan
    foreach ($action in $actions) {
        Write-Host ('[{0}] {1} - {2}' -f $action.Id, $action.Name, $action.Description)
    }
    Write-Host '[Q] Quit'
    Write-Host ''
}

function Invoke-SelectedInject {
    param([int]$Number)

    switch ($Number) {
        1 { Invoke-LoginBanner }
        2 { Invoke-ClamAVConfiguration }
        3 { Invoke-WazuhAgent }
        default { throw "Unknown Windows inject: $Number" }
    }
}

try {
    if ($List) {
        Show-Menu
        exit 0
    }

    $selection = $Inject
    while ($selection -eq 0) {
        Show-Menu
        $answer = Read-Host 'Select an inject number'
        if ($answer -match '^[qQ]$') { exit 0 }
        if ($answer -match '^\d+$' -and [int]$answer -ge 1 -and [int]$answer -le $actions.Count) {
            $selection = [int]$answer
        } else {
            Write-Warning 'Invalid selection.'
        }
    }

    Invoke-SelectedInject -Number $selection
} catch {
    Write-Error $_
    exit 1
}



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


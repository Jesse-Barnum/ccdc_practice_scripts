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
        Write-Host "DRY RUN: would configure ClamAV under $ClamAVPath and prepare a 30-minute scan task." -ForegroundColor Yellow
        return
    }

    Assert-Administrator
    if (-not (Test-Path -LiteralPath $ClamAVPath -PathType Container)) {
        throw "ClamAV directory not found: $ClamAVPath"
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

    Write-Host 'ClamAV configuration files created and Example directives disabled.' -ForegroundColor Green
    Write-Host 'The uploaded source contained the scheduled-task command as a comment; review and enable it if required.'
}

function Invoke-WazuhAgent {
    $managerIp = if ([string]::IsNullOrWhiteSpace($WazuhManagerIp)) {
        Read-Host 'Enter the Wazuh Manager IP Address'
    } else {
        $WazuhManagerIp
    }
    if ([string]::IsNullOrWhiteSpace($managerIp)) {

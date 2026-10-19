<#
.SYNOPSIS
    Self-installing disk space monitor that triggers GUI pop-ups at 50%, 80%, and 90% utilization.
#>

$TaskName = "CCDC_Disk_Monitor"

# 1. Self-Installation Logic (Run once to set up persistence)
if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
    # Get the exact path where this script is currently saved
    $ScriptPath =$PSCommandPath 

    if ($ScriptPath) {
        Write-Host "Scheduled task not found. Installing '$TaskName' to run every 3 minutes..." -ForegroundColor Green
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3)
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

        Register-ScheduledTask -TaskName $TaskName -Action$action -Trigger $trigger -Principal$principal | Out-Null
        Write-Host "Installation complete." -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not determine script path. Please save the script to a file before running." -ForegroundColor Yellow
    }
}

# 2. Disk Monitoring Logic
Add-Type -AssemblyName System.Windows.Forms
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3"

foreach ($disk in $disks) {
    $driveLetter =$disk.DeviceID
    $totalSpace =$disk.Size
    $freeSpace =$disk.FreeSpace

    if ($totalSpace -gt 0) {
        $usedSpace =$totalSpace - $freeSpace
        $percentUsed = [math]::Round(($usedSpace / $totalSpace) * 100, 2)

        $alertMessage = $null
        $icon = [System.Windows.Forms.MessageBoxIcon]::Information

        if ($percentUsed -ge 90) {$alertMessage = "CRITICAL: Drive $driveLetter is currently at$percentUsed% used capacity, above the 90% threshold! Immediate action is required to free up space."
            $icon = [System.Windows.Forms.MessageBoxIcon]::Error
        }
        elseif ($percentUsed -ge 80) {$alertMessage = "WARNING: Drive $driveLetter is currently at$percentUsed% used capacity, above the 80% threshold. Please consider freeing up space soon."
            $icon = [System.Windows.Forms.MessageBoxIcon]::Warning
        }
        elseif ($percentUsed -ge 50) {$alertMessage = "NOTICE: Drive $driveLetter is currently at$percentUsed% used capacity, above the 50% threshold."
            $icon = [System.Windows.Forms.MessageBoxIcon]::Information
        }

        if ($alertMessage) {$popupTitle = "Disk Space Alert ($percentUsed\%) -$driveLetter"
            [System.Windows.Forms.MessageBox]::Show($alertMessage, $popupTitle, [System.Windows.Forms.MessageBoxButtons]::OK,$icon)
        }
    }
}

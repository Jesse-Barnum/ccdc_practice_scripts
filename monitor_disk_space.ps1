<#
.SYNOPSIS
    Monitors local disk space and triggers GUI error pop-ups at 50%, 80%, and 90% utilization.
.DESCRIPTION
    Retrieves logical drive metrics using CIM instances. Uses .NET Windows 
    Forms to generate on-screen message boxes that display the specific percentage.
#>

# Load the Windows Forms assembly to enable GUI pop-ups
Add-Type -AssemblyName System.Windows.Forms

# Retrieve all local logical disks (DriveType 3 filters out network/optical drives)
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3"

foreach ($disk in $disks) {
    $driveLetter = $disk.DeviceID
    $totalSpace = $disk.Size
    $freeSpace = $disk.FreeSpace

    # Prevent division by zero on empty/uninitialized volumes
    if ($totalSpace -gt 0) {
        $usedSpace = $totalSpace - $freeSpace
        $percentUsed = [math]::Round(($usedSpace / $totalSpace) * 100, 2)

        $alertMessage = $null
        $icon = [System.Windows.Forms.MessageBoxIcon]::Information

        # Evaluate thresholds (Highest to lowest to ensure critical takes precedence)
        if ($percentUsed -ge 90) {
            $alertMessage = "CRITICAL: Drive $driveLetter is currently at $percentUsed% used capacity! Immediate action is required to free up space."
            $icon = [System.Windows.Forms.MessageBoxIcon]::Error
        }
        elseif ($percentUsed -ge 80) {
            $alertMessage = "WARNING: Drive $driveLetter is currently at $percentUsed% used capacity. Please consider freeing up space soon."
            $icon = [System.Windows.Forms.MessageBoxIcon]::Warning
        }
        elseif ($percentUsed -ge 50) {
            $alertMessage = "NOTICE: Drive $driveLetter is currently at $percentUsed% used capacity."
            $icon = [System.Windows.Forms.MessageBoxIcon]::Information
        }

        # Trigger the pop-up if a threshold was met
        if ($alertMessage) {
            $popupTitle = "Disk Space Alert ($percentUsed%) - $driveLetter"
            [System.Windows.Forms.MessageBox]::Show($alertMessage, $popupTitle, [System.Windows.Forms.MessageBoxButtons]::OK, $icon)
        }
    }
}

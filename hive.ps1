# --- 6. SCORING ENGINE PERSISTENCE ---
$EnginePath = "C:\Program Files\Engine\ScoringEngine.ps1"

# Create the Engine directory if it doesn't exist
if (-not (Test-Path "C:\Program Files\Engine")) {
    New-Item -ItemType Directory -Force -Path "C:\Program Files\Engine" | Out-Null
}

# Define the Scheduled Task
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File '$EnginePath'"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task so it automatically runs on boot for all cloned VMs
Register-ScheduledTask -TaskName "OWCAScoringEngine" -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null

# Start the engine immediately on the master box to verify it works
Start-ScheduledTask -TaskName "OWCAScoringEngine"

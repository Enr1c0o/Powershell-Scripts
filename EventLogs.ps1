function Check-EventLog {
    param ($logName, $eventID, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        $eventTime = $event.TimeCreated.ToString("MM/dd/yyyy hh:mm:ss tt")
        Write-Output "$message at: $eventTime"
    } else {
        Write-Output "$message logs were not found."
    }
}

# Check if the script is running as Administrator
$runAsAdmin = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'

if (-not $runAsAdmin) {
    # Relaunch the script with elevated privileges (Administrator)
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    Exit
}

Check-EventLog "Application" 3079 "USN Journal last deleted"
Check-EventLog "System" 104 "Event Logs last cleared"
Check-EventLog "System" 1074 "User recent PC Shutdown"
Check-EventLog "Security" 4616 "System time changed"
Check-EventLog "System" 6005 "Event Log Service started"

# Add this line to pause the script before the window closes
Read-Host -Prompt "Press Enter to exit"

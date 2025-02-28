$isAdmin = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Run as admin" -ForegroundColor Red
    return
}

function Check-EventLog {
    param ($logName, $eventID, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        $eventTime = $event.TimeCreated.ToString("MM/dd/yyyy hh:mm:ss tt")
        Write-Host "$message at: $eventTime" -ForegroundColor Magenta
    } else {
        Write-Host "$message logs were not found." -ForegroundColor Magenta
    }
}

$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$formattedBootTime = $lastBootTime.ToString("yyyy-MM-dd hh:mm tt")
Write-Host "Last PC Boot Time: $formattedBootTime" -ForegroundColor Cyan

$drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($drives) {
    Write-Host "Connected Drives:" -ForegroundColor Yellow
    foreach ($drive in $drives) {
        Write-Host "$($drive.DeviceID): $($drive.FileSystem)" -ForegroundColor Green
    }
} else {
    Write-Host "No drives found." -ForegroundColor Red
}

$prefetchKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
$prefetchValueName = "EnablePrefetcher"
try {
    $prefetchStatus = (Get-ItemProperty -Path $prefetchKeyPath -Name $prefetchValueName -ErrorAction Stop).EnablePrefetcher
    if ($prefetchStatus -gt 0) {
        Write-Host "Prefetching is enabled." -ForegroundColor Green
    } else {
        Write-Host "Prefetching is disabled." -ForegroundColor Red
    }
} catch {
    Write-Host "Unable to retrieve Prefetching setting." -ForegroundColor Red
}

$services = @(
    @{ServiceName = 'DPS';        DisplayName = 'DPS'},
    @{ServiceName = 'SysMain';    DisplayName = 'SysMain'},
    @{ServiceName = 'PcaSvc';     DisplayName = 'PcaSvc'},
    @{ServiceName = 'DusmSvc';    DisplayName = 'DusmSvc'},
    @{ServiceName = 'EventLog';   DisplayName = 'EventLog'},
    @{ServiceName = 'AppInfo';    DisplayName = 'AppInfo'},
    @{ServiceName = 'DcomLaunch'; DisplayName = 'DcomLaunch'}
)

foreach ($entry in $services) {
    $serviceQuery = sc.exe query $($entry.ServiceName) | Out-String

    if ($serviceQuery -match "STATE\s+:\s+4\s+RUNNING") {
        try {
            $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($entry.ServiceName)'" -ErrorAction Stop
            $processId = $service.ProcessId
            $state = "Running"
            
            if ($processId) {
                $process = Get-Process -Id $processId -ErrorAction Stop
                $formattedTime = $process.StartTime.ToString("MM/dd/yyyy hh:mm:ss tt")
                Write-Host "$($entry.DisplayName): " -NoNewline -ForegroundColor Green
                Write-Host "Uptime: $formattedTime  State: $state" -ForegroundColor Yellow
            } else {
                Write-Host "$($entry.DisplayName): Running (No Process Details)  State: $state" -ForegroundColor Green
            }
        } catch {
            Write-Host "$($entry.DisplayName): Running (No Process Details)  State: Running" -ForegroundColor Green
        }
    } elseif ($serviceQuery -match "STATE\s+:\s+1\s+STOPPED") {
        $state = "Stopped"
        Write-Host "$($entry.DisplayName): Not Running  State: $state" -ForegroundColor Green
    } else {
        Write-Host "$($entry.DisplayName): Service Not Found" -ForegroundColor Green
    }
}

Check-EventLog "Application" 3079 "USN Journal last deleted"
Check-EventLog "System" 104 "Event Logs last cleared"
Check-EventLog "System" 1074 "User recent PC Shutdown"
Check-EventLog "Security" 4616 "System time changed"
Check-EventLog "System" 6005 "Event Log Service started"

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = Read-Host

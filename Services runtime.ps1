$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = Read-Host
    exit
}

$services = @(
    @{ServiceName = 'DPS';        DisplayName = 'DPS'},
    @{ServiceName = 'SysMain';    DisplayName = 'Sysmain'},
    @{ServiceName = 'PcaSvc';     DisplayName = 'PcaSvc'},
    @{ServiceName = 'DusmSvc';    DisplayName = 'Dusmsvc'},
    @{ServiceName = 'EventLog';   DisplayName = 'Eventlog'},
    @{ServiceName = 'AppInfo';    DisplayName = 'Appinfo'},
    @{ServiceName = 'DcomLaunch'; DisplayName = 'DcomLaunch'}
)

foreach ($entry in $services) {
    $serviceQuery = sc.exe query $($entry.ServiceName) | Out-String

    if ($serviceQuery -match "STATE\s+:\s+4\s+RUNNING") {
        try {
            $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($entry.ServiceName)'" -ErrorAction Stop
            $processId = $service.ProcessId

            if ($processId) {
                $process = Get-Process -Id $processId -ErrorAction Stop
                $formattedTime = $process.StartTime.ToString("MM/dd/yyyy hh:mm:ss tt")
                Write-Host "$($entry.DisplayName): " -NoNewline -ForegroundColor Green
                Write-Host $formattedTime -ForegroundColor Yellow
            } else {
                Write-Host "$($entry.DisplayName): Running (No Process Details)" -ForegroundColor Green
            }
        } catch {
            Write-Host "$($entry.DisplayName): Running (No Process Details)" -ForegroundColor Green
        }
    } elseif ($serviceQuery -match "STATE\s+:\s+1\s+STOPPED") {
        Write-Host "$($entry.DisplayName): Not Running" -ForegroundColor Green
    } else {
        Write-Host "$($entry.DisplayName): Service Not Found" -ForegroundColor Green
    }
}

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = Read-Host
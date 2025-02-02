$isAdmin = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Run as admin" -ForegroundColor Red
    return
}

$lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$formattedBootTime = $lastBootTime.ToString("yyyy-MM-dd hh:mm tt")
Write-Host "Last PC Boot Time: $formattedBootTime" -ForegroundColor Cyan

$servicesToCheck = @("PcaSvc", "SysMain", "DPS", "EventLog", "DcomLaunch")
$allServicesRunning = $true
foreach ($serviceName in $servicesToCheck) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -eq $null) {
        Write-Host "$serviceName service not found." -ForegroundColor Yellow
        $allServicesRunning = $false
    } elseif ($service.Status -ne 'Running') {
        Write-Host "$serviceName is $($service.Status)" -ForegroundColor Red
        $allServicesRunning = $false
    }
}

if ($allServicesRunning) {
    Write-Host "Necessary services are running." -ForegroundColor Green
}

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

$prefetchFolder = "C:\Windows\Prefetch"
if (Test-Path $prefetchFolder) {
    try {
        $latestFile = Get-ChildItem -Path $prefetchFolder -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestFile.LastWriteTime -gt $lastBootTime) {
            Write-Host "Prefetch modified after last restart at $($latestFile.LastWriteTime.ToString("yyyy-MM-dd hh:mm tt"))" -ForegroundColor Red
        } else {
            Write-Host "Prefetch not modified after last PC restart" -ForegroundColor Green
        }
    } catch {
        Write-Host "Unable to access Prefetch folder." -ForegroundColor Red
    }
}

$usnJournalEventLog = Get-WinEvent -FilterHashtable @{LogName='Application'; ID=3079} | Where-Object { $_.TimeCreated -gt $lastBootTime }
if ($usnJournalEventLog) {
    Write-Host "USN journal cleared after restart at $($usnJournalEventLog[0].TimeCreated.ToString('yyyy-MM-dd hh:mm tt'))" -ForegroundColor Red
} else {
    Write-Host "USN journal not cleared after last PC restart" -ForegroundColor Green
}

$timeChangeEventLog = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4616} | Where-Object { $_.TimeCreated -gt $lastBootTime }
if ($timeChangeEventLog) {
    Write-Host "PC time changed at $($timeChangeEventLog[0].TimeCreated.ToString('yyyy-MM-dd hh:mm tt'))" -ForegroundColor Red
} else {
    Write-Host "PC time not changed after last PC restart" -ForegroundColor Green
}

Read-Host -Prompt "Press Enter to exit"

#If its not working inside .ps1 file then try running it in regular admin powershell

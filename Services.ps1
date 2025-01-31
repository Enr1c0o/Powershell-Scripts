$services = @("PcaSvc", "SysMain", "DPS", "EventLog", "DcomLaunch", "CDPUserSvc", "Schedule", "bam", "dam", "WSearch")
$stoppedServiceMessages = @()

foreach ($service in $services) {
    $serviceInfo = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($serviceInfo) {
        $serviceStatus = $serviceInfo.Status
        $displayName = switch ($service) {
            "Schedule" { "Task Scheduler" }
            "WSearch" { "SearchIndexer" }
            default { $service }
        }
        Write-Host "$displayName is $serviceStatus"
        if ($serviceStatus -eq "Stopped") {
            switch ($service) {
                { $_ -in @("PcaSvc", "SysMain", "DPS", "EventLog", "DcomLaunch") } {
                    $stoppedServiceMessages += "Bannable: $displayName should be necessarily running for Screensharing"
                }
                { $_ -in @("bam", "WSearch") } {
                    $stoppedServiceMessages += "NOTE: $displayName Stopping is not bannable but some people prefer to ban for it"
                }
                { $_ -in @("Schedule", "CDPUserSvc", "dam") } {
                    $stoppedServiceMessages += "$displayName Stopping is not considered bannable"
                }
            }
        }
    } else {
        Write-Host "$service not found on this system."
    }
}

if ($stoppedServiceMessages.Count -gt 0) {
    Write-Host ""
    foreach ($message in $stoppedServiceMessages) {
        if ($message -match "Bannable:|NOTE:") {
            Write-Host $message -ForegroundColor Red
        } else {
            Write-Host $message -ForegroundColor Green
        }
    }
}

Read-Host -Prompt "Press Enter to exit"
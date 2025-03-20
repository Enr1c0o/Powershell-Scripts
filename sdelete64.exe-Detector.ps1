$pathsFile = ".\paths.txt"

if (-Not (Test-Path -Path $pathsFile -PathType Leaf)) {
    Write-Host "Error: paths.txt not found!" -ForegroundColor Red
    exit
}

$filePaths = Get-Content -Path $pathsFile

if ($filePaths.Count -eq 0) {
    Write-Host "Error: paths.txt is empty!" -ForegroundColor Red
    exit
}

$targetStrings = @(
    "sdelete64.pdb",
    "sdeltemp",
    "sdelmft",
    "cleaning free space to securely delete compressed files",
    "error cleaning free space",
    "cleaning mft",
    "disk cleaned",
    "sdelete.exe",
    "sdelete64.exe",
    "secure file delete"
)

Write-Host "Scanning Sdelete strings in paths.txt`n"
Write-Host "Scanning for SDelete, it may take a while...`n" -ForegroundColor Yellow

$foundAnyMatch = $false

function Normalize-String($inputString) {
    return ($inputString -replace '\s+', '') -replace '[^a-zA-Z0-9]', '' | ForEach-Object { $_.ToLower() }
}

foreach ($filePath in $filePaths) {
    $filePath = $filePath.Trim()

    if (-Not (Test-Path -Path $filePath -PathType Leaf)) {
        Write-Host "Skipping (file not found): $filePath" -ForegroundColor Yellow
        continue
    }

    $foundInFile = $false
    $matchedStrings = @()

    try {
        $fileContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::Default) + "`n"
        $fileContent += [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8) + "`n"
        $fileContent += [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::Unicode)

        $normalizedFileContent = Normalize-String $fileContent

        foreach ($target in $targetStrings) {
            $normalizedTarget = Normalize-String $target
            if ($normalizedFileContent -match $normalizedTarget) {
                $matchedStrings += $target
            }
        }

        if ($matchedStrings.Count -gt 0) {
            Write-Host "Possibly S-Delete file: $filePath" -ForegroundColor Green
            Write-Host " → Found: $($matchedStrings -join ', ')" -ForegroundColor Cyan
            $foundInFile = $true
            $foundAnyMatch = $true
        }
    }
    catch {
        continue
    }
}

if (-Not $foundAnyMatch) {
    Write-Host "`nDid not find S-Delete" -ForegroundColor Red
}

Write-Host "`nScan completed."

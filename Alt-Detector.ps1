Write-Host "Scanning for usernames in JSON files. This may take a few minutes..." -ForegroundColor Yellow

$rootDirectory = "C:\Users"
$files = Get-ChildItem -Path $rootDirectory -Recurse -Include *.json -Force -ErrorAction SilentlyContinue
$foundValues = @()
$keysToSearch = @("Username", "user", "username", "minecraftName", "minecraftUsername")

if ($files.Count -gt 0) {
    foreach ($file in $files) {
        $fileContent = [System.IO.File]::ReadAllText($file.FullName)
        if ($fileContent -ne $null) {
            foreach ($key in $keysToSearch) {
                $matches = [regex]::Matches($fileContent, "(?i)`"$key`"\s*:\s*`"([^`"]*)`"")
                if ($matches) {
                    foreach ($match in $matches) {
                        $value = $match.Groups[1].Value
                        if ($value -notmatch '@' -and $value.Length -le 18 -and $value -notmatch '[\\\-./,]' -and $value -ne "vscode") {
                            $foundValues += @{"Value" = $value; "Path" = $file.FullName}
                        }
                    }
                }
            }
        }
    }
}

if ($foundValues.Count -gt 0) {
    $results = $foundValues | ForEach-Object {
        [PSCustomObject]@{
            Value = $_.Value
            Path  = $_.Path
        }
    }

    Write-Host ("-" * 80) -ForegroundColor Cyan
    Write-Host ("{0,-20} {1,-60}" -f "Value", "Path") -ForegroundColor Cyan
    Write-Host ("-" * 80) -ForegroundColor Cyan

    foreach ($result in $results) {
        Write-Host ("{0,-20}" -f $result.Value) -ForegroundColor Magenta -NoNewline
        Write-Host $result.Path -ForegroundColor Green
    }

    Write-Host ("-" * 80) -ForegroundColor Cyan
} else {
    Write-Host "No valid usernames found in the JSON files." -ForegroundColor Red
}
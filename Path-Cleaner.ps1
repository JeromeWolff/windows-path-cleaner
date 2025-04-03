# PowerShell Script for removing unused PATH environment variable entries for Windows

# Check if the script is running with administrator privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Fail if the script is not running with administrator privileges
if (-not (Test-Admin)) {
    Write-Warning "This script requires administrator privileges to modify the PATH environment variable."
    Write-Warning "Please run PowerShell as administrator and run the script again."
    exit
}

# Get current PATH environment variables
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

# Split PATHs into arrays
$userPaths = $userPath -split ";"
$systemPaths = $systemPath -split ";"

Write-Host "Checking user PATH for invalid entries..." -ForegroundColor Cyan
$validUserPaths = @()
$invalidUserPaths = @()

foreach ($path in $userPaths) {
    $trimmedPath = $path.Trim()
    if (-not [string]::IsNullOrEmpty($trimmedPath)) {
        if (Test-Path -Path $trimmedPath -ErrorAction SilentlyContinue) {
            $validUserPaths += $trimmedPath
        } else {
            $invalidUserPaths += $trimmedPath
        }
    }
}

Write-Host "Checking system PATH for invalid entries..." -ForegroundColor Cyan
$validSystemPaths = @()
$invalidSystemPaths = @()

foreach ($path in $systemPaths) {
    $trimmedPath = $path.Trim()
    if (-not [string]::IsNullOrEmpty($trimmedPath)) {
        if (Test-Path -Path $trimmedPath -ErrorAction SilentlyContinue) {
            $validSystemPaths += $trimmedPath
        } else {
            $invalidSystemPaths += $trimmedPath
        }
    }
}

# Show results
Write-Host "`nPath analysis results:" -ForegroundColor Green
Write-Host "---------------------------" -ForegroundColor Green

if ($invalidUserPaths.Count -gt 0) {
    Write-Host "`nInvalid entries found in the user PATH variable:" -ForegroundColor Yellow
    $invalidUserPaths | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
} else {
    Write-Host "`nNo invalid entries found in the user PATH variable." -ForegroundColor Green
}

if ($invalidSystemPaths.Count -gt 0) {
    Write-Host "`nInvalid entries found in the system PATH variable:" -ForegroundColor Yellow
    $invalidSystemPaths | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
} else {
    Write-Host "`nNo invalid entries found in the system PATH variable." -ForegroundColor Green
}

# Ask the user if they want to remove the invalid entries
if (($invalidUserPaths.Count -gt 0) -or ($invalidSystemPaths.Count -gt 0)) {
    $confirmation = Read-Host "`nWould you like to remove the invalid entries? (Y/N)"
    if ($confirmation -eq "Y" -or $confirmation -eq "y") {
        # Clean and save the user PATH variable
        if ($invalidUserPaths.Count -gt 0) {
            $newUserPath = $validUserPaths -join ";"
            [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
            Write-Host "User PATH has been cleaned." -ForegroundColor Green
        }

        # Clean and save the system PATH variable
        if ($invalidSystemPaths.Count -gt 0) {
            $newSystemPath = $validSystemPaths -join ";"
            [Environment]::SetEnvironmentVariable("PATH", $newSystemPath, "Machine")
            Write-Host "System PATH has been cleaned." -ForegroundColor Green
        }

        Write-Host "`nThe PATH environment variables have been updated successfully." -ForegroundColor Green
        Write-Host "Please restart your applications to make the changes take effect." -ForegroundColor Yellow
    } else {
        Write-Host "`nNo changes have been made." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo changes are required. All PATH entries are valid." -ForegroundColor Green
}

# Create a backup of the PATH variables
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path -Path $env:TEMP -ChildPath "PATH_Backup_$timestamp.txt"

"User PATH backup on $timestamp" | Out-File -FilePath $backupFile
"--------------------------------------" | Out-File -FilePath $backupFile -Append
$userPaths | ForEach-Object { $_ } | Out-File -FilePath $backupFile -Append
"" | Out-File -FilePath $backupFile -Append
"System-PATH-Backup on $timestamp" | Out-File -FilePath $backupFile -Append
"--------------------------------------" | Out-File -FilePath $backupFile -Append
$systemPaths | ForEach-Object { $_ } | Out-File -FilePath $backupFile -Append

Write-Host "`nBackup der originalen PATH-Variablen wurde erstellt unter:" -ForegroundColor Cyan -NoNewline
Write-Host $backupFile -ForegroundColor Cyan

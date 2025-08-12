# === CONFIGURATION ===
$SOURCE_PROFILE = "C:\Users\USERNAME_TO_MIGRATE"  # Replace with actual username
$DESTINATION_PATH = "C:\Temp\USERNAME_TO_MIGRATE"  # Local destination folder
$LOG_FILE = "C:\Logs\CopyItem_USERNAME_TO_MIGRATE.log"
$INCLUDE_DIRS = @("AppData\Local", "AppData\Roaming", "Desktop", "Documents", "Downloads")  # Key folders for browser and icons
$EXCLUDE_DIRS = @("AppData\Local\Temp", "AppData\Local\Application Data")  # Avoid junctions and bloat

# === FUNCTION TO MEASURE TIME ===
function Measure-SectionTime {
    param ($Name, $ScriptBlock)
    $start = Get-Date
    Write-Host "Starting $Name..." -ForegroundColor Cyan
    & $ScriptBlock
    $end = Get-Date
    $duration = ($end - $start).TotalSeconds
    Write-Host "Completed $Name in $duration seconds." -ForegroundColor Green
}

# === ENSURE LOG DIRECTORY EXISTS ===
Measure-SectionTime -Name "Log directory creation" -ScriptBlock {
    $logDir = Split-Path $LOG_FILE -Parent
    if (-not (Test-Path $logDir)) {
        try {
            New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
            Write-Host "Log directory created at '$logDir'." -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to create log directory '$logDir'. $_" -ForegroundColor Red
            exit 1
        }
    }
}

# === VALIDATE PATHS ===
Measure-SectionTime -Name "Path validation" -ScriptBlock {
    if (-not (Test-Path $SOURCE_PROFILE)) {
        Write-Host "ERROR: Source path '$SOURCE_PROFILE' does not exist." -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path $DESTINATION_PATH)) {
        Write-Host "WARNING: Destination path '$DESTINATION_PATH' does not exist. Attempting to create..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Path $DESTINATION_PATH -Force -ErrorAction Stop | Out-Null
            Write-Host "Created destination path." -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to create destination path '$DESTINATION_PATH'. $_" -ForegroundColor Red
            exit 1
        }
    }
}

# === COPY SPECIFIC FOLDERS ===
Measure-SectionTime -Name "Copy-Item" -ScriptBlock {
    try {
        foreach ($dir in $INCLUDE_DIRS) {
            $sourceDir = Join-Path $SOURCE_PROFILE $dir
            $destDir = Join-Path $DESTINATION_PATH $dir
            if (Test-Path $sourceDir) {
                Write-Host "Copying $sourceDir..." -ForegroundColor Cyan
                Copy-Item -Path "$sourceDir\*" -Destination $destDir -Recurse -Force -Exclude $EXCLUDE_DIRS -Verbose 4>&1 | Out-File -FilePath $LOG_FILE -Append
            }
            else {
                Write-Host "WARNING: Source folder '$sourceDir' not found. Skipping." -ForegroundColor Yellow
                Write-Output "WARNING: Source folder '$sourceDir' not found. Skipping." | Out-File -FilePath $LOG_FILE -Append
            }
        }
        Write-Host "✅ Profile copy completed successfully. Check log at '$LOG_FILE' for details." -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Copy-Item failed. $_" -ForegroundColor Red
        Write-Output "ERROR: Copy-Item failed. $_" | Out-File -FilePath $LOG_FILE -Append
        exit 1
    }
}

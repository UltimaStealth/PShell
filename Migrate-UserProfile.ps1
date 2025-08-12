# === CONFIGURATION ===
$SOURCE_PROFILE = "C:\Users\USERNAME_TO_MIGRATE"  # Replace with actual username
$DESTINATION_PATH = "C:\Temp\USERNAME_TO_MIGRATE"  # Local destination folder
$LOG_FILE = "C:\Logs\Robocopy_USERNAME_TO_MIGRATE.log"
$EXCLUDE_DIRS = @("AppData\Local\Temp", "AppData\LocalLow", "OneDrive")  # Exclude problematic folders

# === PROMPT FOR CREDENTIALS ===
Write-Host "Prompting for admin credentials..." -ForegroundColor Cyan
$credential = Get-Credential -Message "Enter admin credentials (e.g., YOURDOMAIN\adminuser or local admin)"
if (-not $credential) {
    Write-Host "ERROR: No credentials provided. Exiting." -ForegroundColor Red
    exit 1
}
$adminUser = $credential.UserName

# === ENSURE LOG DIRECTORY EXISTS ===
Write-Host "Creating log directory if it doesn't exist..." -ForegroundColor Cyan
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

# === VALIDATE PATHS ===
Write-Host "Validating paths..." -ForegroundColor Cyan
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

# === CLEAN TEMP FILES ===
Write-Host "Cleaning temp files..." -ForegroundColor Cyan
$tempPath = Join-Path $SOURCE_PROFILE "AppData\Local\Temp"
if (Test-Path $tempPath) {
    try {
        Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "WARNING: Failed to clean temp files at '$tempPath'. $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "WARNING: Temp path '$tempPath' not found. Skipping cleanup." -ForegroundColor Yellow
}

# === TAKE OWNERSHIP & GRANT ACCESS ===
Write-Host "Taking ownership and applying permissions..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "takeown" -ArgumentList "/F `"$SOURCE_PROFILE`" /R /D Y" -NoNewWindow -Wait -ErrorAction Stop | Out-Null
    Start-Process -FilePath "icacls" -ArgumentList "`"$SOURCE_PROFILE`" /grant `"$($adminUser):(F)`" /T /C" -NoNewWindow -Wait -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "ERROR: Failed to set permissions on '$SOURCE_PROFILE'. $_" -ForegroundColor Red
    exit 1
}

# === ANALYZE PROFILE SIZE ===
Write-Host "Analyzing profile size..." -ForegroundColor Cyan
try {
    $files = Get-ChildItem -Path $SOURCE_PROFILE -Recurse -Force -ErrorAction SilentlyContinue -Exclude $EXCLUDE_DIRS
    $totalFiles = $files.Count
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    Write-Host "Total files: $totalFiles, Total size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: Failed to analyze profile size. $_" -ForegroundColor Red
    exit 1
}

# === START ROBOCOPY ===
Write-Host "Starting profile copy..." -ForegroundColor Green
try {
    $robocopyArgs = "`"$SOURCE_PROFILE`" `"$DESTINATION_PATH`" /E /COPY:DAT /R:3 /W:5 /V /LOG+:`"$LOG_FILE`" /XD $($EXCLUDE_DIRS -join ' ')"
    $robocopyProcess = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -PassThru -Wait
}
catch {
    Write-Host "ERROR: Robocopy failed to start. $_" -ForegroundColor Red
    exit 1
}

# === CHECK ROBOCOPY EXIT CODE ===
$exitCode = $robocopyProcess.ExitCode
if ($exitCode -le 7) {
    Write-Host "✅ Profile copy completed successfully. Check log at '$LOG_FILE' for details." -ForegroundColor Green
}
else {
    Write-Host "ERROR: Robocopy failed with exit code $exitCode. Check log at '$LOG_FILE' for details." -ForegroundColor Red
    exit 1
}

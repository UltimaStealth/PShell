# === CONFIGURATION ===
$SOURCE_PROFILE = "C:\Users\USERNAME_TO_MIGRATE"  # Replace with actual username
$DESTINATION_PATH = "\\FILESERVER\SHARE\USERNAME_TO_MIGRATE"  # Replace with actual share
$DOMAIN_ADMIN = "YOURDOMAIN\ADMINACCOUNT"  # Replace with actual domain\admin
$LOG_FILE = "C:\Logs\Robocopy_USERNAME_TO_MIGRATE.log"
$EXCLUDE_DIRS = @("AppData\Local\Temp", "AppData\LocalLow", "OneDrive")  # Exclude problematic folders

# === ENSURE LOG DIRECTORY EXISTS ===
$logDir = Split-Path $LOG_FILE -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
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
    } catch {
        Write-Host "ERROR: Failed to create destination path '$DESTINATION_PATH'. $_" -ForegroundColor Red
        exit 1
    }
}

# === CHECK NETWORK SHARE ACCESS ===
Write-Host "Checking network share access..." -ForegroundColor Cyan
try {
    Test-Path $DESTINATION_PATH -ErrorAction Stop | Out-Null
} catch {
    Write-Host "ERROR: Cannot access network share '$DESTINATION_PATH'. Ensure it’s mounted and credentials are valid." -ForegroundColor Red
    Write-Host "Try mapping the share manually: net use \\FILESERVER\SHARE /user:YOURDOMAIN\ADMINACCOUNT password" -ForegroundColor Yellow
    exit 1
}

# === CLEAN TEMP FILES ===
Write-Host "Cleaning temp files..." -ForegroundColor Cyan
$tempPath = Join-Path $SOURCE_PROFILE "AppData\Local\Temp"
if (Test-Path $tempPath) {
    Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "WARNING: Temp path '$tempPath' not found. Skipping cleanup." -ForegroundColor Yellow
}

# === TAKE OWNERSHIP & GRANT ACCESS ===
Write-Host "Taking ownership and applying permissions..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "takeown" -ArgumentList "/F `"$SOURCE_PROFILE`" /R /D Y" -NoNewWindow -Wait -ErrorAction Stop | Out-Null
    Start-Process -FilePath "icacls" -ArgumentList "`"$SOURCE_PROFILE`" /grant `"$DOMAIN_ADMIN:(F)`" /T /C" -NoNewWindow -Wait -ErrorAction Stop | Out-Null
} catch {
    Write-Host "ERROR: Failed to set permissions on '$SOURCE_PROFILE'. $_" -ForegroundColor Red
    exit 1
}

# === ANALYZE PROFILE SIZE ===
Write-Host "Analyzing profile size..." -ForegroundColor Cyan
$files = Get-ChildItem -Path $SOURCE_PROFILE -Recurse -Force -ErrorAction SilentlyContinue -Exclude $EXCLUDE_DIRS
$totalFiles = $files.Count
$totalSize = ($files | Measure-Object -Property Length -Sum).Sum
Write-Host "Total files: $totalFiles, Total size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Cyan

# === START ROBOCOPY ===
Write-Host "Starting profile copy..." -ForegroundColor Green
$robocopyArgs = "`"$SOURCE_PROFILE`" `"$DESTINATION_PATH`" /E /COPY:DAT /R:3 /W:5 /V /LOG+:`"$LOG_FILE`" /XD $($EXCLUDE_DIRS -join ' ')"
$robocopyProcess = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -NoNewWindow -PassThru

# === MONITOR PROGRESS ===
$startTime = Get-Date
while (!$robocopyProcess.HasExited) {
    $copiedFiles = Get-ChildItem -Path $DESTINATION_PATH -Recurse -Force -ErrorAction SilentlyContinue
    $copiedCount = $copiedFiles.Count
    $percent = if ($totalFiles -gt 0) { [math]::Round(($copiedCount / $totalFiles) * 100, 2) } else { 0 }
    $elapsed = (Get-Date) - $startTime
    $estimatedTotalTime = if ($percent -gt 0) { $elapsed.TotalSeconds / ($percent / 100) } else { 0 }
    $remaining = [TimeSpan]::FromSeconds($estimatedTotalTime - $elapsed.TotalSeconds)
    Write-Progress -Activity "Copying Profile" `
                   -Status "$percent% complete. Time remaining: $($remaining.ToString('hh\:mm\:ss'))" `
                   -PercentComplete $percent
    Start-Sleep -Seconds 5
}

# === CHECK ROBOCOPY EXIT CODE ===
$exitCode = $robocopyProcess.ExitCode
if ($exitCode -le 7) {
    Write-Host "✅ Profile copy completed successfully. Check log at '$LOG_FILE' for details." -ForegroundColor Green
} else {
    Write-Host "ERROR: Robocopy failed with exit code $exitCode. Check log at '$LOG_FILE' for details." -ForegroundColor Red
    exit 1
}

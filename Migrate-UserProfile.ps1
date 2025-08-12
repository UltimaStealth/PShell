# === CONFIGURATION ===
$SOURCE_PROFILE = "C:\Users\USERNAME_TO_MIGRATE"
$DESTINATION_PATH = "\\FILESERVER\SHARE\USERNAME_TO_MIGRATE"
$DOMAIN_ADMIN = "YOURDOMAIN\ADMINACCOUNT"
$LOG_FILE = "C:\Logs\Robocopy_USERNAME_TO_MIGRATE.log"

# === CLEAN TEMP FILES ===
Write-Host "Cleaning temp files..." -ForegroundColor Cyan
$tempPath = Join-Path $SOURCE_PROFILE "AppData\Local\Temp"
Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue

# === TAKE OWNERSHIP & GRANT ACCESS ===
Write-Host "Taking ownership and applying permissions..." -ForegroundColor Yellow
takeown /F "$SOURCE_PROFILE" /R /D Y | Out-Null
icacls "$SOURCE_PROFILE" /grant "$DOMAIN_ADMIN:(F)" /T /C | Out-Null

# === ANALYZE PROFILE SIZE ===
Write-Host "Analyzing profile size..." -ForegroundColor Cyan
$files = Get-ChildItem -Path $SOURCE_PROFILE -Recurse -Force -ErrorAction SilentlyContinue
$totalFiles = $files.Count
$totalSize = ($files | Measure-Object -Property Length -Sum).Sum

# === START ROBOCOPY ===
Write-Host "Starting profile copy..." -ForegroundColor Green
$robocopyArgs = "`"$SOURCE_PROFILE`" `"$DESTINATION_PATH`" /MIR /COPYALL /R:3 /W:5 /NFL /NDL /NP /LOG:`"$LOG_FILE`""
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
                   -Status "$percent% complete. Time remaining: $($remaining.ToString("hh\:mm\:ss"))" `
                   -PercentComplete $percent
    Start-Sleep -Seconds 5
}

Write-Host "✅ Profile copy completed." -ForegroundColor Green

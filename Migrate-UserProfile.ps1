# === CONFIGURATION ===
$SOURCE_PROFILE = "C:\Users\USERNAME_TO_MIGRATE"  # Replace with actual username
$DESTINATION_PATH = "\\FILESERVER\SHARE\USERNAME_TO_MIGRATE"  # Replace with actual share
$LOG_FILE = "C:\Logs\Robocopy_USERNAME_TO_MIGRATE.log"
$EXCLUDE_DIRS = @("AppData\Local\Temp", "AppData\LocalLow", "OneDrive")  # Exclude problematic folders

# === PROMPT FOR CREDENTIALS ===
Write-Host "Prompting for domain admin credentials..." -ForegroundColor Cyan
$credential = Get-Credential -Message "Enter domain admin credentials (e.g., YOURDOMAIN\adminuser)"
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
    } catch {
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
        New-Item -ItemType Directory -Path $DESTINATION_PATH -Force -Credential $credential -ErrorAction Stop | Out-Null
        Write-Host "Created destination path." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to create destination path '$DESTINATION_PATH'. $_" -ForegroundColor Red
        exit 1
    }
}

# === CHECK NETWORK SHARE ACCESS ===
Write-Host "Checking network share access..." -ForegroundColor Cyan
try {
    Test-Path $DESTINATION_PATH -Credential $credential -ErrorAction Stop | Out-Null
} catch {
    Write-Host "ERROR: Cannot access network share '$DESTINATION_PATH'. Ensure it’s mounted and credentials are valid." -ForegroundColor Red
    Write-Host "Try mapping the share manually: net use \\FILESERVER\SHARE /user:$adminUser [password]" -ForegroundColor Yellow
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
    Start

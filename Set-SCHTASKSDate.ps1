#Requires the task to be created on each machine that you are updating
#Requires that the tasks name is the same on each machine that you are updating
$Computers = Get-Content "C:\Temp\PShell\Scripts\Set-ScheduledTask\Servers.txt"
@(foreach ($Computer in $Computers) {
    Write-Host -ForegroundColor Green "Processing $Computer ..."
    .\schtasks.exe /S $Computer /TN "Restart" /CHANGE /SD "03/15/2022"
    $ErrorActionPreference = 'SilentlyContinue'
    $TaskText = .\schtasks.exe /s $Computer /TN "Restart" /CHANGE /SD "03/15/2022"
    if (-not $?) {
        Write-Warning -Message "$Computer`: schtasks.exe failed"
        continue
    }
    $ErrorActionPreference = 'Continue'
    $TaskText = $TaskText -join "`n"
}) | Export-Csv -NoTypeInformation -Path "C:\temp\APerry\PShell\Scripts\Set-ScheduledTask\Results.txt"

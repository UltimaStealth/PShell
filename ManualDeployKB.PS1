#
Start-Transcript -OutputDirectory "C:\Temp\Transcript.txt"
#
$RootHotfixPath = 'Patches\'
#
$Hotfixes = @('1-KB5003173-win10_2004-.0-64_4e3b4345ad6e3bf44183d6f25879a0c5ca1b7ef9','2-KB5004945-win10_2004-.0-64_4e3b4345ad6e3bf44183d6f25879a0c5ca1b7ef9')
$Servers = Get-Content 'C:\Temp\SCCM\list-win10.txt'
#
foreach ($Hotfix in $Hotfixes){
    $HotfixPath = "$RootHotfixPath$Hotfix"
    foreach ($Server in $Servers){
        if (Test-Path "\\$Server\c$\Temp"){
            Write-Host "Processing $Server..."
            # Copy update package to local folder on server
            Copy-Item $Hotfixpath "\\$Server\c$\Temp"
            # Run command as SYSTEM via PsExec (-s switch)
            & C:\Windows\PsExec -s \\$Server wusa C:\Temp\$Hotfix /quiet /norestart
            write-host "& C:\Windows\PsExec -s \\$Server wusa C:\Temp\$Hotfix /quiet /norestart"
            if ($LastExitCode -eq 3010) {
                $ConfirmReboot = $False
            } else {
                $ConfirmReboot = $True
            }
            # Delete local copy of update package
            Remove-Item "\\$Server\c$\Temp\$Hotfix"
            Write-Host "Restarting $Server..."
            Restart-Computer -ComputerName $Server -Force -Confirm:$ConfirmReboot
            Write-Host
        } else {
            Write-Host "Folder C:\Temp does not exist on the target server"
        }
    }
}

#Start-Transcript -Path "C:\Temp\PShell\Transcript.txt"
#foreach ($port in 2500..3000) {If (($a=Test-NetConnection TDRX-VEEAM01 -Port $port -WarningAction SilentlyContinue).tcpTestSucceeded -eq $true){ "TCP port $port is open!"}}
#Stop-Transcript
#
$ComputerName = "witt-VEEAM01"
445..445 | ForEach-Object { $port = $_; [PSCustomObject]@{ ComputerName = $ComputerName; Port = $port; '
Open = (Test-NetConnection $ComputerName -Port $port -WarningAction SilentlyContinue).tcpTestSucceeded } } | Export-csv -Path C:\Temp\PShell\PortReport.csv

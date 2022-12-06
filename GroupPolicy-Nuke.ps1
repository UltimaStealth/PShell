$PCList=Get-Clipboard
$Jobs = @()
$JobScriptBlock = {
    Param(
        $ComputerName
    )
    $CommandScriptBlock = {
        Remove-Item "C:\Windows\System32\GroupPolicy\Machine\Registry.pol"
        Remove-Item -Path "C:\Windows\System32\GroupPolicy\User\Registry.pol"
        klist -li 0x3e7 purge
        GPUpdate /Force
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $CommandScriptBlock
}
ForEach ($PC in $PCList) {
    $Jobs += Start-Job -ScriptBlock $JobScriptBlock -ArgumentList $PC
}

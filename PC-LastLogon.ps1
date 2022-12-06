# Offline - Last Online
$PCList= Get-Clipboard
    ForEach ($PC in $PCList) {
Get-ADComputer -identity $PC -Properties * | FT Name, Enabled, LastLogonDate -Autosize
    }
#

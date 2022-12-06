# This queries the remote computer ( $ServerName) to see all currently logged in users. (using the quser command).
# Then, it grabs the ID of the user you specify from the $UserName variable and puts the ID into another variable ( $sessionID).
# Lastly, it tells the remote computer to log off the user using the stored $sessionID variable.
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$PromptUser = {
        [Microsoft.VisualBasic.Interaction]::InputBox(
        ($args -join ' '),     #Prompt message
        "Log Off Remote User" #Title Bar
    )
}
$Username = &$PromptUser "Type username you wish to sign off"
$ServerName = &$PromptUser "Type target server name"
$sessionID = ((quser /server:$ServerName | Where-Object { $_ -match $UserName }) -split ' +')[2]
###logs off user
Logoff $sessionID /server:$ServerName

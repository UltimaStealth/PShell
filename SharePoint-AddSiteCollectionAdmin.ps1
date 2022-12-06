$webApp = Get-SPWebApplication "http://hndc-spweb01"
Foreach($site in $webApp.Sites)
 {
   New-SPUser -UserAlias "DOMAIN\New User" -DisplayName "New User" -Web $site.URL
   $usr = Get-SPUser "DOMAIN\New User" -Web $site.URL
   $usr.IsSiteAdmin = $true
   $usr.Update()
 }

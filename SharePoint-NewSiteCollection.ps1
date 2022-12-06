$SPTemplate = Get-SPWebTemplate "sts#0"
new-spsite -url "http://Name of Sharepoint Server/sites/SiteName1" -ContentDatabase "SPDB_NameofDatabase" -OwnerAlias "DOMAIN\SharePointSVCAcct" -Template $SPTemplate
#Can have multiple added below 

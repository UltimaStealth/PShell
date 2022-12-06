Test-SPContentDatabase -name "Sites_SITE1" -WebApplication http://SharePointServerName/ | ? { $_.Category -eq "MissingFeature" } > c:\Andy\MissingSiteFeature.txt
Test-SPContentDatabase -name "Sites_SITE2" -WebApplication http://SharePointServerName/ | ? { $_.Category -eq "MissingFeature" } >> c:\Andy\MissingSiteFeature.txt
#Can add more sites as above

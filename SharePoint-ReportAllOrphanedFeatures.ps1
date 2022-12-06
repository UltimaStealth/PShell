$results = @()
foreach($site in Get-SPSite -limit all) {
    #write-host "Site : " $site.URL
    foreach ($feature in $site.features) {
        $obj = New-Object PSObject    
       if ($feature.definition -eq $null) {
            $obj | Add-Member NoteProperty "Site/Web Title"($site.Title)
            $obj | Add-Member NoteProperty "Site/Web URL"($site.URL)
            $obj | Add-Member NoteProperty "Feature ID"($feature.DefinitionId)
            $results += $obj
        }
    }
    $webs = $site | get-spweb -limit all
    foreach ($web in $webs) {     
        foreach ($feature in $web.features) {
            $obj = New-Object PSObject
            if ($feature.definition -eq $null) {
                $obj | Add-Member NoteProperty "Site/Web Title"($web.Title)
                $obj | Add-Member NoteProperty "Site/Web URL"($web.URL)
                $obj | Add-Member NoteProperty "Feature ID"($feature.DefinitionId)
                $results += $obj
            }
        }
        $web.dispose()
    }
    $site.dispose()
}
$results | Export-Csv "C:\Temp\MissingFeatures.txt" -notype

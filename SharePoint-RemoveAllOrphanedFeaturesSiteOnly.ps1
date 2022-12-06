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
            $site.features.remove($feature.DefinitionId,$true)
        }
    }
}
$results | Export-Csv "C:\Temp\MissingFeatures.txt" -notype

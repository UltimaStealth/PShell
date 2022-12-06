$List1 = Get-Content -Path C:\Temp\PShell\List\List1.txt
$List2 = Get-Content -Path C:\Temp\PShell\List\List2.txt
(Compare-Object -ReferenceObject $List1 $List2|
    ForEach-Object {
        if ($_.SideIndicator -eq '=>') {
            $_.SideIndicator = 'Not in List2'
        } elseif ($_.SideIndicator -eq '<=')  {
            $_.SideIndicator = 'Not in List1'
        }
        $_
    })|export-csv -Path C:\Temp\PShell\List\ListReport.csv
#Compare-Object $List1 $List2  | Select-Object -ExpandProperty InputObject SideIndicator
#List1(Reference)=Reference Objects
#List2(Comparison)=Comparison Objects
#-IncludeEqual: IncludeEqual displays the matches between the reference and difference objects.
#-ReferenceObject: Specifies an array of objects used as a reference for comparison.
#-DifferenceObject: Specifies the objects that are compared to the reference objects.

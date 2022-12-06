#Installs MSU Updates in a folder
$dir = (Get-Item -Path ".\" -Verbose).FullName
 Foreach($item in (ls $dir *.msu -Name))
 {
    echo $item
    $item = $dir + "\" + $item
    wusa $item /quiet /norestart | Out-Null
 }

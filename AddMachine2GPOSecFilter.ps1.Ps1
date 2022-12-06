#To add:
# - Powershell Min version
# - Ad tools detection?
# - Instructions how to undo/remove computer/computers
# - Ability to run interactively, instead of copy/pasta
#Variables
$Domain = "NAME OF DOMAIN"
$GPO_Name = {6C48A5D2-81CB-4524-BB2D-F181E0B6222A}
$Computers_To_Add = Get-Content -Path "C:\Temp\MachinesNeedService.txt"
$Computer = "Example_PC4"
#
#Business
$GPO = Get-GPO -guid "{6C48A5D2-81CB-4524-BB2D-F181E0B6222A}"
#
#Add single PC to GPO Security Filter
#$GPO | Set-GPPermissions -domain $Domain -PermissionLevel gpoapply  -TargetType computer -TargetName $Computer_To_Add
#
#Add multiple computers to GPO Security Filter
foreach ($Computer in $Computers_To_Add) { $GPO | Set-GPPermissions -DomainName $Domain -PermissionLevel GpoApply  -TargetType Computer -TargetName $Computer}

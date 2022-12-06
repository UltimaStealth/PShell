# Script that will parse through a device export csv obtained from Intune and tag it will useful information out of AD like Division and the primary 
# user’s email. (Requires a csv file.) Cmdlet should be run as ".\Match-DevicePrimaryUPNwithAD.ps1 -CSVPath 'devices.csv' -AllColumns"

<#
    Script name   : Match-DevicePrimaryUPNwithAD.ps1
    Created on    : 2021-09-21
    Author        : UltimaStealth
    Purpose       : Uses given csv file of Intune iOS devices and matches the primary user UPN with a AD account.                    

    Prerequisites : Active Directory module.
                    CSV exported from endpoint.microsoft.com -> Devices iOS/iPadOS -> Export -> 'Only include selected columns in the exported file' -> Yes.
                    For more device details export the report using 'Include all inventory data in the exported file' and use the -AllColumns switch 
                    when running this script.
    
    Parameters    : [Mandatory]
                    CSVPath
                        Full path to input csv file
                            Example: C:\Temp\devices.csv

                    [Optional]
                    Division
                        Filters results to specified Division.
                            Example: -Division AERO          
                    OutputPath
                        Full path to output file destination directory.
                            Example: -Outputpath 'C:\Temp'
                    AllColumns
                        Use this switch when exporting the report with all columns to include the additional fields in the output csv.                            
                        
    Examples      : .\Match-DevicePrimaryUPNwithAD.ps1 -CSVPath 'c:\temp\2021-09-22_PCCIntuneiOSDevices.csv'
                        Uses c:\temp\2021-09-22_PCCIntuneiOSDevices.csv to match primary device user UPN with an AD account and exports the results to c:\temp\2021-09-22_PCCIntuneiOSDevices_Results.csv

                    .\Match-DevicePrimaryUPNwithAD.ps1 -CSVPath 'c:\temp\2021-09-22_PCCIntuneiOSDevices.csv' -Division AERO
                        Same as above but filters the results down to users/devices in the AERO division.

                    .\Match-DevicePrimaryUPNwithAD.ps1 -CSVPath 'c:\temp\2021-09-22_PCCIntuneiOSDevices.csv' -AllColumns
                        Same as above but includes additional columns from the more detailed export.

                    .\Match-DevicePrimaryUPNwithAD.ps1 -CSVPath 'c:\temp\2021-09-22_PCCIntuneiOSDevices.csv' -OutputPath 'c:\Users\y_CRyan.AERA\Desktop'
                        Same as the first example but exports the results to c:\Users\y_CRyan.AERA\Desktop

    Change log    : 2021-09-21 - Initial release.
                    2021-09-24 - Added -Division parameter to filter results. Fixed -OutputPath to actually output to the specified path. 
                                 Added 'Days Since Last Check-in'.
#>

[cmdletbinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$CSVPath,
    [ValidateSet('AD-OU1','AD-OU2','ETC..' ')]
    [string]$Division,
    [ValidateScript({Test-Path $_})]
    [string]$OutputPath,
    [switch]$AllColumns
)

$today = Get-Date
$devices = Import-Csv $CSVPath -Encoding utf8

$results = @()
$devicesCount = ($devices | Measure-Object).Count
$i = 1
foreach ($device in $devices) {
    if ($devicesCount -gt 1) {
        $percentComplete = [math]::Round($i/$devicesCount * 100,2)
        Write-Progress -Activity "Getting computer AD info for $($device.'Device name') | $($device.'Primary user UPN')" -Status "Devices Processed: $i of $devicesCount" -PercentComplete $percentComplete -CurrentOperation "$($percentComplete)% Complete"
    }

    $site = 'N/A'
    $tempAD = $false
    $tempAD = try{Get-ADUser -Filter "UserPrincipalName -eq `"$($device.'Primary user UPN')`"" -Properties LastLogonDate,Office,whenCreated} catch {}
    if($tempAD) {
        $userDNSplit = $tempAD.DistinguishedName.Split(',')
        $userDNsplitCount = ($userDNSplit | Measure-Object).Count
        $site = $userDNsplit[$userDNsplitCount-5].SubString(3,$userDNsplit[$userDNsplitCount-5].Length-3)

        if ($AllColumns) {
            $results += [PSCustomObject] @{
                'AD Division' = if (@('KALI','PWFR') -contains $site) {'FAST'} else {$userDNsplit[$userDNsplitCount-3].SubString(3,$userDNsplit[$userDNsplitCount-3].Length-3)}
                'AD BusUnit' = $userDNsplit[$userDNsplitCount-4].SubString(3,$userDNsplit[$userDNsplitCount-4].Length-3)
                'AD Site' = $site
                'AD Office' = $tempAD.Office
                'AD LastLogonDate' = $tempAD.LastLogonDate
                'AD Enabled' = $tempAD.Enabled
                'Device Name' = [string]"$($device.'Device name')"
                'Enrollment Date' = [datetime]$device.'Enrollment date'
                'Last Check-in' = [datetime]$device.'Last Check-in'
                'Days Since Last Check-in' = if ($device.'Last Check-in') {(New-TimeSpan $device.'Last Check-in' $today).Days} else {'N/A'}
                OS = $device.OS
                'OS version' = $device.'OS version'
                Manufacturer = $device.Manufacturer
                Model = $device.Model
                'Primary User UPN' = $device.'Primary user UPN'
                'Primary User Email Address' = $device.'Primary user email address'
                Compliance = $device.Compliance
                Ownership = $device.Ownership
                'Device State' = $device.'Device state'
                'Intune Registered' = $device.'Intune registered'
                Supervised = $device.Supervised
                Encrypted = $device.Encrypted
                'AD WhenCreated' = $tempAD.whenCreated
                'AD DistinguishedName' = $tempAD.DistinguishedName
            }
        }
        else {   
            $results += [PSCustomObject] @{
                'AD Division' = if (@('KALI','PWFR') -contains $site) {'FAST'} else {$userDNsplit[$userDNsplitCount-3].SubString(3,$userDNsplit[$userDNsplitCount-3].Length-3)}
                'AD BusUnit' = $userDNsplit[$userDNsplitCount-4].SubString(3,$userDNsplit[$userDNsplitCount-4].Length-3)
                'AD Site' = $site
                'AD Office' = $tempAD.Office
                'AD LastLogonDate' = $tempAD.LastLogonDate
                'AD Enabled' = $tempAD.Enabled
                'Device Name' = [string]"$($device.'Device name')"                
                'Last Check-in' = [datetime]$device.'Last check-in'
                'Days Since Last Check-in' = if ($device.'Last Check-in') {(New-TimeSpan $device.'Last Check-in' $today).Days} else {'N/A'}
                OS = $device.OS
                'OS version' = $device.'OS version'
                Manufacturer = $device.Manufacturer                
                'Primary User UPN' = $device.'Primary user UPN'                
                Compliance = $device.Compliance
                Ownership = $device.Ownership
                'AD WhenCreated' = $tempAD.whenCreated
                'AD DistinguishedName' = $tempAD.DistinguishedName
            }
        }            
    }

    else {
        if ($AllColumns) {
            $results += [PSCustomObject] @{
                'AD Division' = 'Not Found in AD'
                'AD BusUnit' = 'N/A'
                'AD Site' = 'N/A'
                'AD Office' = 'N/A'
                'AD LastLogonDate' = 'N/A'
                'AD Enabled' = 'N/A'
                'Device Name' = $device.'Device name'
                'Enrollment Date' = $device.'Enrollment date'
                'Last Check-in' = $device.'Last check-in'
                'Days Since Last Check-in' = if ($device.'Last Check-in') {(New-TimeSpan $device.'Last Check-in' $today).Days} else {'N/A'}
                OS = $device.OS
                'OS version' = $device.'OS version'
                Manufacturer = $device.Manufacturer
                Model = $device.Model
                'Primary User UPN' = $device.'Primary user UPN'
                'Primary User Email Address' = $device.'Primary user email address'
                Compliance = $device.Compliance
                Ownership = $device.Ownership
                'Device State' = $device.'Device state'
                'Intune Registered' = $device.'Intune registered'
                Supervised = $device.Supervised
                Encrypted = $device.Encrypted
                'AD WhenCreated' = 'N/A'
                'AD DistinguishedName' = 'N/A'
            }
        }
        else {
            $results += [PSCustomObject] @{
                'AD Division' = 'Not Found in AD'
                'AD BusUnit' = 'N/A'
                'AD Site' = 'N/A'
                'AD Office' = 'N/A'
                'AD LastLogonDate' = 'N/A'
                'AD Enabled' = 'N/A'
                'Device Name' = $device.'Device name'                
                'Last Check-in' = $device.'Last check-in'
                'Days Since Last Check-in' = if ($device.'Last Check-in') {(New-TimeSpan $device.'Last Check-in' $today).Days} else {'N/A'}
                OS = $device.OS
                'OS version' = $device.'OS version'                                
                'Primary User UPN' = $device.'Primary user UPN'                
                Compliance = $device.Compliance
                Ownership = $device.Ownership                                                
                'AD WhenCreated' = 'N/A'
                'AD DistinguishedName' = 'N/A'
            }
        }
    }
    $i++
}

if ($Division) {
    $results = $results | Where-Object {$_.'AD Division' -eq $Division -or $_.'AD Division' -eq 'Not Found in AD'}
}

if ($OutputPath) {
    if ($OutputPath.SubString($OutputPath.Length-1,1) -eq '\') {
        $OutputPath = $OutputPath.Substring(0,$OutputPath.Length-1)
    }

    $results | Export-Csv "$($OutputPath)\$($csvPath.Substring($csvPath.LastIndexOf('\')+1,$csvPath.Length-$csvPath.LastIndexOf('\')-1).Replace('.csv','_Results.csv'))" -NoTypeInformation -Encoding utf8
}
else {
    $results | Export-Csv "$($CSVPath.Replace('.csv','_Results.csv'))" -NoTypeInformation -Encoding utf8
}

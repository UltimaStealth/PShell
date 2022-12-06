<#
.SYNOPSIS
    Clears all Packages from the Configuration Manager Client Cache.
.DESCRIPTION
    Clears all Packages from the Configuration Manager Client Cache.
.EXAMPLE
    .\clear-ClientCache.ps1
.NOTES   
    Version: 1.0
    Change history
        08.26.2021 - first release
        Requirements: installed ConfigMgr Agent on local machine
#>
[CmdletBinding()]
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements()
foreach ($Element in $CacheElements)
    {
        Write-Verbose "Deleting CacheElement with PackageID $($Element.ContentID)"
        Write-Verbose "in folder location $($Element.Location)"
        $Cache.DeleteCacheElement($Element.CacheElementID)
    }

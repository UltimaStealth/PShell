Get-GpoNetFirewall.ps1
# Get all GPOs containing Firewall Rules
$OU1 = "OU=1,DC=DomainName,DC=com"
$OU2 = "OU=2,DC=DomainName,DC=com"
$Both = $OU1, $OU2
Function ConvertIdentityString
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IdentityString
    )
    If ( $IdentityString -eq 'Any' )
    {
        $IdentityString
    }
    Else
    {
        (ConvertFrom-SddlString -Sddl $IdentityString).DiscretionaryAcl.Split(':')[0]
    }
}
$LinkedGpos = $Both | ForEach-Object {
    (Get-ADOrganizationalUnit -Filter * -SearchBase $_).LinkedGroupPolicyObjects
} | Select-Object -Unique
$LinkedGpos | ForEach-Object {
    $GpoLdapPath = $_
    $GpoGuid = [RegEx]::Match($GpoLdapPath, '([0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})').Value
    $Gpo = Get-GPO -Guid $GpoGuid
    $PolicyStore = "$($Gpo.Domainname)\$($Gpo.DisplayName)"
    $FirewallRules = Get-NetFirewallRule -PolicyStore $PolicyStore
    If ( $FirewallRules.Count )
    {
        $PortFilters = Get-NetFirewallPortFilter -PolicyStore $PolicyStore
        $ApplicationFilters = Get-NetFirewallApplicationFilter -PolicyStore $PolicyStore
        $InterfaceFilters = Get-NetFirewallInterfaceFilter -PolicyStore $PolicyStore
        $InterfaceTypeFilters = Get-NetFirewallInterfaceTypeFilter -PolicyStore $PolicyStore
        $SecurityFilters = Get-NetFirewallSecurityFilter -PolicyStore $PolicyStore
        for ( $idx = 0; $idx -lt $FirewallRules.Count; $idx++ )
        {
            $FirewallRule = $FirewallRules[$idx]
            $PortFilter = $PortFilters[$idx]
            $ApplicationFilter = $ApplicationFilters[$idx]
            $InterfaceFilter = $InterfaceFilters[$idx]
            $InterfaceTypeFilter = $InterfaceTypeFilters[$idx]
            $SecurityFilter = $SecurityFilters[$idx]
            [PSCustomObject]@{
                GpoId = $GpoGuid
                GpoName = $Gpo.DisplayName
                Id = $FirewallRule.Name
                Name = $FirewallRule.DisplayName
                Description = $FirewallRule.Description
                Direction = $FirewallRule.Direction
                Enabled = $FirewallRule.Enabled
                Action = $FirewallRule.Action
                EdgeTraversalPolicy = $FirewallRule.EdgeTraversalPolicy
                Protocol = $PortFilter.Protocol
                LocalPort = $PortFilter.LocalPort
                RemotePort = $PortFilter.RemotePort
                IcmpType = $PortFilter.IcmpType
                DynamicTarget = $PortFilter.DynamicTarget
                Program = $ApplicationFilter.Program
                Package = $ApplicationFilter.Package
                InterfaceAlias = $InterfaceFilter.InterfaceAlias
                InterfaceType = $InterfaceTypeFilter.InterfaceType
                Authentication = $SecurityFilter.Authentication
                Encryption = $SecurityFilter.Encryption
                OverrideBlockRules = $SecurityFilter.OverrideBlockRules
                LocalUser = ConvertIdentityString $SecurityFilter.LocalUser
                RemoteUser = ConvertIdentityString $SecurityFilter.RemoteUser
                RemoteMachine = ConvertIdentityString $SecurityFilter.RemoteMachine
            }
        }
    }
} | Out-GridView

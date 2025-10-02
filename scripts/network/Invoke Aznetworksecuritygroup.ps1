#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Aznetworksecuritygroup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzNetworkSecurityGroup {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzNetworkSecurityGroup {
$NewAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    Name              = $NSGName
    SecurityRules     = $rule1
    Tag               = $Tags
};
$NSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat`n}

#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Invoke Getazvirtualnetworksubnetconfig

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-GetAzVirtualNetworkSubnetConfig {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-GetAzVirtualNetworkSubnetConfig {
    $GetAzVirtualNetworkSubnetConfigSplat = @{
        Name           = $SubnetName
        VirtualNetwork = $vnet
    }
$Subnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
    Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop`n}

#Requires -Version 7.0
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Invoke Getazvirtualnetworksubnetconfig

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-GetAzVirtualNetworkSubnetConfig {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-GetAzVirtualNetworkSubnetConfig {
    #region func-Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
    #Creating the IP config for the NIC
    # $vnet = Get-AzVirtualNetwork -Name myvnet -ResourceGroupName myrg
    $getAzVirtualNetworkSubnetConfigSplat = @{
        Name           = $SubnetName
        VirtualNetwork = $vnet
    }
$Subnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
    #;  $PIP1 = Get-AzPublicIPAddress -Name "PIP1" -ResourceGroupName "RG1"
    Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
    #endRegion func Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
}\n


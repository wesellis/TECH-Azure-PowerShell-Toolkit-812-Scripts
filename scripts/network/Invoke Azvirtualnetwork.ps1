#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Invoke Azvirtualnetwork

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVirtualNetwork {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVirtualNetwork {

$newAzVirtualNetworkSplat = @{
    Name              = $NetworkName
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    AddressPrefix     = $VnetAddressPrefix
    Subnet            = $SingleSubnet
    Tag               = $Tags
};
$Vnet = New-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkSplat
}



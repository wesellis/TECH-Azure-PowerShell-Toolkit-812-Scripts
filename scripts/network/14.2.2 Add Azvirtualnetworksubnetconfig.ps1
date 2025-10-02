#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    14.2.2 Add Azvirtualnetworksubnetconfig
.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    $getAzVirtualNetworkSplat = @{
        Name = 'ProductionVNET'
    }
$vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat
$addAzVirtualNetworkSubnetConfigSplat = @{
        Name = 'AzureBastionSubnet'
        VirtualNetwork = $vnet
        AddressPrefix = " 10.0.2.0/24"
    }
    Add-AzVirtualNetworkSubnetConfig @addAzVirtualNetworkSubnetConfigSplat
    $vnet | Set-AzVirtualNetwork -ErrorAction Stop



#Requires -Version 7.0
#Requires -Modules Az.Network

<#
.SYNOPSIS
    14.2.2 Add Azvirtualnetworksubnetconfig
.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    # Name = 'TestResourceGroup'
    # Location = 'centralus'
    # $newAzVirtualNetworkSubnetConfigSplat = @{
        # Name = 'frontendSubnet'
        # AddressPrefix = " 10.0.1.0/24"
    # }
    # $frontendSubnet = New-AzVirtualNetworkSubnetConfig -ErrorAction Stop @newAzVirtualNetworkSubnetConfigSplat
    # $newAzVirtualNetworkSplat = @{
    #     Name = 'MyVirtualNetwork'
    #     ResourceGroupName = 'TestResourceGroup'
    #     Location = 'centralus'
    #     AddressPrefix = " 10.0.0.0/16"
    #     Subnet = $frontendSubnet
    # }
    # $Vnet = New-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkSplat
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
    $vnet | Set-AzVirtualNetwork -ErrorAction Stop\n


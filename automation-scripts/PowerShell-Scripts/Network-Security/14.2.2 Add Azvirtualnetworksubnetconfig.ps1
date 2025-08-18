<#
.SYNOPSIS
    We Enhanced 14.2.2 Add Azvirtualnetworksubnetconfig

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$vnet | Set-AzVirtualNetwork


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }


    # Name = 'TestResourceGroup'
    # Location = 'centralus'




    # $newAzVirtualNetworkSubnetConfigSplat = @{
        # Name = 'frontendSubnet'
        # AddressPrefix = " 10.0.1.0/24"
    # }

    # $frontendSubnet = New-AzVirtualNetworkSubnetConfig @newAzVirtualNetworkSubnetConfigSplat
    # $newAzVirtualNetworkSplat = @{
    #     Name = 'MyVirtualNetwork'
    #     ResourceGroupName = 'TestResourceGroup'
    #     Location = 'centralus'
    #     AddressPrefix = " 10.0.0.0/16"
    #     Subnet = $frontendSubnet
    # }

    # $WEVnet = New-AzVirtualNetwork @newAzVirtualNetworkSplat

    $getAzVirtualNetworkSplat = @{
        Name = 'ProductionVNET'
    }
    
    $vnet = Get-AzVirtualNetwork @getAzVirtualNetworkSplat

   ;  $addAzVirtualNetworkSubnetConfigSplat = @{
        Name = 'AzureBastionSubnet'
        VirtualNetwork = $vnet
        AddressPrefix = " 10.0.2.0/24"
    }

    Add-AzVirtualNetworkSubnetConfig @addAzVirtualNetworkSubnetConfigSplat
    $vnet | Set-AzVirtualNetwork


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
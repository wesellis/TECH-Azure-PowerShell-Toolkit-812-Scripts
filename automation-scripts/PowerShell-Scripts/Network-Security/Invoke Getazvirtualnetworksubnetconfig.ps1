<#
.SYNOPSIS
    Invoke Getazvirtualnetworksubnetconfig

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

<#
.SYNOPSIS
    We Enhanced Invoke Getazvirtualnetworksubnetconfig

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-Invoke-GetAzVirtualNetworkSubnetConfig {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-GetAzVirtualNetworkSubnetConfig {

    #Region func Get-AzVirtualNetworkSubnetConfig
    #Creating the IP config for the NIC
    # $vnet = Get-AzVirtualNetwork -Name myvnet -ResourceGroupName myrg
    $getAzVirtualNetworkSubnetConfigSplat = @{
        Name           = $WESubnetName
        VirtualNetwork = $vnet
    }

   ;  $WESubnet = Get-AzVirtualNetworkSubnetConfig @getAzVirtualNetworkSubnetConfigSplat
    #;  $WEPIP1 = Get-AzPublicIPAddress -Name " PIP1" -ResourceGroupName " RG1"
    Get-AzVirtualNetworkSubnetConfig
    #endRegion func Get-AzVirtualNetworkSubnetConfig
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
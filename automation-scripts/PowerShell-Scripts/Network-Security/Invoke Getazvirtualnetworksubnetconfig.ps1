#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Invoke Getazvirtualnetworksubnetconfig

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function WE-Invoke-GetAzVirtualNetworkSubnetConfig {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-GetAzVirtualNetworkSubnetConfig {

    #Region func Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
    #Creating the IP config for the NIC
    # $vnet = Get-AzVirtualNetwork -Name myvnet -ResourceGroupName myrg
    $getAzVirtualNetworkSubnetConfigSplat = @{
        Name           = $WESubnetName
        VirtualNetwork = $vnet
    }

   ;  $WESubnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
    #;  $WEPIP1 = Get-AzPublicIPAddress -Name " PIP1" -ResourceGroupName " RG1"
    Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
    #endRegion func Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com


<#
.SYNOPSIS
    We Enhanced Invoke Aznetworkinterfaceipconfig

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

function WE-Invoke-AzNetworkInterfaceIpConfig {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-AzNetworkInterfaceIpConfig {
 

    #Region func New-AzNetworkInterfaceIpConfig
$newAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $WEIPConfigName
    Subnet                   = $WESubnet
    # Subnet                   = $WEVnet.Subnets[0].Id
    # PublicIpAddress          = $WEPIP.ID
    PublicIpAddress          = $WEPIP
    ApplicationSecurityGroup = $WEASG
    Primary                  = $true
}
; 
$WEIPConfig1 = New-AzNetworkInterfaceIpConfig @newAzNetworkInterfaceIpConfigSplat

    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
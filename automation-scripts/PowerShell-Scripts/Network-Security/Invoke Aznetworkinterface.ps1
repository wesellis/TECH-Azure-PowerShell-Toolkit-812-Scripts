<#
.SYNOPSIS
    Invoke Aznetworkinterface

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
    We Enhanced Invoke Aznetworkinterface

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-Invoke-AzNetworkInterface {
}


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-AzNetworkInterface {



    #Region func New-AzNetworkInterface
    #Creating the NIC for the VM
   ;  $newAzNetworkInterfaceSplat = @{
        Name                   = $WENICName
        ResourceGroupName      = $WEResourceGroupName
        Location               = $WELocationName
        # SubnetId                 = $WEVnet.Subnets[0].Id
        # PublicIpAddressId        = $WEPIP.Id
        NetworkSecurityGroupId = $WENSG.Id
        # ApplicationSecurityGroup = $WEASG
        IpConfiguration        = $WEIPConfig1
        Tag                    = $WETags
    
    }
   ;  $WENIC = New-AzNetworkInterface @newAzNetworkInterfaceSplat
    #endRegion func New-AzNetworkInterface
    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
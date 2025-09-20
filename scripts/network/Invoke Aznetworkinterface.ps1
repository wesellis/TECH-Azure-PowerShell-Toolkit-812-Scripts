#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Aznetworkinterface

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzNetworkInterface {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzNetworkInterface {
    #region func-New-AzNetworkInterface -ErrorAction Stop
    #Creating the NIC for the VM
$newAzNetworkInterfaceSplat = @{
        Name                   = $NICName
        ResourceGroupName      = $ResourceGroupName
        Location               = $LocationName
        # SubnetId                 = $Vnet.Subnets[0].Id
        # PublicIpAddressId        = $PIP.Id
        NetworkSecurityGroupId = $NSG.Id
        # ApplicationSecurityGroup = $ASG
        IpConfiguration        = $IPConfig1
        Tag                    = $Tags
    }
$NIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat
    #endRegion func New-AzNetworkInterface -ErrorAction Stop
}



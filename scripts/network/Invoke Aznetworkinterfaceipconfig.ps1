#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Aznetworkinterfaceipconfig

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzNetworkInterfaceIpConfig {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzNetworkInterfaceIpConfig {
    #region func-New-AzNetworkInterfaceIpConfig;
$newAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $IPConfigName
    Subnet                   = $Subnet
    # Subnet                   = $Vnet.Subnets[0].Id
    # PublicIpAddress          = $PIP.ID
    PublicIpAddress          = $PIP
    ApplicationSecurityGroup = $ASG
    Primary                  = $true
}
$IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
}



#Requires -Version 7.4

<#
.SYNOPSIS
    Main Azure automation script

.DESCRIPTION
    This script orchestrates Azure resource creation including resource groups,
    virtual networks, subnets, and gateways using helper functions.

.EXAMPLE
    PS C:\> .\Main.ps1
    Runs the main Azure automation workflow

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Load helper functions
$Helpers = "$PSScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }

# Execute main workflow
$Param = Invoke-DefineParam
$param.newAzResourceGroupSplat | Invoke-CreateAZRG | Out-Null
$param = $param.newAzVirtualNetworkSubnetConfigSplat | Invoke-CreateAZVNETSubnet | Invoke-DefineParam
$VNETCONFIG = $param.newAzVirtualNetworkSplat | Invoke-CreateAZVNET
$Param = $VNETCONFIG | Invoke-DefineParam
$param.newAzVirtualNetworkGatewaySubnetConfigSplat | Invoke-CreateAZGatewaysubnet | Out-Null
$GatewaySubnetConfig = $param.newAzVirtualNetworkGatewaySubnetConfigSplat | Invoke-GetAZGatewaysubnet
$VNETCONFIG | Invoke-SetAZVNET | Out-Null
$PublicIPConfig = $param.newAzPublicIpAddressSplat | Invoke-AzPublicIP
$Param = $GatewaySubnetConfig | Invoke-DefineParam
$Param = $PublicIPConfig | Invoke-DefineParam
$GatewayPublicIPConfig = $Param.newAzVirtualNetworkGatewayIpConfigSplat | Invoke-AzVirtualNetworkGatewayIpConfig
$Param = $GatewayPublicIPConfig | Invoke-DefineParam
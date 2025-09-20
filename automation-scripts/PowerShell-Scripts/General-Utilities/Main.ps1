<#
.SYNOPSIS
    Main

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
$Helpers = " $PsScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }
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
$Param = $PublicIPConfig | Invoke-DefineParam;
$GatewayPublicIPConfig = $Param.newAzVirtualNetworkGatewayIpConfigSplat | Invoke-AzVirtualNetworkGatewayIpConfig
$Param = $GatewayPublicIPConfig | Invoke-DefineParam\n
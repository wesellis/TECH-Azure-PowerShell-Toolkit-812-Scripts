#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Create Azure Virtual Network Gateway IP configuration

.DESCRIPTION
    Creates an Azure Virtual Network Gateway IP configuration with specified parameters.
    This configuration is used when creating or updating virtual network gateways.

.PARAMETER Name
    The name for the gateway IP configuration

.PARAMETER SubnetId
    The resource ID of the subnet for the gateway

.PARAMETER PublicIpAddressId
    The resource ID of the public IP address (optional)

.PARAMETER PrivateIpAddressAllocation
    The private IP address allocation method (Static or Dynamic, default: Dynamic)

.EXAMPLE
    $config = .\Invoke-Gwyipconfig.ps1 -Name "GwConfig" -SubnetId "/subscriptions/.../subnets/GatewaySubnet"

.EXAMPLE
    $config = .\Invoke-Gwyipconfig.ps1 -Name "GwConfig" -SubnetId "/subscriptions/.../subnets/GatewaySubnet" -PublicIpAddressId "/subscriptions/.../publicIPAddresses/MyPIP"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$SubnetId,

    [Parameter()]
    [string]$PublicIpAddressId,

    [Parameter()]
    [ValidateSet('Static', 'Dynamic')]
    [string]$PrivateIpAddressAllocation = 'Dynamic'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Write-Verbose "Creating Virtual Network Gateway IP configuration: $Name"

    $newAzVirtualNetworkGatewayIpConfigSplat = @{
        Name = $Name
        SubnetId = $SubnetId
        PrivateIpAddressAllocation = $PrivateIpAddressAllocation
    }

    if ($PublicIpAddressId) {
        Write-Verbose "Including Public IP Address: $PublicIpAddressId"
        $newAzVirtualNetworkGatewayIpConfigSplat.PublicIpAddressId = $PublicIpAddressId
    }

    $gatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig @newAzVirtualNetworkGatewayIpConfigSplat -ErrorAction Stop

    Write-Output "Successfully created Virtual Network Gateway IP configuration: $Name"
    return $gatewayIPConfig
}
catch {
    Write-Error "Failed to create Virtual Network Gateway IP configuration: $($_.Exception.Message)"
    throw
}
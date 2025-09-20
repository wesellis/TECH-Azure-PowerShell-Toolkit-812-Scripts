#Requires -Version 7.0
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Manage VPN

.DESCRIPTION
    Manage VPN
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$GatewayName,
    [Parameter(Mandatory)]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$GatewaySku = "VpnGw1"
)
Write-Host "Creating VPN Gateway: $GatewayName"
# Get VNet
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
# Create gateway subnet if it doesn't exist
$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet" -ErrorAction SilentlyContinue
if (-not $GatewaySubnet) {
    Write-Host "Creating GatewaySubnet..."
    Add-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet -AddressPrefix "10.0.255.0/27"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    $VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet"
}
# Create public IP for gateway
$GatewayIpName = "$GatewayName-pip"
$params = @{
    ErrorAction = "Stop"
    AllocationMethod = "Dynamic"
    ResourceGroupName = $ResourceGroupName
    Name = $GatewayIpName
    Location = $Location
}
$GatewayIp @params
# Create gateway IP configuration
$params = @{
    ErrorAction = "Stop"
    PublicIpAddressId = $GatewayIp.Id
    SubnetId = $GatewaySubnet.Id
    Name = "gatewayConfig"
}
$GatewayIpConfig @params
# Create VPN gateway
Write-Host "Creating VPN Gateway (this may take 30-45 minutes)..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    GatewaySku = $GatewaySku
    VpnType = "RouteBased"
    IpConfigurations = $GatewayIpConfig
    GatewayType = "Vpn"
    ErrorAction = "Stop"
    Name = $GatewayName
}
$Gateway @params
Write-Host "VPN Gateway created successfully:"
Write-Host "Name: $($Gateway.Name)"
Write-Host "Type: $($Gateway.GatewayType)"
Write-Host "SKU: $($Gateway.Sku.Name)"
Write-Host "Public IP: $($GatewayIp.IpAddress)"


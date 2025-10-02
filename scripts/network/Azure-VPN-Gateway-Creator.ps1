#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Manage VPN

.DESCRIPTION
    Manage VPN
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
Write-Output "Creating VPN Gateway: $GatewayName"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet" -ErrorAction SilentlyContinue
if (-not $GatewaySubnet) {
    Write-Output "Creating GatewaySubnet..."
    Add-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet -AddressPrefix "10.0.255.0/27"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    $VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet"
}
$GatewayIpName = "$GatewayName-pip"
$params = @{
    ErrorAction = "Stop"
    AllocationMethod = "Dynamic"
    ResourceGroupName = $ResourceGroupName
    Name = $GatewayIpName
    Location = $Location
}
$GatewayIp @params
$params = @{
    ErrorAction = "Stop"
    PublicIpAddressId = $GatewayIp.Id
    SubnetId = $GatewaySubnet.Id
    Name = "gatewayConfig"
}
$GatewayIpConfig @params
Write-Output "Creating VPN Gateway (this may take 30-45 minutes)..."
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
Write-Output "VPN Gateway created successfully:"
Write-Output "Name: $($Gateway.Name)"
Write-Output "Type: $($Gateway.GatewayType)"
Write-Output "SKU: $($Gateway.Sku.Name)"
Write-Output "Public IP: $($GatewayIp.IpAddress)"




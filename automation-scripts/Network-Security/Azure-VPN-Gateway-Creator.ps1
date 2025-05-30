# ============================================================================
# Script Name: Azure VPN Gateway Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure VPN Gateway for site-to-site connectivity
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$GatewayName,
    
    [Parameter(Mandatory=$true)]
    [string]$VNetName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
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
$GatewayIp = New-AzPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Name $GatewayIpName `
    -Location $Location `
    -AllocationMethod Dynamic

# Create gateway IP configuration
$GatewayIpConfig = New-AzVirtualNetworkGatewayIpConfig `
    -Name "gatewayConfig" `
    -SubnetId $GatewaySubnet.Id `
    -PublicIpAddressId $GatewayIp.Id

# Create VPN gateway
Write-Host "Creating VPN Gateway (this may take 30-45 minutes)..."
$Gateway = New-AzVirtualNetworkGateway `
    -ResourceGroupName $ResourceGroupName `
    -Name $GatewayName `
    -Location $Location `
    -IpConfigurations $GatewayIpConfig `
    -GatewayType "Vpn" `
    -VpnType "RouteBased" `
    -GatewaySku $GatewaySku

Write-Host "✅ VPN Gateway created successfully:"
Write-Host "  Name: $($Gateway.Name)"
Write-Host "  Type: $($Gateway.GatewayType)"
Write-Host "  SKU: $($Gateway.Sku.Name)"
Write-Host "  Public IP: $($GatewayIp.IpAddress)"

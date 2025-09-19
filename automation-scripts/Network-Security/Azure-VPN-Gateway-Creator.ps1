#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
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

#region Functions

Write-Information "Creating VPN Gateway: $GatewayName"

# Get VNet
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName

# Create gateway subnet if it doesn't exist
$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "GatewaySubnet" -ErrorAction SilentlyContinue
if (-not $GatewaySubnet) {
    Write-Information "Creating GatewaySubnet..."
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
Write-Information "Creating VPN Gateway (this may take 30-45 minutes)..."
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

Write-Information " VPN Gateway created successfully:"
Write-Information "  Name: $($Gateway.Name)"
Write-Information "  Type: $($Gateway.GatewayType)"
Write-Information "  SKU: $($Gateway.Sku.Name)"
Write-Information "  Public IP: $($GatewayIp.IpAddress)"


#endregion

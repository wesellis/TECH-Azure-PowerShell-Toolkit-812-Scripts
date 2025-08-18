# ============================================================================
# Script Name: Azure Virtual Network Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Virtual Networks with subnets and network security groups
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VnetName,
    [string]$AddressPrefix,
    [string]$Location,
    [string]$SubnetName = "default",
    [string]$SubnetPrefix
)

Write-Information "Provisioning Virtual Network: $VnetName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Address Prefix: $AddressPrefix"

# Create subnet configuration if specified
if ($SubnetPrefix) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    Write-Information "Subnet: $SubnetName ($SubnetPrefix)"
    
    # Create virtual network with subnet
    $VNet = New-AzVirtualNetwork -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $VnetName `
        -AddressPrefix $AddressPrefix `
        -Subnet $SubnetConfig
} else {
    # Create virtual network without subnet
    $VNet = New-AzVirtualNetwork -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $VnetName `
        -AddressPrefix $AddressPrefix
}

Write-Information "Virtual Network $VnetName provisioned successfully"
Write-Information "VNet ID: $($VNet.Id)"

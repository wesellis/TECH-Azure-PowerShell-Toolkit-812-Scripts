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

Write-Host "Provisioning Virtual Network: $VnetName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Address Prefix: $AddressPrefix"

# Create subnet configuration if specified
if ($SubnetPrefix) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    Write-Host "Subnet: $SubnetName ($SubnetPrefix)"
    
    # Create virtual network with subnet
    $VNet = New-AzVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $VnetName `
        -AddressPrefix $AddressPrefix `
        -Subnet $SubnetConfig
} else {
    # Create virtual network without subnet
    $VNet = New-AzVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $VnetName `
        -AddressPrefix $AddressPrefix
}

Write-Host "Virtual Network $VnetName provisioned successfully"
Write-Host "VNet ID: $($VNet.Id)"

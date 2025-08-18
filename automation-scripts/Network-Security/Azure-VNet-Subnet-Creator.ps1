# ============================================================================
# Script Name: Azure VNet Subnet Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Adds a new subnet to an existing Azure Virtual Network
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VNetName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubnetName,
    
    [Parameter(Mandatory=$true)]
    [string]$AddressPrefix
)

Write-Information "Adding subnet to VNet: $VNetName"

$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName

Add-AzVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -VirtualNetwork $VNet `
    -AddressPrefix $AddressPrefix

Set-AzVirtualNetwork -VirtualNetwork $VNet

Write-Information "Subnet added successfully:"
Write-Information "  Subnet: $SubnetName"
Write-Information "  Address: $AddressPrefix"
Write-Information "  VNet: $VNetName"

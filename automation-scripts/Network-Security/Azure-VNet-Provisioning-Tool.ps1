<#
.SYNOPSIS
    Manage VNets

.DESCRIPTION
    Manage VNets
    Author: Wes Ellis (wes@wesellis.com)#>
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
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AddressPrefix = $AddressPrefix
        Subnet = $SubnetConfig
        Name = $VnetName
    }
    $VNet = New-AzVirtualNetwork @params
} else {
    # Create virtual network without subnet
    $params = @{
        AddressPrefix = $AddressPrefix
        ResourceGroupName = $ResourceGroupName
        Name = $VnetName
        Location = $Location
    }
    $VNet = New-AzVirtualNetwork @params
}
Write-Host "Virtual Network $VnetName provisioned successfully"
Write-Host "VNet ID: $($VNet.Id)"


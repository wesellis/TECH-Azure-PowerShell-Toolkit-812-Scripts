#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Manage VNets

.DESCRIPTION
    Manage VNets
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$VnetName,
    [string]$AddressPrefix,
    [string]$Location,
    [string]$SubnetName = "default",
    [string]$SubnetPrefix
)
Write-Output "Provisioning Virtual Network: $VnetName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Address Prefix: $AddressPrefix"
if ($SubnetPrefix) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    Write-Output "Subnet: $SubnetName ($SubnetPrefix)"
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AddressPrefix = $AddressPrefix
        Subnet = $SubnetConfig
        Name = $VnetName
    }
    $VNet = New-AzVirtualNetwork @params
} else {
    $params = @{
        AddressPrefix = $AddressPrefix
        ResourceGroupName = $ResourceGroupName
        Name = $VnetName
        Location = $Location
    }
    $VNet = New-AzVirtualNetwork @params
}
Write-Output "Virtual Network $VnetName provisioned successfully"
Write-Output "VNet ID: $($VNet.Id)"




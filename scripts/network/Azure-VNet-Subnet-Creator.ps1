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

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [string]$SubnetName,
    [Parameter(Mandatory)]
    [string]$AddressPrefix
)
Write-Output "Adding subnet to VNet: $VNetName"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$params = @{
    AddressPrefix = $AddressPrefix
    VirtualNetwork = $VNet
    Name = $SubnetName
}
Add-AzVirtualNetworkSubnetConfig @params
Set-AzVirtualNetwork -VirtualNetwork $VNet
Write-Output "Subnet added successfully:"
Write-Output "Subnet: $SubnetName"
Write-Output "Address: $AddressPrefix"
Write-Output "VNet: $VNetName"




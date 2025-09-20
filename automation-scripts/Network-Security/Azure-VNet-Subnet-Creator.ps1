#Requires -Version 7.0
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Manage VNets

.DESCRIPTION
    Manage VNets
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [string]$SubnetName,
    [Parameter(Mandatory)]
    [string]$AddressPrefix
)
Write-Host "Adding subnet to VNet: $VNetName"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$params = @{
    AddressPrefix = $AddressPrefix
    VirtualNetwork = $VNet
    Name = $SubnetName
}
Add-AzVirtualNetworkSubnetConfig @params
Set-AzVirtualNetwork -VirtualNetwork $VNet
Write-Host "Subnet added successfully:"
Write-Host "Subnet: $SubnetName"
Write-Host "Address: $AddressPrefix"
Write-Host "VNet: $VNetName"


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
    [string]$VNetName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubnetName,
    
    [Parameter(Mandatory=$true)]
    [string]$AddressPrefix
)

#region Functions

Write-Information "Adding subnet to VNet: $VNetName"

$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName

$params = @{
    AddressPrefix = $AddressPrefix
    VirtualNetwork = $VNet
    Name = $SubnetName
}
Add-AzVirtualNetworkSubnetConfig @params

Set-AzVirtualNetwork -VirtualNetwork $VNet

Write-Information "Subnet added successfully:"
Write-Information "  Subnet: $SubnetName"
Write-Information "  Address: $AddressPrefix"
Write-Information "  VNet: $VNetName"


#endregion

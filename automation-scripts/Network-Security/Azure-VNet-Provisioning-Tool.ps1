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
    [string]$ResourceGroupName,
    [string]$VnetName,
    [string]$AddressPrefix,
    [string]$Location,
    [string]$SubnetName = "default",
    [string]$SubnetPrefix
)

#region Functions

Write-Information "Provisioning Virtual Network: $VnetName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Address Prefix: $AddressPrefix"

# Create subnet configuration if specified
if ($SubnetPrefix) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    Write-Information "Subnet: $SubnetName ($SubnetPrefix)"
    
    # Create virtual network with subnet
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AddressPrefix = $AddressPrefix
        Subnet = $SubnetConfig
        ErrorAction = "Stop"
        Name = $VnetName
    }
    $VNet @params
} else {
    # Create virtual network without subnet
    $params = @{
        ErrorAction = "Stop"
        AddressPrefix = $AddressPrefix
        ResourceGroupName = $ResourceGroupName
        Name = $VnetName
        Location = $Location
    }
    $VNet @params
}

Write-Information "Virtual Network $VnetName provisioned successfully"
Write-Information "VNet ID: $($VNet.Id)"


#endregion

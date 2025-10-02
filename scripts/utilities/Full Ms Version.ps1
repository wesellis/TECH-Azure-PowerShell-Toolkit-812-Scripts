#Requires -Version 7.4
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Full Ms Version - Azure VPN Gateway Setup Script

.DESCRIPTION
    Azure automation script for creating VPN gateway infrastructure.
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER ResourceGroupName
    Name of the resource group to create or use

.PARAMETER VirtualNetworkName
    Name of the virtual network to create

.PARAMETER Location
    Azure region for resource deployment

.EXAMPLE
    PS C:\> .\Full_Ms_Version.ps1 -ResourceGroupName "TestRG1" -VirtualNetworkName "VNet1" -Location "EastUS"
    Creates a VPN gateway infrastructure in the specified resource group

.INPUTS
    String parameters for resource configuration

.OUTPUTS
    Azure VPN Gateway configuration objects

.NOTES
    General notes about VPN gateway configuration
    Reference: https://docs.microsoft.com/en-us/azure/vpn-gateway/create-routebased-vpn-gateway-powershell
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = "TestRG1",

    [Parameter(Mandatory = $true)]
    [string]$VirtualNetworkName = "VNet1",

    [Parameter(Mandatory = $true)]
    [string]$Location = "EastUS"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Create Resource Group
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop

    # Create Virtual Network
    $params = @{
        ErrorAction = "Stop"
        AddressPrefix = "10.1.0.0/16"
        ResourceGroupName = $ResourceGroupName
        Name = $VirtualNetworkName
        Location = $Location
    }
    $VirtualNetwork = New-AzVirtualNetwork @params

    # Add Frontend Subnet
    $params = @{
        AddressPrefix = "10.1.0.0/24"
        VirtualNetwork = $VirtualNetwork
        Name = "Frontend"
    }
    $SubnetConfig = Add-AzVirtualNetworkSubnetConfig @params
    $VirtualNetwork | Set-AzVirtualNetwork -ErrorAction Stop

    # Add Gateway Subnet
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VirtualNetworkName
    Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix "10.1.255.0/27" -VirtualNetwork $vnet
    $vnet | Set-AzVirtualNetwork -ErrorAction Stop

    # Create Public IP for Gateway
    $PublicipaddressSplat = @{
        Name = "VNet1GWIP"
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        AllocationMethod = "Dynamic"
    }
    $gwpip = New-AzPublicIpAddress @PublicipaddressSplat

    # Configure Gateway IP
    $vnet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
    $gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name "gwipconfig1" -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id

    # Create Virtual Network Gateway
    New-AzVirtualNetworkGateway -Name "VNet1GW" -ResourceGroupName $ResourceGroupName -Location $Location -GatewayType "Vpn" -IpConfigurations $gwipconfig -VpnType "RouteBased" -GatewaySku "VpnGw1"

    # Get Gateway and Public IP Information
    $gateway = Get-AzVirtualNetworkGateway -Name "Vnet1GW" -ResourceGroup $ResourceGroupName
    $publicIP = Get-AzPublicIpAddress -Name "VNet1GWIP" -ResourceGroupName $ResourceGroupName

    Write-Output "Gateway created successfully:"
    Write-Output "Gateway Name: $($gateway.Name)"
    Write-Output "Public IP: $($publicIP.IpAddress)"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
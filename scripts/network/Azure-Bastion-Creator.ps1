#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Manage Bastion

.DESCRIPTION
    Manage Bastion
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$BastionName,
    [Parameter(Mandatory)]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [string]$Location
)
Write-Output "Creating Azure Bastion: $BastionName"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet" -ErrorAction SilentlyContinue
if (-not $BastionSubnet) {
    Write-Output "Creating AzureBastionSubnet..."
    Add-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -VirtualNetwork $VNet -AddressPrefix "10.0.1.0/24"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    $VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet"
}
$BastionIpName = "$BastionName-pip"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $BastionIpName
}
$BastionIp @params
Write-Output "Creating Bastion host (this may take 10-15 minutes)..."
$params = @{
    ErrorAction = "Stop"
    PublicIpAddress = $BastionIp
    VirtualNetwork = $VNet
    ResourceGroupName = $ResourceGroupName
    Name = $BastionName
}
$Bastion @params
Write-Output "Azure Bastion created successfully:"
Write-Output "Name: $($Bastion.Name)"
Write-Output "Location: $($Bastion.Location)"
Write-Output "Public IP: $($BastionIp.IpAddress)"
Write-Output "DNS Name: $($BastionIp.DnsSettings.Fqdn)"
Write-Output "`nBastion Usage:"
Write-Output "Connect to VMs via Azure Portal"
Write-Output "No need for public IPs on VMs"
Write-Output "Secure RDP/SSH access"
Write-Output "No VPN client required"




#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Manage Bastion

.DESCRIPTION
    Manage Bastion
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$BastionName,
    [Parameter(Mandatory)]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [string]$Location
)
Write-Host "Creating Azure Bastion: $BastionName"
# Get VNet
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
# Create AzureBastionSubnet if it doesn't exist
$BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet" -ErrorAction SilentlyContinue
if (-not $BastionSubnet) {
    Write-Host "Creating AzureBastionSubnet..."
    Add-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -VirtualNetwork $VNet -AddressPrefix "10.0.1.0/24"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    $VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet"
}
# Create public IP for Bastion
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
# Create Bastion
Write-Host "Creating Bastion host (this may take 10-15 minutes)..."
$params = @{
    ErrorAction = "Stop"
    PublicIpAddress = $BastionIp
    VirtualNetwork = $VNet
    ResourceGroupName = $ResourceGroupName
    Name = $BastionName
}
$Bastion @params
Write-Host "Azure Bastion created successfully:"
Write-Host "Name: $($Bastion.Name)"
Write-Host "Location: $($Bastion.Location)"
Write-Host "Public IP: $($BastionIp.IpAddress)"
Write-Host "DNS Name: $($BastionIp.DnsSettings.Fqdn)"
Write-Host "`nBastion Usage:"
Write-Host "Connect to VMs via Azure Portal"
Write-Host "No need for public IPs on VMs"
Write-Host "Secure RDP/SSH access"
Write-Host "No VPN client required"


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
    [string]$BastionName,
    
    [Parameter(Mandatory=$true)]
    [string]$VNetName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location
)

#region Functions

Write-Information "Creating Azure Bastion: $BastionName"

# Get VNet
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName

# Create AzureBastionSubnet if it doesn't exist
$BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet" -ErrorAction SilentlyContinue
if (-not $BastionSubnet) {
    Write-Information "Creating AzureBastionSubnet..."
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
Write-Information "Creating Bastion host (this may take 10-15 minutes)..."
$params = @{
    ErrorAction = "Stop"
    PublicIpAddress = $BastionIp
    VirtualNetwork = $VNet
    ResourceGroupName = $ResourceGroupName
    Name = $BastionName
}
$Bastion @params

Write-Information " Azure Bastion created successfully:"
Write-Information "  Name: $($Bastion.Name)"
Write-Information "  Location: $($Bastion.Location)"
Write-Information "  Public IP: $($BastionIp.IpAddress)"
Write-Information "  DNS Name: $($BastionIp.DnsSettings.Fqdn)"

Write-Information "`nBastion Usage:"
Write-Information "• Connect to VMs via Azure Portal"
Write-Information "• No need for public IPs on VMs"
Write-Information "• Secure RDP/SSH access"
Write-Information "• No VPN client required"


#endregion

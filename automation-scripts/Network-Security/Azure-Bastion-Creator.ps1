# ============================================================================
# Script Name: Azure Bastion Host Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Bastion for secure VM access without public IPs
# ============================================================================

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
$BastionIp = New-AzPublicIpAddress -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $BastionIpName `
    -Location $Location `
    -AllocationMethod Static `
    -Sku Standard

# Create Bastion
Write-Information "Creating Bastion host (this may take 10-15 minutes)..."
$Bastion = New-AzBastion -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $BastionName `
    -PublicIpAddress $BastionIp `
    -VirtualNetwork $VNet

Write-Information "✅ Azure Bastion created successfully:"
Write-Information "  Name: $($Bastion.Name)"
Write-Information "  Location: $($Bastion.Location)"
Write-Information "  Public IP: $($BastionIp.IpAddress)"
Write-Information "  DNS Name: $($BastionIp.DnsSettings.Fqdn)"

Write-Information "`nBastion Usage:"
Write-Information "• Connect to VMs via Azure Portal"
Write-Information "• No need for public IPs on VMs"
Write-Information "• Secure RDP/SSH access"
Write-Information "• No VPN client required"

# ============================================================================
# Script Name: Azure NAT Gateway Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure NAT Gateway for outbound internet connectivity
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$NatGatewayName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [int]$IdleTimeoutInMinutes = 10
)

Write-Information "Creating NAT Gateway: $NatGatewayName"

# Create public IP for NAT Gateway
$NatIpName = "$NatGatewayName-pip"
$NatIp = New-AzPublicIpAddress -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $NatIpName `
    -Location $Location `
    -AllocationMethod Static `
    -Sku Standard

# Create NAT Gateway
$NatGateway = New-AzNatGateway -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $NatGatewayName `
    -Location $Location `
    -IdleTimeoutInMinutes $IdleTimeoutInMinutes `
    -Sku Standard `
    -PublicIpAddress $NatIp

Write-Information "✅ NAT Gateway created successfully:"
Write-Information "  Name: $($NatGateway.Name)"
Write-Information "  Location: $($NatGateway.Location)"
Write-Information "  SKU: $($NatGateway.Sku.Name)"
Write-Information "  Idle Timeout: $($NatGateway.IdleTimeoutInMinutes) minutes"
Write-Information "  Public IP: $($NatIp.IpAddress)"

Write-Information "`nNext Steps:"
Write-Information "1. Associate NAT Gateway with subnet(s)"
Write-Information "2. Configure route tables if needed"
Write-Information "3. Test outbound connectivity"

Write-Information "`nUsage Command:"
Write-Information "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$natGateway"

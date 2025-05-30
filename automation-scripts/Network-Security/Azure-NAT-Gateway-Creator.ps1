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

Write-Host "Creating NAT Gateway: $NatGatewayName"

# Create public IP for NAT Gateway
$NatIpName = "$NatGatewayName-pip"
$NatIp = New-AzPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Name $NatIpName `
    -Location $Location `
    -AllocationMethod Static `
    -Sku Standard

# Create NAT Gateway
$NatGateway = New-AzNatGateway `
    -ResourceGroupName $ResourceGroupName `
    -Name $NatGatewayName `
    -Location $Location `
    -IdleTimeoutInMinutes $IdleTimeoutInMinutes `
    -Sku Standard `
    -PublicIpAddress $NatIp

Write-Host "✅ NAT Gateway created successfully:"
Write-Host "  Name: $($NatGateway.Name)"
Write-Host "  Location: $($NatGateway.Location)"
Write-Host "  SKU: $($NatGateway.Sku.Name)"
Write-Host "  Idle Timeout: $($NatGateway.IdleTimeoutInMinutes) minutes"
Write-Host "  Public IP: $($NatIp.IpAddress)"

Write-Host "`nNext Steps:"
Write-Host "1. Associate NAT Gateway with subnet(s)"
Write-Host "2. Configure route tables if needed"
Write-Host "3. Test outbound connectivity"

Write-Host "`nUsage Command:"
Write-Host "Set-AzVirtualNetworkSubnetConfig -VirtualNetwork `$vnet -Name 'subnet-name' -AddressPrefix '10.0.1.0/24' -NatGateway `$natGateway"

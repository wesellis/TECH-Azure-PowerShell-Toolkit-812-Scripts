# ============================================================================
# Script Name: Azure Public IP Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates a new Azure Public IP address
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$PublicIpName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$AllocationMethod = "Static",
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "Standard"
)

Write-Information "Creating Public IP: $PublicIpName"

$PublicIp = New-AzPublicIpAddress -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $PublicIpName `
    -Location $Location `
    -AllocationMethod $AllocationMethod `
    -Sku $Sku

Write-Information "Public IP created successfully:"
Write-Information "  Name: $($PublicIp.Name)"
Write-Information "  IP Address: $($PublicIp.IpAddress)"
Write-Information "  Allocation: $($PublicIp.PublicIpAllocationMethod)"
Write-Information "  SKU: $($PublicIp.Sku.Name)"

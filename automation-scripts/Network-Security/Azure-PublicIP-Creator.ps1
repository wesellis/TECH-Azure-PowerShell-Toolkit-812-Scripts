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

Write-Host "Creating Public IP: $PublicIpName"

$PublicIp = New-AzPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Name $PublicIpName `
    -Location $Location `
    -AllocationMethod $AllocationMethod `
    -Sku $Sku

Write-Host "Public IP created successfully:"
Write-Host "  Name: $($PublicIp.Name)"
Write-Host "  IP Address: $($PublicIp.IpAddress)"
Write-Host "  Allocation: $($PublicIp.PublicIpAllocationMethod)"
Write-Host "  SKU: $($PublicIp.Sku.Name)"

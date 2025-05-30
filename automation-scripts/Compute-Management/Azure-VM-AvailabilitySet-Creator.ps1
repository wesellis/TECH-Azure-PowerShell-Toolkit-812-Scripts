# ============================================================================
# Script Name: Azure VM Availability Set Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure VM Availability Sets for high availability
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AvailabilitySetName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [int]$PlatformFaultDomainCount = 2,
    
    [Parameter(Mandatory=$false)]
    [int]$PlatformUpdateDomainCount = 5
)

Write-Host "Creating Availability Set: $AvailabilitySetName"

$AvailabilitySet = New-AzAvailabilitySet `
    -ResourceGroupName $ResourceGroupName `
    -Name $AvailabilitySetName `
    -Location $Location `
    -PlatformFaultDomainCount $PlatformFaultDomainCount `
    -PlatformUpdateDomainCount $PlatformUpdateDomainCount `
    -Sku Aligned

Write-Host "✅ Availability Set created successfully:"
Write-Host "  Name: $($AvailabilitySet.Name)"
Write-Host "  Location: $($AvailabilitySet.Location)"
Write-Host "  Fault Domains: $($AvailabilitySet.PlatformFaultDomainCount)"
Write-Host "  Update Domains: $($AvailabilitySet.PlatformUpdateDomainCount)"
Write-Host "  SKU: $($AvailabilitySet.Sku)"

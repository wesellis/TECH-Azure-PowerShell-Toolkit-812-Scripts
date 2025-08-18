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

Write-Information "Creating Availability Set: $AvailabilitySetName"

$AvailabilitySet = New-AzAvailabilitySet -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $AvailabilitySetName `
    -Location $Location `
    -PlatformFaultDomainCount $PlatformFaultDomainCount `
    -PlatformUpdateDomainCount $PlatformUpdateDomainCount `
    -Sku Aligned

Write-Information "✅ Availability Set created successfully:"
Write-Information "  Name: $($AvailabilitySet.Name)"
Write-Information "  Location: $($AvailabilitySet.Location)"
Write-Information "  Fault Domains: $($AvailabilitySet.PlatformFaultDomainCount)"
Write-Information "  Update Domains: $($AvailabilitySet.PlatformUpdateDomainCount)"
Write-Information "  SKU: $($AvailabilitySet.Sku)"

# ============================================================================
# Script Name: Azure Resource Group Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates a new Azure Resource Group with optional tags
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Tags = @{}
)

Write-Host "Creating Resource Group: $ResourceGroupName"

if ($Tags.Count -gt 0) {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
    Write-Host "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Host "  $($Tag.Key): $($Tag.Value)"
    }
} else {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

Write-Host "✅ Resource Group created successfully:"
Write-Host "  Name: $($ResourceGroup.ResourceGroupName)"
Write-Host "  Location: $($ResourceGroup.Location)"
Write-Host "  Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Host "  Resource ID: $($ResourceGroup.ResourceId)"

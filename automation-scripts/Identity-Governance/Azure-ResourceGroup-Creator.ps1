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

Write-Information "Creating Resource Group: $ResourceGroupName"

if ($Tags.Count -gt 0) {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
    Write-Information "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Information "  $($Tag.Key): $($Tag.Value)"
    }
} else {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

Write-Information "✅ Resource Group created successfully:"
Write-Information "  Name: $($ResourceGroup.ResourceGroupName)"
Write-Information "  Location: $($ResourceGroup.Location)"
Write-Information "  Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Information "  Resource ID: $($ResourceGroup.ResourceId)"

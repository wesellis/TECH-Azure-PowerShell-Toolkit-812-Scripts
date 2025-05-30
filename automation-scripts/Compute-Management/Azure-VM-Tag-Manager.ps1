# ============================================================================
# Script Name: Azure VM Tag Manager
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Adds or updates tags on Azure Virtual Machines
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$Tags
)

Write-Host "Updating tags for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Merge existing tags with new tags
$ExistingTags = $VM.Tags
if (-not $ExistingTags) { $ExistingTags = @{} }

foreach ($Tag in $Tags.GetEnumerator()) {
    $ExistingTags[$Tag.Key] = $Tag.Value
    Write-Host "Added/Updated tag: $($Tag.Key) = $($Tag.Value)"
}

Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -Tag $ExistingTags
Write-Host "Tags updated successfully for VM: $VmName"

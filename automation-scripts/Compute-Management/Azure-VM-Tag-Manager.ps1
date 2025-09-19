#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$Tags
)

#region Functions

Write-Information "Updating tags for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Merge existing tags with new tags
$ExistingTags = $VM.Tags
if (-not $ExistingTags) { $ExistingTags = @{} }

foreach ($Tag in $Tags.GetEnumerator()) {
    $ExistingTags[$Tag.Key] = $Tag.Value
    Write-Information "Added/Updated tag: $($Tag.Key) = $($Tag.Value)"
}

Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -Tag $ExistingTags
Write-Information "Tags updated successfully for VM: $VmName"


#endregion

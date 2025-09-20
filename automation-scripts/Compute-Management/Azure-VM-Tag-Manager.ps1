#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Manage VM tags

.DESCRIPTION
    Manage VM tags\n    Author: Wes Ellis (wes@wesellis.com)\n#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter(Mandatory)]
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
Write-Host "Tags updated successfully for VM: $VmName"\n


#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Manage VM tags

.DESCRIPTION
    Manage VM tags


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter(Mandatory)]
    [hashtable]$Tags
)
Write-Output "Updating tags for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
$ExistingTags = $VM.Tags
if (-not $ExistingTags) { $ExistingTags = @{} }
foreach ($Tag in $Tags.GetEnumerator()) {
    $ExistingTags[$Tag.Key] = $Tag.Value
    Write-Output "Added/Updated tag: $($Tag.Key) = $($Tag.Value)"
}
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -Tag $ExistingTags
Write-Output "Tags updated successfully for VM: $VmName"




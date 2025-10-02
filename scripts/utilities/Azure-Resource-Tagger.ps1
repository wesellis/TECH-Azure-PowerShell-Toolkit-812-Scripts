#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Tag resources

.DESCRIPTION
    Tag resources
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    $ResourceGroupName,
    [hashtable]$Tags = @{},
    $ResourceType,
    [switch]$WhatIf,
    [switch]$Force
)
Write-Output "Azure Resource Tagger"
Write-Output "====================="
if ($Tags.Count -eq 0) {
    Write-Output "No tags specified. Example usage:"
    Write-Output "  .\Azure-Resource-Tagger.ps1 -ResourceGroupName 'MyRG' -Tags @{Environment='Prod'; Owner='IT'}"
    return
}
Write-Output "Target Resource Group: $ResourceGroupName"
Write-Output "Tags to Apply:"
foreach ($tag in $Tags.GetEnumerator()) {
    Write-Output "  $($tag.Key): $($tag.Value)"
}
if ($WhatIf) {
    Write-Output "`n[WHAT-IF MODE] - No changes will be made"
}
$resources = if ($ResourceType) {
    Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
} else {
    Get-AzResource -ResourceGroupName $ResourceGroupName
}
Write-Output "`nFound $($resources.Count) resources to tag"
$TaggedCount = 0
foreach ($resource in $resources) {
    try {
        if ($WhatIf) {
            Write-Output "  [WHAT-IF] Would tag: $($resource.Name) ($($resource.ResourceType))"
        } else {
            $ExistingTags = $resource.Tags ?? @{}
            foreach ($tag in $Tags.GetEnumerator()) {
                $ExistingTags[$tag.Key] = $tag.Value
            }
            Set-AzResource -ResourceId $resource.ResourceId -Tag $ExistingTags -Force:$Force
            Write-Output "  [OK] Tagged: $($resource.Name)"
            $TaggedCount++
        }
    } catch {
        Write-Warning "Failed to tag resource '$($resource.Name)': $($_.Exception.Message)"
    }
}
if (-not $WhatIf) {
    Write-Output "`n[OK] Successfully tagged $TaggedCount resources"
}
Write-Output "`nResource tagging completed at $(Get-Date)"




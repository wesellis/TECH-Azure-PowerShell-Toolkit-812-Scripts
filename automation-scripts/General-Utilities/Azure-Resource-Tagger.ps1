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
    [string]$ResourceGroupName,
    [hashtable]$Tags = @{},
    [string]$ResourceType,
    [switch]$WhatIf,
    [switch]$Force
)

#region Functions

Write-Information "Azure Resource Tagger"
Write-Information "====================="

if ($Tags.Count -eq 0) {
    Write-Information "No tags specified. Example usage:"
    Write-Information "  .\Azure-Resource-Tagger.ps1 -ResourceGroupName 'MyRG' -Tags @{Environment='Prod'; Owner='IT'}"
    return
}

Write-Information "Target Resource Group: $ResourceGroupName"
Write-Information "Tags to Apply:"
foreach ($tag in $Tags.GetEnumerator()) {
    Write-Information "  $($tag.Key): $($tag.Value)"
}

if ($WhatIf) {
    Write-Information "`n[WHAT-IF MODE] - No changes will be made"
}

# Get resources to tag
$resources = if ($ResourceType) {
    Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
} else {
    Get-AzResource -ResourceGroupName $ResourceGroupName
}

Write-Information "`nFound $($resources.Count) resources to tag"

$taggedCount = 0
foreach ($resource in $resources) {
    try {
        if ($WhatIf) {
            Write-Information "  [WHAT-IF] Would tag: $($resource.Name) ($($resource.ResourceType))"
        } else {
            # Merge existing tags with new tags
            $existingTags = $resource.Tags ?? @{}
            foreach ($tag in $Tags.GetEnumerator()) {
                $existingTags[$tag.Key] = $tag.Value
            }
            
            Set-AzResource -ResourceId $resource.ResourceId -Tag $existingTags -Force:$Force
            Write-Information "  [OK] Tagged: $($resource.Name)"
            $taggedCount++
        }
    } catch {
        Write-Warning "Failed to tag resource '$($resource.Name)': $($_.Exception.Message)"
    }
}

if (-not $WhatIf) {
    Write-Information "`n[OK] Successfully tagged $taggedCount resources"
}

Write-Information "`nResource tagging completed at $(Get-Date)"

#endregion

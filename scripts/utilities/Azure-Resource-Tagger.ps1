#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Tag resources

.DESCRIPTION
    Tag resources
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$ResourceGroupName,
    [hashtable]$Tags = @{},
    [string]$ResourceType,
    [switch]$WhatIf,
    [switch]$Force
)
Write-Host "Azure Resource Tagger"
Write-Host "====================="
if ($Tags.Count -eq 0) {
    Write-Host "No tags specified. Example usage:"
    Write-Host "  .\Azure-Resource-Tagger.ps1 -ResourceGroupName 'MyRG' -Tags @{Environment='Prod'; Owner='IT'}"
    return
}
Write-Host "Target Resource Group: $ResourceGroupName"
Write-Host "Tags to Apply:"
foreach ($tag in $Tags.GetEnumerator()) {
    Write-Host "  $($tag.Key): $($tag.Value)"
}
if ($WhatIf) {
    Write-Host "`n[WHAT-IF MODE] - No changes will be made"
}
# Get resources to tag
$resources = if ($ResourceType) {
    Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
} else {
    Get-AzResource -ResourceGroupName $ResourceGroupName
}
Write-Host "`nFound $($resources.Count) resources to tag"
$taggedCount = 0
foreach ($resource in $resources) {
    try {
        if ($WhatIf) {
            Write-Host "  [WHAT-IF] Would tag: $($resource.Name) ($($resource.ResourceType))"
        } else {
            # Merge existing tags with new tags
            $existingTags = $resource.Tags ?? @{}
            foreach ($tag in $Tags.GetEnumerator()) {
                $existingTags[$tag.Key] = $tag.Value
            }
            Set-AzResource -ResourceId $resource.ResourceId -Tag $existingTags -Force:$Force
            Write-Host "  [OK] Tagged: $($resource.Name)"
            $taggedCount++
        }
    } catch {
        Write-Warning "Failed to tag resource '$($resource.Name)': $($_.Exception.Message)"
    }
}
if (-not $WhatIf) {
    Write-Host "`n[OK] Successfully tagged $taggedCount resources"
}
Write-Host "`nResource tagging completed at $(Get-Date)"


# ============================================================================
# Script Name: Azure Resource Tagger
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Bulk resource tagging across Azure services
# ============================================================================

param (
    [string]$ResourceGroupName,
    [hashtable]$Tags = @{},
    [string]$ResourceType,
    [switch]$WhatIf,
    [switch]$Force
)

Write-Host "Azure Resource Tagger" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

if ($Tags.Count -eq 0) {
    Write-Host "No tags specified. Example usage:" -ForegroundColor Yellow
    Write-Host "  .\Azure-Resource-Tagger.ps1 -ResourceGroupName 'MyRG' -Tags @{Environment='Prod'; Owner='IT'}" -ForegroundColor White
    return
}

Write-Host "Target Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "Tags to Apply:" -ForegroundColor Green
foreach ($tag in $Tags.GetEnumerator()) {
    Write-Host "  $($tag.Key): $($tag.Value)" -ForegroundColor White
}

if ($WhatIf) {
    Write-Host "`n[WHAT-IF MODE] - No changes will be made" -ForegroundColor Yellow
}

# Get resources to tag
$resources = if ($ResourceType) {
    Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
} else {
    Get-AzResource -ResourceGroupName $ResourceGroupName
}

Write-Host "`nFound $($resources.Count) resources to tag" -ForegroundColor Green

$taggedCount = 0
foreach ($resource in $resources) {
    try {
        if ($WhatIf) {
            Write-Host "  [WHAT-IF] Would tag: $($resource.Name) ($($resource.ResourceType))" -ForegroundColor Yellow
        } else {
            # Merge existing tags with new tags
            $existingTags = $resource.Tags ?? @{}
            foreach ($tag in $Tags.GetEnumerator()) {
                $existingTags[$tag.Key] = $tag.Value
            }
            
            Set-AzResource -ResourceId $resource.ResourceId -Tag $existingTags -Force:$Force
            Write-Host "  ✓ Tagged: $($resource.Name)" -ForegroundColor Green
            $taggedCount++
        }
    } catch {
        Write-Warning "Failed to tag resource '$($resource.Name)': $($_.Exception.Message)"
    }
}

if (-not $WhatIf) {
    Write-Host "`n✓ Successfully tagged $taggedCount resources" -ForegroundColor Green
}

Write-Host "`nResource tagging completed at $(Get-Date)" -ForegroundColor Cyan
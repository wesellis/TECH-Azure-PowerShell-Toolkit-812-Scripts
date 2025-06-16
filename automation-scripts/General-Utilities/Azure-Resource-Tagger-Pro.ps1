# Enhanced Azure Resource Tagger with Bulk Operations
param (
    [Parameter(Mandatory=$false)][string]$ResourceGroupName,
    [Parameter(Mandatory=$false)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][hashtable]$Tags,
    [Parameter(Mandatory=$false)][string[]]$ResourceTypes,
    [Parameter(Mandatory=$false)][string]$TaggingStrategy = "Merge", # Merge, Replace, RemoveAll
    [Parameter(Mandatory=$false)][string]$ExportPath,
    [Parameter(Mandatory=$false)][switch]$WhatIf,
    [Parameter(Mandatory=$false)][switch]$Force,
    [Parameter(Mandatory=$false)][switch]$Parallel
)

# Import enhanced functions
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath ".." -AdditionalChildPath "modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

Show-Banner -ScriptName "Azure Resource Tagger Pro" -Description "Enterprise bulk tagging with advanced features"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection required" }
    
    Write-ProgressStep -StepNumber 1 -TotalSteps 5 -StepName "Discovery" -Status "Finding resources..."
    
    # Get resources based on scope
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } elseif ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
        Get-AzResource
    } else {
        Get-AzResource
    }
    
    # Filter by resource types if specified
    if ($ResourceTypes) {
        $resources = $resources | Where-Object { $_.ResourceType -in $ResourceTypes }
    }
    
    Write-Log "Found $($resources.Count) resources to process" -Level INFO
    
    Write-ProgressStep -StepNumber 2 -TotalSteps 5 -StepName "Analysis" -Status "Analyzing current tags..."
    
    # Analyze current tagging state
    $tagAnalysis = @{
        TotalResources = $resources.Count
        TaggedResources = ($resources | Where-Object { $_.Tags.Count -gt 0 }).Count
        UntaggedResources = ($resources | Where-Object { $_.Tags.Count -eq 0 }).Count
        UniqueTagKeys = ($resources.Tags.Keys | Sort-Object -Unique).Count
    }
    
    Write-Log "Tag Analysis:" -Level INFO
    Write-Log "  Total Resources: $($tagAnalysis.TotalResources)" -Level INFO
    Write-Log "  Already Tagged: $($tagAnalysis.TaggedResources)" -Level INFO
    Write-Log "  Untagged: $($tagAnalysis.UntaggedResources)" -Level INFO
    Write-Log "  Unique Tag Keys: $($tagAnalysis.UniqueTagKeys)" -Level INFO
    
    Write-ProgressStep -StepNumber 3 -TotalSteps 5 -StepName "Planning" -Status "Planning tag operations..."
    
    # Plan tagging operations
    $operations = @()
    foreach ($resource in $resources) {
        $newTags = switch ($TaggingStrategy) {
            "Merge" {
                $merged = $resource.Tags ?? @{}
                foreach ($tag in $Tags.GetEnumerator()) { $merged[$tag.Key] = $tag.Value }
                $merged
            }
            "Replace" { $Tags }
            "RemoveAll" { @{} }
        }
        
        $operations += @{
            Resource = $resource
            CurrentTags = $resource.Tags ?? @{}
            NewTags = $newTags
            Action = $TaggingStrategy
        }
    }
    
    if ($WhatIf) {
        Write-Log "[WHAT-IF] Tag operations planned:" -Level INFO
        $operations | ForEach-Object {
            Write-Log "  $($_.Resource.Name): $($_.Action) - $($_.NewTags.Count) tags" -Level INFO
        }
        return
    }
    
    Write-ProgressStep -StepNumber 4 -TotalSteps 5 -StepName "Execution" -Status "Applying tags..."
    
    # Execute tagging operations
    $successCount = 0
    $errorCount = 0
    
    if ($Parallel -and $operations.Count -gt 10) {
        # Parallel execution for large operations
        $results = $operations | ForEach-Object -Parallel {
            try {
                Set-AzResource -ResourceId $_.Resource.ResourceId -Tag $_.NewTags -Force:$using:Force
                return @{ Success = $true; ResourceName = $_.Resource.Name }
            } catch {
                Write-Warning "Failed to tag $($_.Resource.Name): $($_.Exception.Message)"
                return @{ Success = $false; ResourceName = $_.Resource.Name; Error = $_.Exception.Message }
            }
        } -ThrottleLimit 10
        
        # Count results
        $successCount = ($results | Where-Object { $_.Success }).Count
        $errorCount = ($results | Where-Object { -not $_.Success }).Count
    } else {
        # Sequential execution
        foreach ($operation in $operations) {
            try {
                Invoke-AzureOperation -Operation {
                    Set-AzResource -ResourceId $operation.Resource.ResourceId -Tag $operation.NewTags -Force:$Force
                } -OperationName "Tag Resource: $($operation.Resource.Name)" -MaxRetries 2
                $successCount = $successCount + 1
                Write-Log "✓ Tagged: $($operation.Resource.Name)" -Level SUCCESS
            } catch {
                Write-Log "✗ Failed: $($operation.Resource.Name) - $($_.Exception.Message)" -Level ERROR
                $errorCount = $errorCount + 1
            }
        }
    }
    
    Write-ProgressStep -StepNumber 5 -TotalSteps 5 -StepName "Complete" -Status "Finalizing..."
    
    # Export results if requested
    if ($ExportPath) {
        $results = $operations | Select-Object @{N="ResourceName";E={$_.Resource.Name}}, 
                                             @{N="ResourceType";E={$_.Resource.ResourceType}},
                                             @{N="Action";E={$_.Action}},
                                             @{N="TagCount";E={$_.NewTags.Count}}
        $results | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Log "Results exported to: $ExportPath" -Level INFO
    }
    
    Write-Progress -Activity "Resource Tagging" -Completed
    Write-Log "Tagging operation completed!" -Level SUCCESS
    Write-Log "  Successfully tagged: $successCount resources" -Level SUCCESS
    Write-Log "  Failed: $errorCount resources" -Level $(if ($errorCount -gt 0) { "WARN" } else { "SUCCESS" })
    
} catch {
    Write-Progress -Activity "Resource Tagging" -Completed
    Write-Log "Tagging operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    throw
}

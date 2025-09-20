<#
.SYNOPSIS
    Azure Resource Tagger Pro

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter(Mandatory)][hashtable]$Tags,
    [Parameter()][string[]]$ResourceTypes,
    [Parameter()][string]$TaggingStrategy = "Merge" , # Merge, Replace, RemoveAll
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ExportPath,
    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Force,
    [Parameter()][switch]$Parallel
)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " .." -AdditionalChildPath " modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure Resource Tagger Pro" -Description "Enterprise bulk tagging with  features"
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    # Progress stepNumber 1 -TotalSteps 5 -StepName "Discovery" -Status "Finding resources..."
    # Get resources based on scope
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } elseif ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
        Get-AzResource -ErrorAction Stop
    } else {
        Get-AzResource -ErrorAction Stop
    }
    # Filter by resource types if specified
    if ($ResourceTypes) {
        $resources = $resources | Where-Object { $_.ResourceType -in $ResourceTypes }
    }

    # Progress stepNumber 2 -TotalSteps 5 -StepName "Analysis" -Status "Analyzing current tags..."
    # Analyze current tagging state
    $tagAnalysis = @{
        TotalResources = $resources.Count
        TaggedResources = ($resources | Where-Object { $_.Tags.Count -gt 0 }).Count
        UntaggedResources = ($resources | Where-Object { $_.Tags.Count -eq 0 }).Count
        UniqueTagKeys = ($resources.Tags.Keys | Sort-Object -Unique).Count
    }

    # Progress stepNumber 3 -TotalSteps 5 -StepName "Planning" -Status "Planning tag operations..."
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
        $operations = $operations + @{
            Resource = $resource
            CurrentTags = $resource.Tags ?? @{}
            NewTags = $newTags
            Action = $TaggingStrategy
        }
    }
    if ($WhatIf) {

        $operations | ForEach-Object {

        }
        return
    }
    # Progress stepNumber 4 -TotalSteps 5 -StepName "Execution" -Status "Applying tags..."
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

            } catch {

$errorCount = $errorCount + 1
            }
        }
    }
    # Progress stepNumber 5 -TotalSteps 5 -StepName "Complete" -Status "Finalizing..."
    # Export results if requested
    if ($ExportPath) {
$results = $operations | Select-Object @{N="ResourceName" ;E={$_.Resource.Name}},
                                             @{N="ResourceType" ;E={$_.Resource.ResourceType}},
                                             @{N="Action" ;E={$_.Action}},
                                             @{N="TagCount" ;E={$_.NewTags.Count}}
        $results | Export-Csv -Path $ExportPath -NoTypeInformation

    }
        Write-Log "  Failed: $errorCount resources" -Level $(if ($errorCount -gt 0) { "WARN" } else { "SUCCESS" })
} catch {
        throw
}\n
#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Tag resources

.DESCRIPTION
    Tag resources
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]$ResourceGroupName,
    [Parameter()]$SubscriptionId,
    [Parameter(Mandatory)][hashtable]$Tags,
    [Parameter()][string[]]$ResourceTypes,
    [Parameter()]$TaggingStrategy = "Merge", # Merge, Replace, RemoveAll
    [Parameter()]$ExportPath,
    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Force,
    [Parameter()][switch]$Parallel
)
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath ".." -AdditionalChildPath "modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $ModulePath) { try {
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } elseif ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
        Get-AzResource -ErrorAction Stop
    } else {
        Get-AzResource -ErrorAction Stop
    }
    if ($ResourceTypes) {
        $resources = $resources | Where-Object { $_.ResourceType -in $ResourceTypes }
    }

    $TagAnalysis = @{
        TotalResources = $resources.Count
        TaggedResources = ($resources | Where-Object { $_.Tags.Count -gt 0 }).Count
        UntaggedResources = ($resources | Where-Object { $_.Tags.Count -eq 0 }).Count
        UniqueTagKeys = ($resources.Tags.Keys | Sort-Object -Unique).Count
    }

    $operations = @()
    foreach ($resource in $resources) {
        $NewTags = switch ($TaggingStrategy) {
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
            NewTags = $NewTags
            Action = $TaggingStrategy
        }
    }
    if ($WhatIf) {

        $operations | ForEach-Object {

        }
        return
    }
    $SuccessCount = 0
    $ErrorCount = 0
    if ($Parallel -and $operations.Count -gt 10) {
        $results = $operations | ForEach-Object -Parallel {
            try {
                Set-AzResource -ResourceId $_.Resource.ResourceId -Tag $_.NewTags -Force:$using:Force
                return @{ Success = $true; ResourceName = $_.Resource.Name }
            } catch {
                Write-Warning "Failed to tag $($_.Resource.Name): $($_.Exception.Message)"
                return @{ Success = $false; ResourceName = $_.Resource.Name; Error = $_.Exception.Message }
            }
        } -ThrottleLimit 10
        $SuccessCount = ($results | Where-Object { $_.Success }).Count
        $ErrorCount = ($results | Where-Object { -not $_.Success }).Count
    } else {
        foreach ($operation in $operations) {
            try {
                Invoke-AzureOperation -Operation {
                    Set-AzResource -ResourceId $operation.Resource.ResourceId -Tag $operation.NewTags -Force:$Force
                } -OperationName "Tag Resource: $($operation.Resource.Name)" -MaxRetries 2
                $SuccessCount = $SuccessCount + 1

            } catch {

                $ErrorCount = $ErrorCount + 1
            }
        }
    }
    if ($ExportPath) {
        $results = $operations | Select-Object @{N="ResourceName";E={$_.Resource.Name}},
                                             @{N="ResourceType";E={$_.Resource.ResourceType}},
                                             @{N="Action";E={$_.Action}},
                                             @{N="TagCount";E={$_.NewTags.Count}}
        $results | Export-Csv -Path $ExportPath -NoTypeInformation

    }
        Write-Log "  Failed: $ErrorCount resources" -Level $(if ($ErrorCount -gt 0) { "WARN" } else { "SUCCESS" })
} catch {
        throw`n}

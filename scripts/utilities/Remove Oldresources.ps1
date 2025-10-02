#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.DataFactory

<#
.SYNOPSIS
    Remove Old Azure Data Factory Resources

.DESCRIPTION
    Azure automation script to remove old triggers and pipelines from Azure Data Factory.
    Specifically targets msexports and config resources for cleanup.

.PARAMETER DataFactoryResourceGroup
    Resource group containing the Data Factory (from environment variable)

.PARAMETER DataFactoryName
    Name of the Data Factory (from environment variable)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate Azure Data Factory permissions
    Use with caution - removes resources permanently
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

try {
    # Initialize deployment script outputs
    $DeploymentScriptOutputs = @{}

    # Get Data Factory parameters from environment
    $DataFactoryResourceGroup = $env:DataFactoryResourceGroup
    $DataFactoryName = $env:DataFactoryName

    if (-not $DataFactoryResourceGroup -or -not $DataFactoryName) {
        throw "Required environment variables DataFactoryResourceGroup and DataFactoryName are not set"
    }

    Write-Output "Starting cleanup of old resources"
    Write-Output "Data Factory: $DataFactoryName"
    Write-Output "Resource Group: $DataFactoryResourceGroup"

    # Create parameter hashtable for Data Factory cmdlets
    $AdfParams = @{
        ResourceGroupName = $DataFactoryResourceGroup
        DataFactoryName   = $DataFactoryName
    }

    # Get all triggers from Data Factory
    Write-Output "`nSearching for triggers to remove..."
    $allTriggers = Get-AzDataFactoryV2Trigger @AdfParams -ErrorAction SilentlyContinue

    # Filter triggers matching the pattern for msexports
    $triggersToRemove = $allTriggers | Where-Object {
        $_.Name -match '^msexports(_(setup|daily|monthly|extract|FileAdded))?$'
    }

    if ($triggersToRemove) {
        Write-Output "Found $($triggersToRemove.Count) triggers to remove:"
        $triggersToRemove | ForEach-Object { Write-Output "  - $($_.Name)" }

        # Stop triggers before removing
        Write-Output "`nStopping triggers..."
        $stoppedTriggers = @()
        foreach ($trigger in $triggersToRemove) {
            if ($PSCmdlet.ShouldProcess($trigger.Name, "Stop Trigger")) {
                $stoppedTriggers += Stop-AzDataFactoryV2Trigger @AdfParams -Name $trigger.Name -Force -ErrorAction SilentlyContinue
                Write-Output "  Stopped: $($trigger.Name)"
            }
        }
        $DeploymentScriptOutputs["stoppedTriggers"] = $stoppedTriggers

        # Remove triggers
        Write-Output "`nRemoving triggers..."
        $removedTriggers = @()
        foreach ($trigger in $triggersToRemove) {
            if ($PSCmdlet.ShouldProcess($trigger.Name, "Remove Trigger")) {
                Remove-AzDataFactoryV2Trigger @AdfParams -Name $trigger.Name -Force -ErrorAction SilentlyContinue
                $removedTriggers += $trigger.Name
                Write-Output "  Removed: $($trigger.Name)"
            }
        }
        $DeploymentScriptOutputs["removedTriggers"] = $removedTriggers
    }
    else {
        Write-Output "No triggers found matching removal criteria"
    }

    # Get all pipelines from Data Factory
    Write-Output "`nSearching for pipelines to remove..."
    $allPipelines = Get-AzDataFactoryV2Pipeline @AdfParams -ErrorAction SilentlyContinue

    # Filter pipelines matching the pattern for msexports and config
    $pipelinesToRemove = $allPipelines | Where-Object {
        $_.Name -match '^(msexports_(backfill|extract|fill|get|run|setup|transform)|config_(BackfillData|ExportData|RunBackfill|RunExports))$'
    }

    if ($pipelinesToRemove) {
        Write-Output "Found $($pipelinesToRemove.Count) pipelines to remove:"
        $pipelinesToRemove | ForEach-Object { Write-Output "  - $($_.Name)" }

        # Remove pipelines
        Write-Output "`nRemoving pipelines..."
        $removedPipelines = @()
        foreach ($pipeline in $pipelinesToRemove) {
            if ($PSCmdlet.ShouldProcess($pipeline.Name, "Remove Pipeline")) {
                Remove-AzDataFactoryV2Pipeline @AdfParams -Name $pipeline.Name -Force -ErrorAction SilentlyContinue
                $removedPipelines += $pipeline.Name
                Write-Output "  Removed: $($pipeline.Name)"
            }
        }
        $DeploymentScriptOutputs["removedPipelines"] = $removedPipelines
    }
    else {
        Write-Output "No pipelines found matching removal criteria"
    }

    # Output summary
    Write-Output "`n========== Cleanup Summary =========="
    Write-Output "Triggers stopped: $($DeploymentScriptOutputs['stoppedTriggers'].Count)"
    Write-Output "Triggers removed: $($DeploymentScriptOutputs['removedTriggers'].Count)"
    Write-Output "Pipelines removed: $($DeploymentScriptOutputs['removedPipelines'].Count)"
    Write-Output "====================================="

    # Return outputs for deployment script
    $DeploymentScriptOutputs
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

# Example usage:
# $env:DataFactoryResourceGroup = "myResourceGroup"
# $env:DataFactoryName = "myDataFactory"
# .\Remove Oldresources.ps1 -WhatIf  # Preview changes
# .\Remove Oldresources.ps1          # Actually remove resources
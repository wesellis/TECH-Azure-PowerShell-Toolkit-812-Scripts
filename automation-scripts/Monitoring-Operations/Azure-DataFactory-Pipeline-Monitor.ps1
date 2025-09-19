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
    [string]$FactoryName,
    [int]$DaysBack = 7
)

#region Functions

Write-Information "Monitoring Data Factory: $FactoryName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Analysis Period: Last $DaysBack days"
Write-Information "============================================"

# Get Data Factory details
$DataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $FactoryName

Write-Information "Data Factory Information:"
Write-Information "  Name: $($DataFactory.DataFactoryName)"
Write-Information "  Location: $($DataFactory.Location)"
Write-Information "  Provisioning State: $($DataFactory.ProvisioningState)"
Write-Information "  Created Time: $($DataFactory.CreateTime)"

if ($DataFactory.RepoConfiguration) {
    Write-Information "  Git Integration: $($DataFactory.RepoConfiguration.Type)"
    Write-Information "  Repository: $($DataFactory.RepoConfiguration.RepositoryName)"
}

# Get pipelines
Write-Information "`nPipelines:"
$Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName

if ($Pipelines.Count -eq 0) {
    Write-Information "  No pipelines found"
} else {
    foreach ($Pipeline in $Pipelines) {
        Write-Information "  - Pipeline: $($Pipeline.Name)"
        Write-Information "    Activities: $($Pipeline.Activities.Count)"
        Write-Information "    Parameters: $($Pipeline.Parameters.Count)"
    }
}

# Get recent pipeline runs
$EndTime = Get-Date -ErrorAction Stop
$StartTime = $EndTime.AddDays(-$DaysBack)

Write-Information "`nRecent Pipeline Runs (Last $DaysBack days):"
try {
    $PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
    
    if ($PipelineRuns.Count -eq 0) {
        Write-Information "  No pipeline runs found in the specified period"
    } else {
        # Group by status for summary
        $RunSummary = $PipelineRuns | Group-Object Status
        Write-Information "`nPipeline Run Summary:"
        foreach ($Group in $RunSummary) {
            Write-Information "  $($Group.Name): $($Group.Count) runs"
        }
        
        # Show recent runs
        Write-Information "`nRecent Pipeline Runs:"
        $RecentRuns = $PipelineRuns | Sort-Object RunStart -Descending | Select-Object -First 10
        
        foreach ($Run in $RecentRuns) {
            Write-Information "  - Pipeline: $($Run.PipelineName)"
            Write-Information "    Run ID: $($Run.RunId)"
            Write-Information "    Status: $($Run.Status)"
            Write-Information "    Start Time: $($Run.RunStart)"
            Write-Information "    End Time: $($Run.RunEnd)"
            
            if ($Run.RunEnd -and $Run.RunStart) {
                $Duration = $Run.RunEnd - $Run.RunStart
                Write-Information "    Duration: $($Duration.ToString('hh\:mm\:ss'))"
            }
            
            if ($Run.Message) {
                Write-Information "    Message: $($Run.Message)"
            }
            Write-Information "    ---"
        }
    }
} catch {
    Write-Information "  Unable to retrieve pipeline runs: $($_.Exception.Message)"
}

# Get linked services
Write-Information "`nLinked Services:"
try {
    $LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    
    if ($LinkedServices.Count -eq 0) {
        Write-Information "  No linked services found"
    } else {
        foreach ($LinkedService in $LinkedServices) {
            Write-Information "  - Service: $($LinkedService.Name)"
            Write-Information "    Type: $($LinkedService.Properties.Type)"
        }
    }
} catch {
    Write-Information "  Unable to retrieve linked services: $($_.Exception.Message)"
}

# Get datasets
Write-Information "`nDatasets:"
try {
    $Datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    
    if ($Datasets.Count -eq 0) {
        Write-Information "  No datasets found"
    } else {
        foreach ($Dataset in $Datasets) {
            Write-Information "  - Dataset: $($Dataset.Name)"
            Write-Information "    Type: $($Dataset.Properties.Type)"
        }
    }
} catch {
    Write-Information "  Unable to retrieve datasets: $($_.Exception.Message)"
}

# Get triggers
Write-Information "`nTriggers:"
try {
    $Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    
    if ($Triggers.Count -eq 0) {
        Write-Information "  No triggers found"
    } else {
        foreach ($Trigger in $Triggers) {
            Write-Information "  - Trigger: $($Trigger.Name)"
            Write-Information "    Type: $($Trigger.Properties.Type)"
            Write-Information "    State: $($Trigger.Properties.RuntimeState)"
        }
    }
} catch {
    Write-Information "  Unable to retrieve triggers: $($_.Exception.Message)"
}

Write-Information "`nData Factory Portal Access:"
Write-Information "URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName"

Write-Information "`nMonitoring Recommendations:"
Write-Information "1. Review failed pipeline runs for error patterns"
Write-Information "2. Monitor pipeline execution duration trends"
Write-Information "3. Check data movement and transformation performance"
Write-Information "4. Validate trigger schedules and dependencies"
Write-Information "5. Monitor integration runtime utilization"

Write-Information "`nData Factory monitoring completed at $(Get-Date)"


#endregion

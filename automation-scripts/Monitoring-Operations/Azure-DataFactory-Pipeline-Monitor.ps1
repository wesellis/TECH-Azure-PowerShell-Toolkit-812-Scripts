# ============================================================================
# Script Name: Azure Data Factory Pipeline Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Data Factory pipelines, activities, and execution status
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$FactoryName,
    [int]$DaysBack = 7
)

Write-Host "Monitoring Data Factory: $FactoryName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Analysis Period: Last $DaysBack days"
Write-Host "============================================"

# Get Data Factory details
$DataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $FactoryName

Write-Host "Data Factory Information:"
Write-Host "  Name: $($DataFactory.DataFactoryName)"
Write-Host "  Location: $($DataFactory.Location)"
Write-Host "  Provisioning State: $($DataFactory.ProvisioningState)"
Write-Host "  Created Time: $($DataFactory.CreateTime)"

if ($DataFactory.RepoConfiguration) {
    Write-Host "  Git Integration: $($DataFactory.RepoConfiguration.Type)"
    Write-Host "  Repository: $($DataFactory.RepoConfiguration.RepositoryName)"
}

# Get pipelines
Write-Host "`nPipelines:"
$Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName

if ($Pipelines.Count -eq 0) {
    Write-Host "  No pipelines found"
} else {
    foreach ($Pipeline in $Pipelines) {
        Write-Host "  - Pipeline: $($Pipeline.Name)"
        Write-Host "    Activities: $($Pipeline.Activities.Count)"
        Write-Host "    Parameters: $($Pipeline.Parameters.Count)"
    }
}

# Get recent pipeline runs
$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-$DaysBack)

Write-Host "`nRecent Pipeline Runs (Last $DaysBack days):"
try {
    $PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
    
    if ($PipelineRuns.Count -eq 0) {
        Write-Host "  No pipeline runs found in the specified period"
    } else {
        # Group by status for summary
        $RunSummary = $PipelineRuns | Group-Object Status
        Write-Host "`nPipeline Run Summary:"
        foreach ($Group in $RunSummary) {
            Write-Host "  $($Group.Name): $($Group.Count) runs"
        }
        
        # Show recent runs
        Write-Host "`nRecent Pipeline Runs:"
        $RecentRuns = $PipelineRuns | Sort-Object RunStart -Descending | Select-Object -First 10
        
        foreach ($Run in $RecentRuns) {
            Write-Host "  - Pipeline: $($Run.PipelineName)"
            Write-Host "    Run ID: $($Run.RunId)"
            Write-Host "    Status: $($Run.Status)"
            Write-Host "    Start Time: $($Run.RunStart)"
            Write-Host "    End Time: $($Run.RunEnd)"
            
            if ($Run.RunEnd -and $Run.RunStart) {
                $Duration = $Run.RunEnd - $Run.RunStart
                Write-Host "    Duration: $($Duration.ToString('hh\:mm\:ss'))"
            }
            
            if ($Run.Message) {
                Write-Host "    Message: $($Run.Message)"
            }
            Write-Host "    ---"
        }
    }
} catch {
    Write-Host "  Unable to retrieve pipeline runs: $($_.Exception.Message)"
}

# Get linked services
Write-Host "`nLinked Services:"
try {
    $LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    
    if ($LinkedServices.Count -eq 0) {
        Write-Host "  No linked services found"
    } else {
        foreach ($LinkedService in $LinkedServices) {
            Write-Host "  - Service: $($LinkedService.Name)"
            Write-Host "    Type: $($LinkedService.Properties.Type)"
        }
    }
} catch {
    Write-Host "  Unable to retrieve linked services: $($_.Exception.Message)"
}

# Get datasets
Write-Host "`nDatasets:"
try {
    $Datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    
    if ($Datasets.Count -eq 0) {
        Write-Host "  No datasets found"
    } else {
        foreach ($Dataset in $Datasets) {
            Write-Host "  - Dataset: $($Dataset.Name)"
            Write-Host "    Type: $($Dataset.Properties.Type)"
        }
    }
} catch {
    Write-Host "  Unable to retrieve datasets: $($_.Exception.Message)"
}

# Get triggers
Write-Host "`nTriggers:"
try {
    $Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    
    if ($Triggers.Count -eq 0) {
        Write-Host "  No triggers found"
    } else {
        foreach ($Trigger in $Triggers) {
            Write-Host "  - Trigger: $($Trigger.Name)"
            Write-Host "    Type: $($Trigger.Properties.Type)"
            Write-Host "    State: $($Trigger.Properties.RuntimeState)"
        }
    }
} catch {
    Write-Host "  Unable to retrieve triggers: $($_.Exception.Message)"
}

Write-Host "`nData Factory Portal Access:"
Write-Host "URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName"

Write-Host "`nMonitoring Recommendations:"
Write-Host "1. Review failed pipeline runs for error patterns"
Write-Host "2. Monitor pipeline execution duration trends"
Write-Host "3. Check data movement and transformation performance"
Write-Host "4. Validate trigger schedules and dependencies"
Write-Host "5. Monitor integration runtime utilization"

Write-Host "`nData Factory monitoring completed at $(Get-Date)"

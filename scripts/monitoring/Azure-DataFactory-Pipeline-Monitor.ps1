#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$FactoryName,
    [int]$DaysBack = 7
)
Write-Output "Monitoring Data Factory: $FactoryName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Analysis Period: Last $DaysBack days"
Write-Output "============================================"
$DataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $FactoryName
Write-Output "Data Factory Information:"
Write-Output "Name: $($DataFactory.DataFactoryName)"
Write-Output "Location: $($DataFactory.Location)"
Write-Output "Provisioning State: $($DataFactory.ProvisioningState)"
Write-Output "Created Time: $($DataFactory.CreateTime)"
if ($DataFactory.RepoConfiguration) {
    Write-Output "Git Integration: $($DataFactory.RepoConfiguration.Type)"
    Write-Output "Repository: $($DataFactory.RepoConfiguration.RepositoryName)"
}
Write-Output "`nPipelines:"
$Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
if ($Pipelines.Count -eq 0) {
    Write-Output "No pipelines found"
} else {
    foreach ($Pipeline in $Pipelines) {
        Write-Output "  - Pipeline: $($Pipeline.Name)"
        Write-Output "    Activities: $($Pipeline.Activities.Count)"
        Write-Output "    Parameters: $($Pipeline.Parameters.Count)"
    }
}
$EndTime = Get-Date -ErrorAction Stop
$StartTime = $EndTime.AddDays(-$DaysBack)
Write-Output "`nRecent Pipeline Runs (Last $DaysBack days):"
try {
    $PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
    if ($PipelineRuns.Count -eq 0) {
        Write-Output "No pipeline runs found in the specified period"
    } else {
        $RunSummary = $PipelineRuns | Group-Object Status
        Write-Output "`nPipeline Run Summary:"
        foreach ($Group in $RunSummary) {
            Write-Output "  $($Group.Name): $($Group.Count) runs"
        }
        Write-Output "`nRecent Pipeline Runs:"
        $RecentRuns = $PipelineRuns | Sort-Object RunStart -Descending | Select-Object -First 10
        foreach ($Run in $RecentRuns) {
            Write-Output "  - Pipeline: $($Run.PipelineName)"
            Write-Output "    Run ID: $($Run.RunId)"
            Write-Output "    Status: $($Run.Status)"
            Write-Output "    Start Time: $($Run.RunStart)"
            Write-Output "    End Time: $($Run.RunEnd)"
            if ($Run.RunEnd -and $Run.RunStart) {
                $Duration = $Run.RunEnd - $Run.RunStart
                Write-Output "    Duration: $($Duration.ToString('hh\:mm\:ss'))"
            }
            if ($Run.Message) {
                Write-Output "    Message: $($Run.Message)"
            }
            Write-Output "    ---"
        }
    }
} catch {
    Write-Output "Unable to retrieve pipeline runs: $($_.Exception.Message)"
}
Write-Output "`nLinked Services:"
try {
    $LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($LinkedServices.Count -eq 0) {
        Write-Output "No linked services found"
    } else {
        foreach ($LinkedService in $LinkedServices) {
            Write-Output "  - Service: $($LinkedService.Name)"
            Write-Output "    Type: $($LinkedService.Properties.Type)"
        }
    }
} catch {
    Write-Output "Unable to retrieve linked services: $($_.Exception.Message)"
}
Write-Output "`nDatasets:"
try {
    $Datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($Datasets.Count -eq 0) {
        Write-Output "No datasets found"
    } else {
        foreach ($Dataset in $Datasets) {
            Write-Output "  - Dataset: $($Dataset.Name)"
            Write-Output "    Type: $($Dataset.Properties.Type)"
        }
    }
} catch {
    Write-Output "Unable to retrieve datasets: $($_.Exception.Message)"
}
Write-Output "`nTriggers:"
try {
    $Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($Triggers.Count -eq 0) {
        Write-Output "No triggers found"
    } else {
        foreach ($Trigger in $Triggers) {
            Write-Output "  - Trigger: $($Trigger.Name)"
            Write-Output "    Type: $($Trigger.Properties.Type)"
            Write-Output "    State: $($Trigger.Properties.RuntimeState)"
        }
    }
} catch {
    Write-Output "Unable to retrieve triggers: $($_.Exception.Message)"
}
Write-Output "`nData Factory Portal Access:"
Write-Output "URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName"
Write-Output "`nMonitoring Recommendations:"
Write-Output "1. Review failed pipeline runs for error patterns"
Write-Output "2. Monitor pipeline execution duration trends"
Write-Output "3. Check data movement and transformation performance"
Write-Output "4. Validate trigger schedules and dependencies"
Write-Output "5. Monitor integration runtime utilization"
Write-Output "`nData Factory monitoring completed at $(Get-Date)"




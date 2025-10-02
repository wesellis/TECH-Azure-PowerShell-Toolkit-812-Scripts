#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Datafactory Pipeline Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$FactoryName,
    [int]$DaysBack = 7
)
Write-Output "Monitoring Data Factory: $FactoryName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output "Analysis Period: Last $DaysBack days" "INFO"
Write-Output " ============================================" "INFO"
    [string]$DataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $FactoryName
Write-Output "Data Factory Information:" "INFO"
Write-Output "Name: $($DataFactory.DataFactoryName)" "INFO"
Write-Output "Location: $($DataFactory.Location)" "INFO"
Write-Output "Provisioning State: $($DataFactory.ProvisioningState)" "INFO"
Write-Output "Created Time: $($DataFactory.CreateTime)" "INFO"
if ($DataFactory.RepoConfiguration) {
    Write-Output "Git Integration: $($DataFactory.RepoConfiguration.Type)" "INFO"
    Write-Output "Repository: $($DataFactory.RepoConfiguration.RepositoryName)" "INFO"
}
Write-Output " `nPipelines:" "INFO"
    [string]$Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
if ($Pipelines.Count -eq 0) {
    Write-Output "No pipelines found" "INFO"
} else {
    foreach ($Pipeline in $Pipelines) {
        Write-Output "  - Pipeline: $($Pipeline.Name)" "INFO"
        Write-Output "    Activities: $($Pipeline.Activities.Count)" "INFO"
        Write-Output "    Parameters: $($Pipeline.Parameters.Count)" "INFO"
    }
}
    [string]$EndTime = Get-Date -ErrorAction Stop
    [string]$StartTime = $EndTime.AddDays(-$DaysBack)
Write-Output " `nRecent Pipeline Runs (Last $DaysBack days):" "INFO"
try {
    [string]$PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
    if ($PipelineRuns.Count -eq 0) {
        Write-Output "No pipeline runs found in the specified period" "INFO"
    } else {
    [string]$RunSummary = $PipelineRuns | Group-Object Status
        Write-Output " `nPipeline Run Summary:" "INFO"
        foreach ($Group in $RunSummary) {
            Write-Output "  $($Group.Name): $($Group.Count) runs" "INFO"
        }
        Write-Output " `nRecent Pipeline Runs:" "INFO"
    [string]$RecentRuns = $PipelineRuns | Sort-Object RunStart -Descending | Select-Object -First 10
        foreach ($Run in $RecentRuns) {
            Write-Output "  - Pipeline: $($Run.PipelineName)" "INFO"
            Write-Output "    Run ID: $($Run.RunId)" "INFO"
            Write-Output "    Status: $($Run.Status)" "INFO"
            Write-Output "    Start Time: $($Run.RunStart)" "INFO"
            Write-Output "    End Time: $($Run.RunEnd)" "INFO"
            if ($Run.RunEnd -and $Run.RunStart) {
    [string]$Duration = $Run.RunEnd - $Run.RunStart
                Write-Output "    Duration: $($Duration.ToString('hh\:mm\:ss'))" "INFO"
            }
            if ($Run.Message) {
                Write-Output "    Message: $($Run.Message)" "INFO"
            }
            Write-Output "    ---" "INFO"
        }
    }
} catch {
    Write-Output "Unable to retrieve pipeline runs: $($_.Exception.Message)" "INFO"
}
Write-Output " `nLinked Services:" "INFO"
try {
    [string]$LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($LinkedServices.Count -eq 0) {
        Write-Output "No linked services found" "INFO"
    } else {
        foreach ($LinkedService in $LinkedServices) {
            Write-Output "  - Service: $($LinkedService.Name)" "INFO"
            Write-Output "    Type: $($LinkedService.Properties.Type)" "INFO"
        }
    }
} catch {
    Write-Output "Unable to retrieve linked services: $($_.Exception.Message)" "INFO"
}
Write-Output " `nDatasets:" "INFO"
try {
    [string]$Datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($Datasets.Count -eq 0) {
        Write-Output "No datasets found" "INFO"
    } else {
        foreach ($Dataset in $Datasets) {
            Write-Output "  - Dataset: $($Dataset.Name)" "INFO"
            Write-Output "    Type: $($Dataset.Properties.Type)" "INFO"
        }
    }
} catch {
    Write-Output "Unable to retrieve datasets: $($_.Exception.Message)" "INFO"
}
Write-Output " `nTriggers:" "INFO"
try {
    [string]$Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($Triggers.Count -eq 0) {
        Write-Output "No triggers found" "INFO"
    } else {
        foreach ($Trigger in $Triggers) {
            Write-Output "  - Trigger: $($Trigger.Name)" "INFO"
            Write-Output "    Type: $($Trigger.Properties.Type)" "INFO"
            Write-Output "    State: $($Trigger.Properties.RuntimeState)" "INFO"
        }
    }
} catch {
    Write-Output "Unable to retrieve triggers: $($_.Exception.Message)" "INFO"
}
Write-Output " `nData Factory Portal Access:" "INFO"
Write-Output "URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName" "INFO"
Write-Output " `nMonitoring Recommendations:" "INFO"
Write-Output " 1. Review failed pipeline runs for error patterns" "INFO"
Write-Output " 2. Monitor pipeline execution duration trends" "INFO"
Write-Output " 3. Check data movement and transformation performance" "INFO"
Write-Output " 4. Validate trigger schedules and dependencies" "INFO"
Write-Output " 5. Monitor integration runtime utilization" "INFO"
Write-Output " `nData Factory monitoring completed at $(Get-Date)" "INFO"




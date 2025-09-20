#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Datafactory Pipeline Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$FactoryName,
    [int]$DaysBack = 7
)
Write-Host "Monitoring Data Factory: $FactoryName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Analysis Period: Last $DaysBack days" "INFO"
Write-Host " ============================================" "INFO"
$DataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $FactoryName
Write-Host "Data Factory Information:" "INFO"
Write-Host "Name: $($DataFactory.DataFactoryName)" "INFO"
Write-Host "Location: $($DataFactory.Location)" "INFO"
Write-Host "Provisioning State: $($DataFactory.ProvisioningState)" "INFO"
Write-Host "Created Time: $($DataFactory.CreateTime)" "INFO"
if ($DataFactory.RepoConfiguration) {
    Write-Host "Git Integration: $($DataFactory.RepoConfiguration.Type)" "INFO"
    Write-Host "Repository: $($DataFactory.RepoConfiguration.RepositoryName)" "INFO"
}
Write-Host " `nPipelines:" "INFO"
$Pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
if ($Pipelines.Count -eq 0) {
    Write-Host "No pipelines found" "INFO"
} else {
    foreach ($Pipeline in $Pipelines) {
        Write-Host "  - Pipeline: $($Pipeline.Name)" "INFO"
        Write-Host "    Activities: $($Pipeline.Activities.Count)" "INFO"
        Write-Host "    Parameters: $($Pipeline.Parameters.Count)" "INFO"
    }
}
$EndTime = Get-Date -ErrorAction Stop
$StartTime = $EndTime.AddDays(-$DaysBack)
Write-Host " `nRecent Pipeline Runs (Last $DaysBack days):" "INFO"
try {
    $PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
    if ($PipelineRuns.Count -eq 0) {
        Write-Host "No pipeline runs found in the specified period" "INFO"
    } else {
        # Group by status for summary
        $RunSummary = $PipelineRuns | Group-Object Status
        Write-Host " `nPipeline Run Summary:" "INFO"
        foreach ($Group in $RunSummary) {
            Write-Host "  $($Group.Name): $($Group.Count) runs" "INFO"
        }
        # Show recent runs
        Write-Host " `nRecent Pipeline Runs:" "INFO"
        $RecentRuns = $PipelineRuns | Sort-Object RunStart -Descending | Select-Object -First 10
        foreach ($Run in $RecentRuns) {
            Write-Host "  - Pipeline: $($Run.PipelineName)" "INFO"
            Write-Host "    Run ID: $($Run.RunId)" "INFO"
            Write-Host "    Status: $($Run.Status)" "INFO"
            Write-Host "    Start Time: $($Run.RunStart)" "INFO"
            Write-Host "    End Time: $($Run.RunEnd)" "INFO"
            if ($Run.RunEnd -and $Run.RunStart) {
                $Duration = $Run.RunEnd - $Run.RunStart
                Write-Host "    Duration: $($Duration.ToString('hh\:mm\:ss'))" "INFO"
            }
            if ($Run.Message) {
                Write-Host "    Message: $($Run.Message)" "INFO"
            }
            Write-Host "    ---" "INFO"
        }
    }
} catch {
    Write-Host "Unable to retrieve pipeline runs: $($_.Exception.Message)" "INFO"
}
Write-Host " `nLinked Services:" "INFO"
try {
    $LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($LinkedServices.Count -eq 0) {
        Write-Host "No linked services found" "INFO"
    } else {
        foreach ($LinkedService in $LinkedServices) {
            Write-Host "  - Service: $($LinkedService.Name)" "INFO"
            Write-Host "    Type: $($LinkedService.Properties.Type)" "INFO"
        }
    }
} catch {
    Write-Host "Unable to retrieve linked services: $($_.Exception.Message)" "INFO"
}
Write-Host " `nDatasets:" "INFO"
try {
$Datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($Datasets.Count -eq 0) {
        Write-Host "No datasets found" "INFO"
    } else {
        foreach ($Dataset in $Datasets) {
            Write-Host "  - Dataset: $($Dataset.Name)" "INFO"
            Write-Host "    Type: $($Dataset.Properties.Type)" "INFO"
        }
    }
} catch {
    Write-Host "Unable to retrieve datasets: $($_.Exception.Message)" "INFO"
}
Write-Host " `nTriggers:" "INFO"
try {
$Triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $FactoryName
    if ($Triggers.Count -eq 0) {
        Write-Host "No triggers found" "INFO"
    } else {
        foreach ($Trigger in $Triggers) {
            Write-Host "  - Trigger: $($Trigger.Name)" "INFO"
            Write-Host "    Type: $($Trigger.Properties.Type)" "INFO"
            Write-Host "    State: $($Trigger.Properties.RuntimeState)" "INFO"
        }
    }
} catch {
    Write-Host "Unable to retrieve triggers: $($_.Exception.Message)" "INFO"
}
Write-Host " `nData Factory Portal Access:" "INFO"
Write-Host "URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName" "INFO"
Write-Host " `nMonitoring Recommendations:" "INFO"
Write-Host " 1. Review failed pipeline runs for error patterns" "INFO"
Write-Host " 2. Monitor pipeline execution duration trends" "INFO"
Write-Host " 3. Check data movement and transformation performance" "INFO"
Write-Host " 4. Validate trigger schedules and dependencies" "INFO"
Write-Host " 5. Monitor integration runtime utilization" "INFO"
Write-Host " `nData Factory monitoring completed at $(Get-Date)" "INFO"



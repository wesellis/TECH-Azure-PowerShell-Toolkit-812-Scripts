<#
.SYNOPSIS
    Azure Datafactory Pipeline Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Datafactory Pipeline Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEFactoryName,
    [int]$WEDaysBack = 7
)

Write-WELog " Monitoring Data Factory: $WEFactoryName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Analysis Period: Last $WEDaysBack days" " INFO"
Write-WELog " ============================================" " INFO"


$WEDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $WEResourceGroupName -Name $WEFactoryName

Write-WELog " Data Factory Information:" " INFO"
Write-WELog "  Name: $($WEDataFactory.DataFactoryName)" " INFO"
Write-WELog "  Location: $($WEDataFactory.Location)" " INFO"
Write-WELog "  Provisioning State: $($WEDataFactory.ProvisioningState)" " INFO"
Write-WELog "  Created Time: $($WEDataFactory.CreateTime)" " INFO"

if ($WEDataFactory.RepoConfiguration) {
    Write-WELog "  Git Integration: $($WEDataFactory.RepoConfiguration.Type)" " INFO"
    Write-WELog "  Repository: $($WEDataFactory.RepoConfiguration.RepositoryName)" " INFO"
}


Write-WELog " `nPipelines:" " INFO"
$WEPipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEFactoryName

if ($WEPipelines.Count -eq 0) {
    Write-WELog "  No pipelines found" " INFO"
} else {
    foreach ($WEPipeline in $WEPipelines) {
        Write-WELog "  - Pipeline: $($WEPipeline.Name)" " INFO"
        Write-WELog "    Activities: $($WEPipeline.Activities.Count)" " INFO"
        Write-WELog "    Parameters: $($WEPipeline.Parameters.Count)" " INFO"
    }
}


$WEEndTime = Get-Date
$WEStartTime = $WEEndTime.AddDays(-$WEDaysBack)

Write-WELog " `nRecent Pipeline Runs (Last $WEDaysBack days):" " INFO"
try {
    $WEPipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEFactoryName -LastUpdatedAfter $WEStartTime -LastUpdatedBefore $WEEndTime
    
    if ($WEPipelineRuns.Count -eq 0) {
        Write-WELog "  No pipeline runs found in the specified period" " INFO"
    } else {
        # Group by status for summary
        $WERunSummary = $WEPipelineRuns | Group-Object Status
        Write-WELog " `nPipeline Run Summary:" " INFO"
        foreach ($WEGroup in $WERunSummary) {
            Write-WELog "  $($WEGroup.Name): $($WEGroup.Count) runs" " INFO"
        }
        
        # Show recent runs
        Write-WELog " `nRecent Pipeline Runs:" " INFO"
        $WERecentRuns = $WEPipelineRuns | Sort-Object RunStart -Descending | Select-Object -First 10
        
        foreach ($WERun in $WERecentRuns) {
            Write-WELog "  - Pipeline: $($WERun.PipelineName)" " INFO"
            Write-WELog "    Run ID: $($WERun.RunId)" " INFO"
            Write-WELog "    Status: $($WERun.Status)" " INFO"
            Write-WELog "    Start Time: $($WERun.RunStart)" " INFO"
            Write-WELog "    End Time: $($WERun.RunEnd)" " INFO"
            
            if ($WERun.RunEnd -and $WERun.RunStart) {
                $WEDuration = $WERun.RunEnd - $WERun.RunStart
                Write-WELog "    Duration: $($WEDuration.ToString('hh\:mm\:ss'))" " INFO"
            }
            
            if ($WERun.Message) {
                Write-WELog "    Message: $($WERun.Message)" " INFO"
            }
            Write-WELog "    ---" " INFO"
        }
    }
} catch {
    Write-WELog "  Unable to retrieve pipeline runs: $($_.Exception.Message)" " INFO"
}


Write-WELog " `nLinked Services:" " INFO"
try {
    $WELinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEFactoryName
    
    if ($WELinkedServices.Count -eq 0) {
        Write-WELog "  No linked services found" " INFO"
    } else {
        foreach ($WELinkedService in $WELinkedServices) {
            Write-WELog "  - Service: $($WELinkedService.Name)" " INFO"
            Write-WELog "    Type: $($WELinkedService.Properties.Type)" " INFO"
        }
    }
} catch {
    Write-WELog "  Unable to retrieve linked services: $($_.Exception.Message)" " INFO"
}


Write-WELog " `nDatasets:" " INFO"
try {
   ;  $WEDatasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEFactoryName
    
    if ($WEDatasets.Count -eq 0) {
        Write-WELog "  No datasets found" " INFO"
    } else {
        foreach ($WEDataset in $WEDatasets) {
            Write-WELog "  - Dataset: $($WEDataset.Name)" " INFO"
            Write-WELog "    Type: $($WEDataset.Properties.Type)" " INFO"
        }
    }
} catch {
    Write-WELog "  Unable to retrieve datasets: $($_.Exception.Message)" " INFO"
}


Write-WELog " `nTriggers:" " INFO"
try {
   ;  $WETriggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEFactoryName
    
    if ($WETriggers.Count -eq 0) {
        Write-WELog "  No triggers found" " INFO"
    } else {
        foreach ($WETrigger in $WETriggers) {
            Write-WELog "  - Trigger: $($WETrigger.Name)" " INFO"
            Write-WELog "    Type: $($WETrigger.Properties.Type)" " INFO"
            Write-WELog "    State: $($WETrigger.Properties.RuntimeState)" " INFO"
        }
    }
} catch {
    Write-WELog "  Unable to retrieve triggers: $($_.Exception.Message)" " INFO"
}

Write-WELog " `nData Factory Portal Access:" " INFO"
Write-WELog " URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$WEResourceGroupName/providers/Microsoft.DataFactory/factories/$WEFactoryName" " INFO"

Write-WELog " `nMonitoring Recommendations:" " INFO"
Write-WELog " 1. Review failed pipeline runs for error patterns" " INFO"
Write-WELog " 2. Monitor pipeline execution duration trends" " INFO"
Write-WELog " 3. Check data movement and transformation performance" " INFO"
Write-WELog " 4. Validate trigger schedules and dependencies" " INFO"
Write-WELog " 5. Monitor integration runtime utilization" " INFO"

Write-WELog " `nData Factory monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
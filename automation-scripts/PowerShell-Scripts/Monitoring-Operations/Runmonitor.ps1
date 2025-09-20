<#
.SYNOPSIS
    Runmonitor

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
Use this script to execute a single activity run from your new ADF V2 pipeline generated from the Azure quickstart template gallery
Execute pipeline 1x and also monitor the status
adfv2runmonitor.ps1 -resourceGroupName "adfv2" -DataFactoryName "ADFTutorialFactory09272dttm2p5xspjxy"
Required params: -resourceGroupName -DataFactoryName
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
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
    [string] $resourceGroupName,
    [string] $DataFactoryName
)
if(-not($resourceGroupName)) { Throw "You must supply a value for -resourceGroupName" }
if(-not($DataFactoryName)) { Throw "You must supply a value for -DataFactoryName" }
$runId = Invoke-AzureRmDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $resourceGroupName -PipelineName "ArmtemplateSampleCopyPipeline"
while ($True) {;
$run = Get-AzureRmDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $runId
if ($run) {
if ($run.Status -ne 'InProgress') {
Write-Host "Pipeline run finished. The status is: " "INFO" $run.Status -foregroundcolor "Yellow"
$run
break
}
Write-Host "Pipeline is running...status: InProgress" "INFO" -foregroundcolor "Yellow"
}
Start-Sleep -Seconds 20
}
Write-Host "Activity run details:" "INFO" -foregroundcolor "Yellow" ;
$result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $DataFactoryName -ResourceGroupName $resourceGroupName -PipelineRunId $runId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)
$result
Write-Host "Activity 'Output' section:" "INFO" -foregroundcolor "Yellow"
$result.Output -join " `r`n"
Write-Host " \nActivity 'Error' section:" "INFO" -foregroundcolor "Yellow"
$result.Error -join " `r`n"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


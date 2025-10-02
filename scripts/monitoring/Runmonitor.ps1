#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Runmonitor

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Use this script to execute a single activity run from your new ADF V2 pipeline generated from the Azure quickstart template gallery
Execute pipeline 1x and also monitor the status
adfv2runmonitor.ps1 -resourceGroupName "adfv2" -DataFactoryName "ADFTutorialFactory09272dttm2p5xspjxy"
Required params: -resourceGroupName -DataFactoryName
function Write-Host {
    [string]$ErrorActionPreference = "Stop"
[CmdletBinding()]
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
    [string] $ResourceGroupName,
    [string] $DataFactoryName
)
if(-not($ResourceGroupName)) { Throw "You must supply a value for -resourceGroupName" }
if(-not($DataFactoryName)) { Throw "You must supply a value for -DataFactoryName" }
    [string]$RunId = Invoke-AzureRmDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -PipelineName "ArmtemplateSampleCopyPipeline"
while ($True) {;
    [string]$run = Get-AzureRmDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $RunId
if ($run) {
if ($run.Status -ne 'InProgress') {
Write-Output "Pipeline run finished. The status is: " "INFO" $run.Status -foregroundcolor "Yellow"
    [string]$run
break
}
Write-Output "Pipeline is running...status: InProgress" "INFO" -foregroundcolor "Yellow"
}
Start-Sleep -Seconds 20
}
Write-Output "Activity run details:" "INFO" -foregroundcolor "Yellow" ;
    [string]$result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -PipelineRunId $RunId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)
    [string]$result
Write-Output "Activity 'Output' section:" "INFO" -foregroundcolor "Yellow"
    [string]$result.Output -join " `r`n"
Write-Host "
Activity 'Error' section:" "INFO" -foregroundcolor "Yellow"
    [string]$result.Error -join " `r`n"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

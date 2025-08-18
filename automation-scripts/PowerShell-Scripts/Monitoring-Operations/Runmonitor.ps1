<#
.SYNOPSIS
    Runmonitor

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
    We Enhanced Runmonitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

.SYNOPSIS
Use this script to execute a single activity run from your new ADF V2 pipeline generated from the Azure quickstart template gallery

.DESCRIPTION
Execute pipeline 1x and also monitor the status

.EXAMPLE
adfv2runmonitor.ps1 -resourceGroupName "adfv2" -DataFactoryName " ADFTutorialFactory09272dttm2p5xspjxy"

.NOTES
Required params: -resourceGroupName -DataFactoryName





[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()
try {
    # Main script execution
]
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [string] $resourceGroupName,
    [string] $WEDataFactoryName
)

if(-not($resourceGroupName)) { Throw " You must supply a value for -resourceGroupName" }
if(-not($WEDataFactoryName)) { Throw " You must supply a value for -DataFactoryName" }

$runId = Invoke-AzureRmDataFactoryV2Pipeline -DataFactoryName $WEDataFactoryName -ResourceGroupName $resourceGroupName -PipelineName " ArmtemplateSampleCopyPipeline"

while ($WETrue) {; 
$run = Get-AzureRmDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $WEDataFactoryName -PipelineRunId $runId
if ($run) {
if ($run.Status -ne 'InProgress') {
Write-WELog " Pipeline run finished. The status is: " " INFO" $run.Status -foregroundcolor " Yellow"
$run
break
}
Write-WELog " Pipeline is running...status: InProgress" " INFO" -foregroundcolor " Yellow"
}
Start-Sleep -Seconds 20
}



Write-WELog " Activity run details:" " INFO" -foregroundcolor " Yellow" ; 
$result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $WEDataFactoryName -ResourceGroupName $resourceGroupName -PipelineRunId $runId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)
$result

Write-WELog " Activity 'Output' section:" " INFO" -foregroundcolor " Yellow"
$result.Output -join " `r`n"

Write-WELog " \nActivity 'Error' section:" " INFO" -foregroundcolor " Yellow"
$result.Error -join " `r`n"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

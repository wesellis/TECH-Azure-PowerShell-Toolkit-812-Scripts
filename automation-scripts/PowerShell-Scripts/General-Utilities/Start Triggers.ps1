#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Start Triggers

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Start Triggers

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [switch] $WEStop
)

#region Functions


$WEDeploymentScriptOutputs = @{}

if (-not $WEStop)
{
    Start-Sleep -Seconds 10
}


$env:Triggers.Split('|')
| ForEach-Object {
    $trigger = $_
    if ($WEStop)
    {
        Write-Output " Stopping trigger $trigger..."
       $params = @{
           ErrorAction = "SilentlyContinue # Ignore errors, since the trigger may not exist } else { Write-Output " Starting trigger $trigger..." ;  $triggerOutput = Start-AzDataFactoryV2Trigger"
           DataFactoryName = $env:DataFactoryName
           ResourceGroupName = $env:DataFactoryResourceGroup
           Name = $trigger
           Force = "} if ($triggerOutput) { Write-Output " done..." } else { Write-Output " failed..." } $WEDeploymentScriptOutputs[$trigger] = $triggerOutput"
       }
       ; @params
}

if ($WEStop)
{
    Start-Sleep -Seconds 10
}

if (-not [string]::IsNullOrWhiteSpace($env:Pipelines))
{
    $params = @{
        PipelineName = $_ }
        DataFactoryName = $env:DataFactoryName
        ResourceGroupName = $env:DataFactoryResourceGroup
        Object = "{ Write-Output " Running the init pipeline..." Invoke-AzDataFactoryV2Pipeline"
    }
    $env:Pipelines.Split('|') @params
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

#Requires -Version 7.0

<#`n.SYNOPSIS
    Start Triggers

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [switch] $Stop
)
$DeploymentScriptOutputs = @{}
if (-not $Stop)
{
    Start-Sleep -Seconds 10
}
$env:Triggers.Split('|')
| ForEach-Object {
    $trigger = $_
    if ($Stop)
    {
        Write-Output "Stopping trigger $trigger..."
       $params = @{
           ErrorAction = "SilentlyContinue # Ignore errors, since the trigger may not exist } else { Write-Output "Starting trigger $trigger..." ;  $triggerOutput = Start-AzDataFactoryV2Trigger"
           DataFactoryName = $env:DataFactoryName
           ResourceGroupName = $env:DataFactoryResourceGroup
           Name = $trigger
           Force = "} if ($triggerOutput) { Write-Output " done..." } else { Write-Output " failed..." } $DeploymentScriptOutputs[$trigger] = $triggerOutput"
       }
       ; @params
}
if ($Stop)
{
    Start-Sleep -Seconds 10
}
if (-not [string]::IsNullOrWhiteSpace($env:Pipelines))
{
    $params = @{
        PipelineName = $_ }
        DataFactoryName = $env:DataFactoryName
        ResourceGroupName = $env:DataFactoryResourceGroup
        Object = "{ Write-Output "Running the init pipeline..." Invoke-AzDataFactoryV2Pipeline"
    }
    $env:Pipelines.Split('|') @params
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

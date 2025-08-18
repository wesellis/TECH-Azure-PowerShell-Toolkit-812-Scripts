<#
.SYNOPSIS
    Start Triggers

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
    We Enhanced Start Triggers

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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


$WEDeploymentScriptOutputs = @{}

if (-not $WEStop)
{
    Start-Sleep -Seconds 10
}


$env:Triggers.Split('|') `
| ForEach-Object {
    $trigger = $_
    if ($WEStop)
    {
        Write-Output " Stopping trigger $trigger..."
       ;  $triggerOutput = Stop-AzDataFactoryV2Trigger `
            -ResourceGroupName $env:DataFactoryResourceGroup `
            -DataFactoryName $env:DataFactoryName `
            -Name $trigger `
            -Force `
            -ErrorAction SilentlyContinue # Ignore errors, since the trigger may not exist
    }
    else
    {
        Write-Output " Starting trigger $trigger..."
       ;  $triggerOutput = Start-AzDataFactoryV2Trigger `
            -ResourceGroupName $env:DataFactoryResourceGroup `
            -DataFactoryName $env:DataFactoryName `
            -Name $trigger `
            -Force
    }
    if ($triggerOutput)
    {
        Write-Output " done..."
    }
    else
    {
        Write-Output " failed..."
    }
    $WEDeploymentScriptOutputs[$trigger] = $triggerOutput
}

if ($WEStop)
{
    Start-Sleep -Seconds 10
}

if (-not [string]::IsNullOrWhiteSpace($env:Pipelines))
{
    $env:Pipelines.Split('|') `
    | ForEach-Object {
        Write-Output " Running the init pipeline..."
        Invoke-AzDataFactoryV2Pipeline `
            -ResourceGroupName $env:DataFactoryResourceGroup `
            -DataFactoryName $env:DataFactoryName `
            -PipelineName $_
    }
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

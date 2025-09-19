#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Remove Oldresources

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
    We Enhanced Remove Oldresources

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEDeploymentScriptOutputs = @{}

; 
$adfParams = @{
    ResourceGroupName = $env:DataFactoryResourceGroup
    DataFactoryName   = $env:DataFactoryName
}

; 
$triggers -ErrorAction "SilentlyContinue"
| Where-Object { $_.Name -match '^msexports(_(setup|daily|monthly|extract|FileAdded))?$' }
$WEDeploymentScriptOutputs["stopTriggers" ] = $triggers | Stop-AzDataFactoryV2Trigger -Force -ErrorAction SilentlyContinue
$WEDeploymentScriptOutputs[" deleteTriggers" ] = $triggers | Remove-AzDataFactoryV2Trigger -Force -ErrorAction SilentlyContinue


$WEDeploymentScriptOutputs[" -ErrorAction "SilentlyContinue"
| -match "^(msexports_(backfill|extract|fill|get|run|setup|transform)|config_(BackfillData|ExportData|RunBackfill|RunExports))$' }" -Object "{ $_.Name"
| Remove-AzDataFactoryV2Pipeline -Force -ErrorAction SilentlyContinue


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

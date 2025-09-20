<#
.SYNOPSIS
    Remove Oldresources

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$DeploymentScriptOutputs = @{}
$adfParams = @{
    ResourceGroupName = $env:DataFactoryResourceGroup
    DataFactoryName   = $env:DataFactoryName
}
$triggers -ErrorAction "SilentlyContinue"
| Where-Object { $_.Name -match '^msexports(_(setup|daily|monthly|extract|FileAdded))?$' }
$DeploymentScriptOutputs["stopTriggers" ] = $triggers | Stop-AzDataFactoryV2Trigger -Force -ErrorAction SilentlyContinue
$DeploymentScriptOutputs[" deleteTriggers" ] = $triggers | Remove-AzDataFactoryV2Trigger -Force -ErrorAction SilentlyContinue
$DeploymentScriptOutputs[" -ErrorAction "SilentlyContinue"
| -match "^(msexports_(backfill|extract|fill|get|run|setup|transform)|config_(BackfillData|ExportData|RunBackfill|RunExports))$' }" -Object "{ $_.Name"
| Remove-AzDataFactoryV2Pipeline -Force -ErrorAction SilentlyContinue\n
#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Appservice Scaling Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PlanName,
    [int]$InstanceCount
)
Set-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -NumberofWorkers $InstanceCount
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n


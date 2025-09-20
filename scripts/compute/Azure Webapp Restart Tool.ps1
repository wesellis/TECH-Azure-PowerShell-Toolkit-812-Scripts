#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Webapp Restart Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
    [string]$AppName
)
Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Vm Restart Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop" ;
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$VmName
)
Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

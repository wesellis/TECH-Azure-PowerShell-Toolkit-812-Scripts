#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Vm Shutdown Tool

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
Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

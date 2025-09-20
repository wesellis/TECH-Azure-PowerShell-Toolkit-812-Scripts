#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Vm Restore Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [string]$RestorePoint
)
Restore-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName -RestorePoint $RestorePoint
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

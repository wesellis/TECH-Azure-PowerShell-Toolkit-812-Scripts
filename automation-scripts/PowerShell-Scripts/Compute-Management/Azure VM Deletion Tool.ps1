<#
.SYNOPSIS
    Azure Vm Deletion Tool

.DESCRIPTION
    Azure automation
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
    [string]$VmName
)
Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


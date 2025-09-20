#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Vm Backup Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
    [string]$VmName
)
Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

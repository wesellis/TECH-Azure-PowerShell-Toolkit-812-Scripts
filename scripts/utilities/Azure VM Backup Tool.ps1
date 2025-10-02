#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Vm Backup Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $VaultName,
    $VmName
)
Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}



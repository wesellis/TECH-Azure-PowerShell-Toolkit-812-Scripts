#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Get Azure Recovery Services backup protection policy

.DESCRIPTION
    Get Azure Recovery Services backup protection policy operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateSet('AzureVM', 'WindowsServer', 'AzureFiles', 'MSSQL')]
    [string]$WorkloadType
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction Stop

$getAzRecoveryServicesBackupProtectionPolicySplat = @{
    VaultId = $targetVault.ID
}

if ($WorkloadType) {
    $getAzRecoveryServicesBackupProtectionPolicySplat.WorkloadType = $WorkloadType
}

Get-AzRecoveryServicesBackupProtectionPolicy @getAzRecoveryServicesBackupProtectionPolicySplat -ErrorAction Stop
#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Enable Azure Recovery Services backup protection

.DESCRIPTION
    Enable Azure Recovery Services backup protection operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [string]$VaultResourceGroupName,

    [Parameter()]
    [string]$PolicyName = "DefaultPolicy"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultResourceGroupName -Name $VaultName -ErrorAction Stop

$getAzRecoveryServicesBackupProtectionPolicySplat = @{
    Name = $PolicyName
    VaultId = $targetVault.ID
}

$policy = Get-AzRecoveryServicesBackupProtectionPolicy @getAzRecoveryServicesBackupProtectionPolicySplat -ErrorAction Stop

$enableAzRecoveryServicesBackupProtectionSplat = @{
    Policy = $policy
    Name = $VMName
    ResourceGroupName = $ResourceGroupName
    VaultId = $targetVault.ID
}

Enable-AzRecoveryServicesBackupProtection @enableAzRecoveryServicesBackupProtectionSplat -ErrorAction Stop
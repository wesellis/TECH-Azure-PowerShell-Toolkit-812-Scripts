#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Set Azure Recovery Services backup property

.DESCRIPTION
    Set Azure Recovery Services backup property operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Storage Redundancy can be modified only if there are no backup items protected to the vault.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('GeoRedundant', 'LocallyRedundant')]
    [string]$BackupStorageRedundancy = 'GeoRedundant'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction Stop

$setAzRecoveryServicesBackupPropertySplat = @{
    Vault = $vault
    BackupStorageRedundancy = $BackupStorageRedundancy
}

Set-AzRecoveryServicesBackupProperty @setAzRecoveryServicesBackupPropertySplat -ErrorAction Stop




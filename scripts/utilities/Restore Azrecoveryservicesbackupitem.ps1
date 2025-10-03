#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Restore Azrecoveryservicesbackupitem

.DESCRIPTION
    Restore Azrecoveryservicesbackupitem operation
    Restores the data and configuration for a Backup item to the specified recovery point.

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName,

    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName = "outlook1restoredsa",

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountResourceGroupName = "CanPrintEquip_Outlook1Restored_RG",

    [Parameter(Mandatory = $true)]
    [string]$TargetResourceGroupName = "CanPrintEquip_Outlook1Restored_RG",

    [Parameter()]
    [int]$RecoveryPointIndex = 0
)

$ErrorActionPreference = 'Stop'

$ResourceGroupName = -join ("$CustomerName" , "_$VMName" , "_RG" )
$Vaultname = -join ("$VMName" , "ARSV1" )

$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
$targetVault = Get-AzRecoveryServicesVault @getAzRecoveryServicesVaultSplat

$getAzRecoveryServicesBackupContainerSplat = @{
    ContainerType = "AzureVM"
    Status = "Registered"
    FriendlyName = $VMName
    VaultId = $targetVault.ID
}
$namedContainer = Get-AzRecoveryServicesBackupContainer @getAzRecoveryServicesBackupContainerSplat

$getAzRecoveryServicesBackupItemSplat = @{
    Container = $namedContainer
    WorkloadType = "AzureVM"
    VaultId = $targetVault.ID
}
$backupitem = Get-AzRecoveryServicesBackupItem @getAzRecoveryServicesBackupItemSplat

$getAzRecoveryServicesBackupRecoveryPointSplat = @{
    Item = $backupitem
    VaultId = $targetVault.ID
}
$rp = Get-AzRecoveryServicesBackupRecoveryPoint @getAzRecoveryServicesBackupRecoveryPointSplat

if ($rp.Count -eq 0) {
    Write-Error "No recovery points found for the backup item"
    return
}

$restoreAzRecoveryServicesBackupItemSplat = @{
    RecoveryPoint = $rp[$RecoveryPointIndex]
    StorageAccountName = $StorageAccountName
    StorageAccountResourceGroupName = $StorageAccountResourceGroupName
    TargetResourceGroupName = $TargetResourceGroupName
    VaultId = $targetVault.ID
    VaultLocation = $targetVault.Location
}
$restorejob = Restore-AzRecoveryServicesBackupItem @restoreAzRecoveryServicesBackupItemSplat
$restorejob
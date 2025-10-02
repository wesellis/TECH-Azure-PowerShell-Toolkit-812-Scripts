#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get recoveryservicesbackuprecoverypoint

.DESCRIPTION
    Get recoveryservicesbackuprecoverypoint operation

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

    [Parameter()]
    [int]$DaysBack = 7
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

$startDate = (Get-Date).AddDays(-$DaysBack)
$endDate = Get-Date

$getAzRecoveryServicesBackupRecoveryPointSplat = @{
    Item = $backupitem
    StartDate = $startDate.ToUniversalTime()
    EndDate = $endDate.ToUniversalTime()
    VaultId = $targetVault.ID
}
$rp = Get-AzRecoveryServicesBackupRecoveryPoint -ErrorAction Stop @getAzRecoveryServicesBackupRecoveryPointSplat
$rp
#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get recoveryservicesbackupitem

.DESCRIPTION
    Get recoveryservicesbackupitem operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName = 'CanPrintEquip',

    [Parameter(Mandatory = $true)]
    [string]$VMName = 'Outlook1'
)

$ErrorActionPreference = 'Stop'

$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join ("$VMName" , "ARSV1" )
$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
$targetVault = Get-AzRecoveryServicesVault -ErrorAction Stop @getAzRecoveryServicesVaultSplat

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
$backupitem = Get-AzRecoveryServicesBackupItem -ErrorAction Stop @getAzRecoveryServicesBackupItemSplat
$backupitem
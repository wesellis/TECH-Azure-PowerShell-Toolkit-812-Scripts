<#
.SYNOPSIS
    Backup Azure Recovery Services backup item

.DESCRIPTION
    Trigger a backup job for Azure VM using Recovery Services
.EXAMPLE
    PS C:\> .\"10 Backup Azrecoveryservicesbackupitem.ps1"
    Triggers a backup for the configured VM
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    LastModified: 2025-09-19
    Requires appropriate permissions and modules
#>
Use Backup-AzRecoveryServicesBackupItem to trigger a backup job. If it's the initial backup, it is a full backup. Subsequent backups take an incremental copy. The following example takes a VM backup to be retained for 60 days.
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $Vaultname
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
$item = Get-AzRecoveryServicesBackupItem @getAzRecoveryServicesBackupItemSplat
$endDate = (Get-Date).AddDays(60).ToUniversalTime()
$backupAzRecoveryServicesBackupItemSplat = @{
    Item = $item
    VaultId = $targetVault.ID
    ExpiryDateTimeUTC = $endDate
}
$job = Backup-AzRecoveryServicesBackupItem @backupAzRecoveryServicesBackupItemSplat


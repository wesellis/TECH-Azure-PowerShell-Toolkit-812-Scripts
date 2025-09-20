<#
.SYNOPSIS
    Restore Azrecoveryservicesbackupitem

.DESCRIPTION
    Restore Azrecoveryservicesbackupitem operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
    # Use the Restore-AzRecoveryServicesBackupItem cmdlet to restore a backup item's data and configuration to a recovery point. Once you identify a recovery point, use it as the value for the -RecoveryPoint parameter. In the sample above, $rp[0] was the recovery point to use. In the following sample code, $rp[0] is the recovery point to use for restoring the disk.
    Restores the data and configuration for a Backup item to the specified recovery point. The required parameters vary with the backup item type. The same command is used to restore Azure Virtual machines, databases running within Azure Virtual machines and Azure file shares as well.
$StorageAccountName = "outlook1restoredsa"
$StorageAccountResourceGroupName = "CanPrintEquip_Outlook1Restored_RG"
$TargetResourceGroupName = "CanPrintEquip_Outlook1Restored_RG"
$restoreAzRecoveryServicesBackupItemSplat = @{
    RecoveryPoint = $rp[0]
    StorageAccountName = $StorageAccountName
    StorageAccountResourceGroupName = $StorageAccountResourceGroupName
    TargetResourceGroupName = $TargetResourceGroupName
    VaultId = $targetVault.ID
    VaultLocation = $targetVault.Location
}
$restorejob = Restore-AzRecoveryServicesBackupItem @restoreAzRecoveryServicesBackupItemSplat
$restorejob
    # WorkloadName    Operation       Status          StartTime              EndTime
    # ------------    ---------       ------          ---------              -------
    # V2VM            Restore         InProgress      26-Apr-16 1:14:01 PM   01-Jan-01 12:00:00 AM


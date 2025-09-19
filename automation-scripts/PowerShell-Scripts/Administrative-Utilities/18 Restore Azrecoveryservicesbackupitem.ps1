#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    18 Restore Azrecoveryservicesbackupitem

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 18 Restore Azrecoveryservicesbackupitem

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes

    # Use the Restore-AzRecoveryServicesBackupItem cmdlet to restore a backup item's data and configuration to a recovery point. Once you identify a recovery point, use it as the value for the -RecoveryPoint parameter. In the sample above, $rp[0] was the recovery point to use. In the following sample code, $rp[0] is the recovery point to use for restoring the disk.

    Restores the data and configuration for a Backup item to the specified recovery point. The required parameters vary with the backup item type. The same command is used to restore Azure Virtual machines, databases running within Azure Virtual machines and Azure file shares as well.











$WEStorageAccountName = "outlook1restoredsa"
$WEStorageAccountResourceGroupName = " CanPrintEquip_Outlook1Restored_RG"
$WETargetResourceGroupName = " CanPrintEquip_Outlook1Restored_RG"

; 
$restoreAzRecoveryServicesBackupItemSplat = @{
    RecoveryPoint = $rp[0]
    StorageAccountName = $WEStorageAccountName
    StorageAccountResourceGroupName = $WEStorageAccountResourceGroupName
    TargetResourceGroupName = $WETargetResourceGroupName
    VaultId = $targetVault.ID
    VaultLocation = $targetVault.Location
}
; 
$restorejob = Restore-AzRecoveryServicesBackupItem @restoreAzRecoveryServicesBackupItemSplat
$restorejob


    # WorkloadName    Operation       Status          StartTime              EndTime
    # ------------    ---------       ------          ---------              -------
    # V2VM            Restore         InProgress      26-Apr-16 1:14:01 PM   01-Jan-01 12:00:00 AM

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

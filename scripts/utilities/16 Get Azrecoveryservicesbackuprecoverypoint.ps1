#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Get recoveryservicesbackuprecoverypoint

.DESCRIPTION
    Get recoveryservicesbackuprecoverypoint operation
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
    RecoveryPointId    RecoveryPointType  RecoveryPointTime      ContainerName                        ContainerType
---------------    -----------------  -----------------      -------------                        -------------
630969556710589... CrashConsistent    2020-12-12 11:18:41 PM iaasvmcontainerv2;canprintequip_o... AzureVM
$startDate = (Get-Date).AddDays(-7)
$endDate = Get-Date;
$getAzRecoveryServicesBackupRecoveryPointSplat = @{
    Item = $backupitem
    StartDate = $startdate.ToUniversalTime()
    EndDate = $enddate.ToUniversalTime()
    VaultId = $targetVault.ID
}
$rp = Get-AzRecoveryServicesBackupRecoveryPoint -ErrorAction Stop @getAzRecoveryServicesBackupRecoveryPointSplat
$rp


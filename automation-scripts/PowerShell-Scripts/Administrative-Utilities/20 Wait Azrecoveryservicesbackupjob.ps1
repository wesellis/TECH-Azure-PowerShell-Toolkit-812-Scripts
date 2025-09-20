<#
.SYNOPSIS
    Wait Azrecoveryservicesbackupjob

.DESCRIPTION
    Wait Azrecoveryservicesbackupjob operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$waitAzRecoveryServicesBackupJobSplat = @{
    Job = $restorejob
    Timeout = 43200
}
Wait-AzRecoveryServicesBackupJob @waitAzRecoveryServicesBackupJobSplat\n
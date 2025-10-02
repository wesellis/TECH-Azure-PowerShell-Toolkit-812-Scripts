#Requires -Version 7.4

<#`n.SYNOPSIS
    Wait Azrecoveryservicesbackupjob

.DESCRIPTION
    Wait Azrecoveryservicesbackupjob operation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$waitAzRecoveryServicesBackupJobSplat = @{
    Job = $restorejob
    Timeout = 43200
}
Wait-AzRecoveryServicesBackupJob @waitAzRecoveryServicesBackupJobSplat



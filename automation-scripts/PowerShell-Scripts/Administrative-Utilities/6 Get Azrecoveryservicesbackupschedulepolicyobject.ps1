<#
.SYNOPSIS
    Get recoveryservicesbackupschedulepolicyobject

.DESCRIPTION
    Get recoveryservicesbackupschedulepolicyobject operation
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
ScheduleRunFrequency ScheduleRunDays ScheduleRunTimes
-------------------- --------------- ----------------
               Daily {Sunday}        {2020-12-12 5:00:00 PM}
    General notes
The Get-AzRecoveryServicesBackupSchedulePolicyObject -ErrorAction Stop cmdlet gets a base AzureRMRecoveryServicesSchedulePolicyObject. This object is not persisted in the system. It is temporary object that you can manipulate and use with the New-AzRecoveryServicesBackupProtectionPolicy -ErrorAction Stop cmdlet to create a new backup protection policy.
$getAzRecoveryServicesBackupSchedulePolicyObjectSplat = @{
    WorkloadType = "AzureVM"
}
Get-AzRecoveryServicesBackupSchedulePolicyObject -ErrorAction Stop @getAzRecoveryServicesBackupSchedulePolicyObjectSplat


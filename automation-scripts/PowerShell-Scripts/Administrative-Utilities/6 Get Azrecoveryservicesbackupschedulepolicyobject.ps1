#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    6 Get Azrecoveryservicesbackupschedulepolicyobject

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
    We Enhanced 6 Get Azrecoveryservicesbackupschedulepolicyobject

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

ScheduleRunFrequency ScheduleRunDays ScheduleRunTimes       
-------------------- --------------- ----------------       
               Daily {Sunday}        {2020-12-12 5:00:00 PM}
.NOTES
    General notes

The Get-AzRecoveryServicesBackupSchedulePolicyObject -ErrorAction Stop cmdlet gets a base AzureRMRecoveryServicesSchedulePolicyObject. This object is not persisted in the system. It is temporary object that you can manipulate and use with the New-AzRecoveryServicesBackupProtectionPolicy -ErrorAction Stop cmdlet to create a new backup protection policy.
    


$getAzRecoveryServicesBackupSchedulePolicyObjectSplat = @{
    WorkloadType = "AzureVM"
}

Get-AzRecoveryServicesBackupSchedulePolicyObject -ErrorAction Stop @getAzRecoveryServicesBackupSchedulePolicyObjectSplat

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

<#
.SYNOPSIS
    7 Get Azrecoveryservicesbackupprotectionpolicy

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 7 Get Azrecoveryservicesbackupprotectionpolicy

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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

    #all current Backup Policies

    Name                 WorkloadType       BackupManagementType BackupTime                Frequency                                IsDifferentialBac
                                                                                                                                kupEnabled       
----                 ------------       -------------------- ----------                ---------                                -----------------
HourlyLogBackup      MSSQL              AzureWorkload        2020-12-12 4:00:00 PM     Daily                                    False

SnapshotRetentionInDays : 2
ProtectedItemsCount     : 0
AzureBackupRGName       : 
AzureBackupRGNameSuffix : 
SchedulePolicy          : scheduleRunType:Daily, ScheduleRunDays:null, ScheduleRunTimes:{2020-12-12 4:00:00 PM}
RetentionPolicy         : IsDailyScheduleEnabled:True, IsWeeklyScheduleEnabled:False, IsMonthlyScheduleEnabled:False,
                          IsYearlyScheduleEnabled:FalseDailySchedule: DurationCountInDays: 30, RetentionTimes: {2020-12-12 4:00:00 PM}, 
                          WeeklySchedule: NULL, MonthlySchedule:NULL, YearlySchedule:NULL
Name                    : DefaultPolicy
WorkloadType            : AzureVM
Id                      : /Subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/resourceGroups/CanPrintEquip_Outlook_RG/providers/Microsoft.Recover
                          yServices/vaults/Outlook1ARSV1/backupPolicies/DefaultPolicy
BackupManagementType    : AzureVM



Name                 WorkloadType       BackupManagementType BackupTime                DaysOfWeek
----                 ------------       -------------------- ----------                ----------
DefaultPolicy        AzureVM            AzureVM              2020-12-12 4:00:00 PM

from Azure Portal
BACKUP FREQUENCY

Daily at 4:00 PM UTC
RETENTION RANGE

Retention of daily backup point

Retain backup taken every day at 4:00 PM for 30 Day(s)

.NOTES
    General notes


    


$WECustomerName = 'CanPrintEquip'
$WEVMName = 'Outlook1'
$WEResourceGroupName = -join ("$WECustomerName" , " _Outlook" , " _RG" )

$WEVaultname = -join (" $WEVMName" , " ARSV1" )
; 
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $WEResourceGroupName -Name $WEVaultname
$targetVault.ID
; 
$getAzRecoveryServicesBackupProtectionPolicySplat = @{
    WorkloadType = " AzureVM" #you may ommit this parameter if you want to get all the current Backup policies
    VaultId = $targetVault.ID
}

Get-AzRecoveryServicesBackupProtectionPolicy -ErrorAction Stop @getAzRecoveryServicesBackupProtectionPolicySplat

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
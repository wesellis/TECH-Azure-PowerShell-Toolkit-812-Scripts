#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get recoveryservicesbackupprotectionpolicy

.DESCRIPTION
    Get recoveryservicesbackupprotectionpolicy operation
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
    General notes
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $Vaultname
$targetVault.ID
$getAzRecoveryServicesBackupProtectionPolicySplat = @{
    WorkloadType = "AzureVM" #you may ommit this parameter if you want to get all the current Backup policies
    VaultId = $targetVault.ID
}
Get-AzRecoveryServicesBackupProtectionPolicy -ErrorAction Stop @getAzRecoveryServicesBackupProtectionPolicySplat


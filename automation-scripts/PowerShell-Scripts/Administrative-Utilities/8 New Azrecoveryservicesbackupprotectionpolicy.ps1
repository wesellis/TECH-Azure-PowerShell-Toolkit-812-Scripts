<#
.SYNOPSIS
    We Enhanced 8 New Azrecoveryservicesbackupprotectionpolicy

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

    A backup protection policy is associated with at least one retention policy. A retention policy defines how long a recovery point is kept before it's deleted.

Use Get-AzRecoveryServicesBackupRetentionPolicyObject to view the default retention policy.
Similarly you can use Get-AzRecoveryServicesBackupSchedulePolicyObject to obtain the default schedule policy.
The New-AzRecoveryServicesBackupProtectionPolicy cmdlet creates a PowerShell object that holds backup policy information.
The schedule and retention policy objects are used as inputs to the New-AzRecoveryServicesBackupProtectionPolicy cmdlet.



$WERetPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType 'AzureVM'
$WERetPol.DailySchedule.DurationCountInDays = '365'
$WESchPol = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType 'AzureVM'
; 
$newAzRecoveryServicesBackupProtectionPolicySplat = @{
    Name = "NewPolicy"
    WorkloadType = 'AzureVM'
    RetentionPolicy = $WERetPol
    SchedulePolicy = $WESchPol
    VaultId = $targetVault.ID
}

New-AzRecoveryServicesBackupProtectionPolicy @newAzRecoveryServicesBackupProtectionPolicySplat

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
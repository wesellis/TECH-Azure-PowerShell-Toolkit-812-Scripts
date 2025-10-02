#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Create new Azure Recovery Services backup protection policy

.DESCRIPTION
    Create new Azure Recovery Services backup protection policy operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PolicyName,

    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateSet('AzureVM', 'WindowsServer', 'AzureFiles', 'MSSQL')]
    [string]$WorkloadType = 'AzureVM',

    [Parameter()]
    [int]$DailyRetentionDays = 30
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction Stop

$retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType $WorkloadType -ErrorAction Stop
$retentionPolicy.DailySchedule.DurationCountInDays = $DailyRetentionDays

$schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType $WorkloadType -ErrorAction Stop

$newAzRecoveryServicesBackupProtectionPolicySplat = @{
    Name = $PolicyName
    WorkloadType = $WorkloadType
    RetentionPolicy = $retentionPolicy
    SchedulePolicy = $schedulePolicy
    VaultId = $targetVault.ID
}

New-AzRecoveryServicesBackupProtectionPolicy @newAzRecoveryServicesBackupProtectionPolicySplat -ErrorAction Stop
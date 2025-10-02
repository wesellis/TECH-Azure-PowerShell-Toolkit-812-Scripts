#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    configure backup policies
.DESCRIPTION
    configure backup policies operation
    Author: Wes Ellis (wes@wesellis.com)

    Configures backup policies for Azure VMs and SQL databases
    Virtual Machines, SQL databases, and file shares. Supports creating custom
    backup policies with configurable retention periods and schedules.
.parameter VaultName
    Name of the Recovery Services vault
.parameter ResourceGroupName
    Name of the resource group containing the vault
.parameter PolicyName
    Name of the backup policy to create or update
.parameter BackupType
    Type of backup policy: VM, SQL, FileShare
.parameter RetentionDaily
    Number of days to retain daily backups
.parameter RetentionWeekly
    Number of weeks to retain weekly backups
.parameter RetentionMonthly
    Number of months to retain monthly backups
.parameter RetentionYearly
    Number of years to retain yearly backups
.parameter ScheduleTime
    Time of day to run backups (24-hour format)
.parameter ApplyToResources
    Apply the policy to specific resources immediately

    .\configure-backup-policies.ps1 -VaultName "MyVault" -ResourceGroupName "MyRG" -PolicyName "DailyVM" -BackupType VM

    Creates a VM backup policy with default retention settings

    .\configure-backup-policies.ps1 -VaultName "MyVault" -ResourceGroupName "MyRG" -PolicyName "SQLPolicy" -BackupType SQL -RetentionDaily 30

    Creates SQL backup policy with 30-day retention

    Author: Azure PowerShell Toolkit

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,

    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyName,

    [parameter(Mandatory = $true)]
    [ValidateSet('VM', 'SQL', 'FileShare')]
    [string]$BackupType,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 9999)]
    [int]$RetentionDaily = 7,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 520)]
    [int]$RetentionWeekly = 4,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 120)]
    [int]$RetentionMonthly = 12,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 99)]
    [int]$RetentionYearly = 5,

    [parameter(Mandatory = $false)]
    [ValidatePattern('^([01]?[0-9]|2[0-3]):[0-5][0-9]$')]
    [string]$ScheduleTime = "02:00",

    [parameter(Mandatory = $false)]
    [string[]]$ApplyToResources,

    [parameter()]
    [switch]$InstantRPRetention,

    [parameter()]
    [ValidateSet('Standard', 'Enhanced')]
    [string]$PolicyTier = 'Standard'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'


[OutputType([bool])] 
 {
    param(
        [string]$VaultName,
        [string]$ResourceGroupName
    )

    try {
        $vault = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        write-Verbose "Recovery Services vault '$VaultName' found"
        return $vault
    }
    catch {
        write-Error "Recovery Services vault '$VaultName' not found in resource group '$ResourceGroupName'"
        throw
    }
}

function New-VMBackupPolicy {
    param(
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [string]$PolicyName,
        [int]$RetentionDaily,
        [int]$RetentionWeekly,
        [int]$RetentionMonthly,
        [int]$RetentionYearly,
        [string]$ScheduleTime
    )

    try {
        Set-AzRecoveryServicesVaultContext -Vault $Vault

        $existingPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -ErrorAction SilentlyContinue

        if ($existingPolicy) {
            write-Verbose "Policy '$PolicyName' already exists. Updating..."
        }
        else {
            write-Verbose "Creating new VM backup policy: $PolicyName"
        }

        $scheduleHour = [int]($ScheduleTime.Split(':')[0])
        $scheduleMinute = [int]($ScheduleTime.Split(':')[1])
        $scheduleDate = Get-Date -Hour $scheduleHour -Minute $scheduleMinute -Second 0

        $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
        $schedulePolicy.ScheduleRunTimes[0] = $scheduleDate

        $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM

        $retentionPolicy.DailySchedule.DurationCountInDays = $RetentionDaily
        $retentionPolicy.IsDailyScheduleEnabled = $true

        if ($RetentionWeekly -gt 0) {
            $retentionPolicy.WeeklySchedule.DurationCountInWeeks = $RetentionWeekly
            $retentionPolicy.WeeklySchedule.DaysOfTheWeek = @("Sunday")
            $retentionPolicy.IsWeeklyScheduleEnabled = $true
        }

        if ($RetentionMonthly -gt 0) {
            $retentionPolicy.MonthlySchedule.DurationCountInMonths = $RetentionMonthly
            $retentionPolicy.MonthlySchedule.RetentionScheduleFormatType = "Weekly"
            $retentionPolicy.MonthlySchedule.RetentionScheduleWeekly.DaysOfTheWeek = @("Sunday")
            $retentionPolicy.MonthlySchedule.RetentionScheduleWeekly.WeeksOfTheMonth = @("First")
            $retentionPolicy.IsMonthlyScheduleEnabled = $true
        }

        if ($RetentionYearly -gt 0) {
            $retentionPolicy.YearlySchedule.DurationCountInYears = $RetentionYearly
            $retentionPolicy.YearlySchedule.RetentionScheduleFormatType = "Weekly"
            $retentionPolicy.YearlySchedule.MonthsOfYear = @("January")
            $retentionPolicy.YearlySchedule.RetentionScheduleWeekly.DaysOfTheWeek = @("Sunday")
            $retentionPolicy.YearlySchedule.RetentionScheduleWeekly.WeeksOfTheMonth = @("First")
            $retentionPolicy.IsYearlyScheduleEnabled = $true
        }

        if ($PSCmdlet.ShouldProcess($PolicyName, "Create/Update VM Backup Policy")) {
            if ($existingPolicy) {
                $params = @{
                    Policy = $existingPolicy
                    SchedulePolicy = $schedulePolicy
                    RetentionPolicy = $retentionPolicy
                }
                Set-AzRecoveryServicesBackupProtectionPolicy @params
            }
            else {
                $params = @{
                    Name = $PolicyName
                    WorkloadType = "AzureVM"
                    SchedulePolicy = $schedulePolicy
                    RetentionPolicy = $retentionPolicy
                }
                New-AzRecoveryServicesBackupProtectionPolicy @params
            }
        }

        write-Host "VM backup policy '$PolicyName' configured successfully" -InformationAction Continue
        return Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    catch {
        write-Error "Failed to configure VM backup policy: $_"
        throw
    }
}

function New-SQLBackupPolicy {
    param(
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [string]$PolicyName,
        [int]$RetentionDaily,
        [int]$RetentionWeekly,
        [int]$RetentionMonthly,
        [int]$RetentionYearly
    )

    try {
        Set-AzRecoveryServicesVaultContext -Vault $Vault

        write-Verbose "Creating SQL backup policy: $PolicyName"

        $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType MSSQL -ScheduleRunFrequency Daily
        $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType MSSQL

        $retentionPolicy.FullBackupRetentionPolicy.IsDailyScheduleEnabled = $true
        $retentionPolicy.FullBackupRetentionPolicy.DailySchedule.DurationCountInDays = $RetentionDaily

        if ($RetentionWeekly -gt 0) {
            $retentionPolicy.FullBackupRetentionPolicy.IsWeeklyScheduleEnabled = $true
            $retentionPolicy.FullBackupRetentionPolicy.WeeklySchedule.DurationCountInWeeks = $RetentionWeekly
        }

        if ($RetentionMonthly -gt 0) {
            $retentionPolicy.FullBackupRetentionPolicy.IsMonthlyScheduleEnabled = $true
            $retentionPolicy.FullBackupRetentionPolicy.MonthlySchedule.DurationCountInMonths = $RetentionMonthly
        }

        if ($RetentionYearly -gt 0) {
            $retentionPolicy.FullBackupRetentionPolicy.IsYearlyScheduleEnabled = $true
            $retentionPolicy.FullBackupRetentionPolicy.YearlySchedule.DurationCountInYears = $RetentionYearly
        }

        if ($PSCmdlet.ShouldProcess($PolicyName, "Create SQL Backup Policy")) {
            $params = @{
                Name = $PolicyName
                WorkloadType = "MSSQL"
                SchedulePolicy = $schedulePolicy
                RetentionPolicy = $retentionPolicy
                VaultId = $Vault.ID
            }
            New-AzRecoveryServicesBackupProtectionPolicy @params
        }

        write-Host "SQL backup policy '$PolicyName' configured successfully" -InformationAction Continue
        return Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    catch {
        write-Error "Failed to configure SQL backup policy: $_"
        throw
    }
}

function New-FileShareBackupPolicy {
    param(
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [string]$PolicyName,
        [int]$RetentionDaily,
        [string]$ScheduleTime
    )

    try {
        Set-AzRecoveryServicesVaultContext -Vault $Vault

        write-Verbose "Creating FileShare backup policy: $PolicyName"

        $scheduleHour = [int]($ScheduleTime.Split(':')[0])
        $scheduleMinute = [int]($ScheduleTime.Split(':')[1])
        $scheduleDate = Get-Date -Hour $scheduleHour -Minute $scheduleMinute -Second 0

        $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureFiles
        $schedulePolicy.ScheduleRunTimes[0] = $scheduleDate

        $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureFiles
        $retentionPolicy.DailySchedule.DurationCountInDays = $RetentionDaily

        if ($PSCmdlet.ShouldProcess($PolicyName, "Create FileShare Backup Policy")) {
            $params = @{
                Name = $PolicyName
                WorkloadType = "AzureFiles"
                SchedulePolicy = $schedulePolicy
                RetentionPolicy = $retentionPolicy
            }
            New-AzRecoveryServicesBackupProtectionPolicy @params
        }

        write-Host "FileShare backup policy '$PolicyName' configured successfully" -InformationAction Continue
        return Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    catch {
        write-Error "Failed to configure FileShare backup policy: $_"
        throw
    }
}

function Apply-BackupPolicy {
    param(
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [object]$Policy,
        [string[]]$ResourceIds,
        [string]$BackupType
    )

    try {
        Set-AzRecoveryServicesVaultContext -Vault $Vault

        foreach ($resourceId in $ResourceIds) {
            write-Verbose "Applying policy to resource: $resourceId"

            switch ($BackupType) {
                'VM' {
                    $vmName = $resourceId.Split('/')[-1]
                    $rgName = $resourceId.Split('/')[4]

                    $vmSplat = @{
    ResourceGroupName = $rgName
    Name = $vmName
    ErrorAction = SilentlyContinue
}
Get-AzVM @vmSplat
                    if ($vm) {
                        if ($PSCmdlet.ShouldProcess($vmName, "Enable backup with policy '$($Policy.Name)'")) {
                            $params = @{
                                ResourceGroupName = $rgName
                                Name = $vmName
                                Policy = $Policy
                            }
                            Enable-AzRecoveryServicesBackupProtection @params
                            write-Host "Backup enabled for VM: $vmName" -InformationAction Continue
                        }
                    }
                    else {
                        write-Warning "VM not found: $vmName"
                    }
                }
                'SQL' {
                    write-Verbose "SQL backup configuration for: $resourceId"
                }
                'FileShare' {
                    write-Verbose "FileShare backup configuration for: $resourceId"
                }
            }

} catch {
        write-Error "Failed to apply backup policy: $_"
        throw
    }
}

function Get-BackupPolicySummary {
    param(
        [object]$Policy,
        [string]$BackupType
    )

    $summary = [PSCustomObject]@{
        PolicyName = $Policy.Name
        WorkloadType = $Policy.WorkloadType
        ScheduleRunTimes = $Policy.SchedulePolicy.ScheduleRunTimes -join ', '
        DailyRetention = $Policy.RetentionPolicy.DailySchedule.DurationCountInDays
        WeeklyRetention = if ($Policy.RetentionPolicy.IsWeeklyScheduleEnabled) {
            $Policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks
        } else { "Not configured" }
        MonthlyRetention = if ($Policy.RetentionPolicy.IsMonthlyScheduleEnabled) {
            $Policy.RetentionPolicy.MonthlySchedule.DurationCountInMonths
        } else { "Not configured" }
        YearlyRetention = if ($Policy.RetentionPolicy.IsYearlyScheduleEnabled) {
            $Policy.RetentionPolicy.YearlySchedule.DurationCountInYears
        } else { "Not configured" }
    }

    return $summary
}


try {
    write-Host "[START] Configuring backup policies" -InformationAction Continue

    $vault = Test-RecoveryServicesVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName

    $policy = switch ($BackupType) {
        'VM' {
            $params = @{
                RetentionYearly = $RetentionYearly
                RetentionWeekly = $RetentionWeekly
                RetentionMonthly = $RetentionMonthly
                RetentionDaily = $RetentionDaily
                Vault = $vault
                ScheduleTime = $ScheduleTime
                PolicyName = $PolicyName
            }
            New-VMBackupPolicy @params
        }
        'SQL' {
            $params = @{
                RetentionMonthly = $RetentionMonthly
                RetentionYearly = $RetentionYearly
                PolicyName = $PolicyName
                Vault = $vault
                RetentionWeekly = $RetentionWeekly
                RetentionDaily = $RetentionDaily
            }
            New-SQLBackupPolicy @params
        }
        'FileShare' {
            $params = @{
                RetentionDaily = $RetentionDaily
                PolicyName = $PolicyName
                Vault = $vault
                ScheduleTime = $ScheduleTime
            }
            New-FileShareBackupPolicy @params
        }
    }

    if ($ApplyToResources -and $ApplyToResources.Count -gt 0) {
        write-Host "[APPLY] Applying policy to specified resources" -InformationAction Continue
        Apply-BackupPolicy -Vault $vault -Policy $policy -ResourceIds $ApplyToResources -BackupType $BackupType
    }

    $summary = Get-BackupPolicySummary -Policy $policy -BackupType $BackupType
    write-Host "`n[SUMMARY] Backup Policy Configuration:" -InformationAction Continue
    $summary | Format-List

    write-Host "[COMPLETE] Backup policy configuration completed successfully" -InformationAction Continue

    return $policy
}
catch {
    $errorDetails = @{
        Message = $_.Exception.Message
        Category = $_.CategoryInfo.Category
        Line = $_.InvocationInfo.ScriptLineNumber
    }

    write-Error "Backup policy configuration failed: $($errorDetails.Message) at line $($errorDetails.Line)"
    throw
}
finally {
    $ProgressPreference = 'Continue'
}




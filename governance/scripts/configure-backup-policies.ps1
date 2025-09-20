#Requires -Module Az.RecoveryServices, Az.Sql
#Requires -Version 5.1
<#
.SYNOPSIS
    configure backup policies
.DESCRIPTION
    configure backup policies operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Configures backup policies for Azure VMs and SQL databases
    Virtual Machines, SQL databases, and file shares. Supports creating custom
    backup policies with configurable retention periods and schedules.
.PARAMETER VaultName
    Name of the Recovery Services vault
.PARAMETER ResourceGroupName
    Name of the resource group containing the vault
.PARAMETER PolicyName
    Name of the backup policy to create or update
.PARAMETER BackupType
    Type of backup policy: VM, SQL, FileShare
.PARAMETER RetentionDaily
    Number of days to retain daily backups
.PARAMETER RetentionWeekly
    Number of weeks to retain weekly backups
.PARAMETER RetentionMonthly
    Number of months to retain monthly backups
.PARAMETER RetentionYearly
    Number of years to retain yearly backups
.PARAMETER ScheduleTime
    Time of day to run backups (24-hour format)
.PARAMETER ApplyToResources
    Apply the policy to specific resources immediately

    .\configure-backup-policies.ps1 -VaultName "MyVault" -ResourceGroupName "MyRG" -PolicyName "DailyVM" -BackupType VM

    Creates a VM backup policy with default retention settings

    .\configure-backup-policies.ps1 -VaultName "MyVault" -ResourceGroupName "MyRG" -PolicyName "SQLPolicy" -BackupType SQL -RetentionDaily 30

    Creates SQL backup policy with 30-day retention

    Author: Azure PowerShell Toolkit#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('VM', 'SQL', 'FileShare')]
    [string]$BackupType,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 9999)]
    [int]$RetentionDaily = 7,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 520)]
    [int]$RetentionWeekly = 4,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 120)]
    [int]$RetentionMonthly = 12,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 99)]
    [int]$RetentionYearly = 5,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^([01]?[0-9]|2[0-3]):[0-5][0-9]$')]
    [string]$ScheduleTime = "02:00",

    [Parameter(Mandatory = $false)]
    [string[]]$ApplyToResources,

    [Parameter()]
    [switch]$InstantRPRetention,

    [Parameter()]
    [ValidateSet('Standard', 'Enhanced')]
    [string]$PolicyTier = 'Standard'
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

#endregion

#region Functions
function Test-RecoveryServicesVault {
    [CmdletBinding()]
    param(
        [string]$VaultName,
        [string]$ResourceGroupName
    )

    try {
        $vault = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        Write-Verbose "Recovery Services vault '$VaultName' found"
        return $vault
    }
    catch {
        Write-Error "Recovery Services vault '$VaultName' not found in resource group '$ResourceGroupName'"
        throw
    }
}

function New-VMBackupPolicy {
    [CmdletBinding(SupportsShouldProcess = $true)]
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

        # Check if policy already exists
        $existingPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -ErrorAction SilentlyContinue

        if ($existingPolicy) {
            Write-Verbose "Policy '$PolicyName' already exists. Updating..."
        }
        else {
            Write-Verbose "Creating new VM backup policy: $PolicyName"
        }

        # Parse schedule time
        $scheduleHour = [int]($ScheduleTime.Split(':')[0])
        $scheduleMinute = [int]($ScheduleTime.Split(':')[1])
        $scheduleDate = Get-Date -Hour $scheduleHour -Minute $scheduleMinute -Second 0

        # Create schedule policy object
        $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
        $schedulePolicy.ScheduleRunTimes[0] = $scheduleDate

        # Create retention policy object
        $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM

        # Configure daily retention
        $retentionPolicy.DailySchedule.DurationCountInDays = $RetentionDaily
        $retentionPolicy.IsDailyScheduleEnabled = $true

        # Configure weekly retention
        if ($RetentionWeekly -gt 0) {
            $retentionPolicy.WeeklySchedule.DurationCountInWeeks = $RetentionWeekly
            $retentionPolicy.WeeklySchedule.DaysOfTheWeek = @("Sunday")
            $retentionPolicy.IsWeeklyScheduleEnabled = $true
        }

        # Configure monthly retention
        if ($RetentionMonthly -gt 0) {
            $retentionPolicy.MonthlySchedule.DurationCountInMonths = $RetentionMonthly
            $retentionPolicy.MonthlySchedule.RetentionScheduleFormatType = "Weekly"
            $retentionPolicy.MonthlySchedule.RetentionScheduleWeekly.DaysOfTheWeek = @("Sunday")
            $retentionPolicy.MonthlySchedule.RetentionScheduleWeekly.WeeksOfTheMonth = @("First")
            $retentionPolicy.IsMonthlyScheduleEnabled = $true
        }

        # Configure yearly retention
        if ($RetentionYearly -gt 0) {
            $retentionPolicy.YearlySchedule.DurationCountInYears = $RetentionYearly
            $retentionPolicy.YearlySchedule.RetentionScheduleFormatType = "Weekly"
            $retentionPolicy.YearlySchedule.MonthsOfYear = @("January")
            $retentionPolicy.YearlySchedule.RetentionScheduleWeekly.DaysOfTheWeek = @("Sunday")
            $retentionPolicy.YearlySchedule.RetentionScheduleWeekly.WeeksOfTheMonth = @("First")
            $retentionPolicy.IsYearlyScheduleEnabled = $true
        }

        # Create or update the policy
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

        Write-Host "VM backup policy '$PolicyName' configured successfully" -InformationAction Continue
        return Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    catch {
        Write-Error "Failed to configure VM backup policy: $_"
        throw
    }
}

function New-SQLBackupPolicy {
    [CmdletBinding(SupportsShouldProcess = $true)]
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

        Write-Verbose "Creating SQL backup policy: $PolicyName"

        # Get SQL workload backup policy object
        $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType MSSQL -ScheduleRunFrequency Daily
        $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType MSSQL

        # Configure retention
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

        Write-Host "SQL backup policy '$PolicyName' configured successfully" -InformationAction Continue
        return Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    catch {
        Write-Error "Failed to configure SQL backup policy: $_"
        throw
    }
}

function New-FileShareBackupPolicy {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [string]$PolicyName,
        [int]$RetentionDaily,
        [string]$ScheduleTime
    )

    try {
        Set-AzRecoveryServicesVaultContext -Vault $Vault

        Write-Verbose "Creating FileShare backup policy: $PolicyName"

        # Parse schedule time
        $scheduleHour = [int]($ScheduleTime.Split(':')[0])
        $scheduleMinute = [int]($ScheduleTime.Split(':')[1])
        $scheduleDate = Get-Date -Hour $scheduleHour -Minute $scheduleMinute -Second 0

        # Get FileShare workload backup policy objects
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

        Write-Host "FileShare backup policy '$PolicyName' configured successfully" -InformationAction Continue
        return Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    catch {
        Write-Error "Failed to configure FileShare backup policy: $_"
        throw
    }
}

function Apply-BackupPolicy {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [object]$Policy,
        [string[]]$ResourceIds,
        [string]$BackupType
    )

    try {
        Set-AzRecoveryServicesVaultContext -Vault $Vault

        foreach ($resourceId in $ResourceIds) {
            Write-Verbose "Applying policy to resource: $resourceId"

            switch ($BackupType) {
                'VM' {
                    # Parse VM details from resource ID
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
                            Write-Host "Backup enabled for VM: $vmName" -InformationAction Continue
                        }
                    }
                    else {
                        Write-Warning "VM not found: $vmName"
                    }
                }
                'SQL' {
                    # SQL backup implementation
                    Write-Verbose "SQL backup configuration for: $resourceId"
                }
                'FileShare' {
                    # FileShare backup implementation
                    Write-Verbose "FileShare backup configuration for: $resourceId"
                }
            }
        
} catch {
        Write-Error "Failed to apply backup policy: $_"
        throw
    }
}

function Get-BackupPolicySummary {
    [CmdletBinding()]
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

#endregion

#region Main-Execution
try {
    Write-Host "[START] Configuring backup policies" -InformationAction Continue

    # Validate Recovery Services vault
    $vault = Test-RecoveryServicesVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName

    # Create/Update backup policy based on type
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

    # Apply policy to resources if specified
    if ($ApplyToResources -and $ApplyToResources.Count -gt 0) {
        Write-Host "[APPLY] Applying policy to specified resources" -InformationAction Continue
        Apply-BackupPolicy -Vault $vault -Policy $policy -ResourceIds $ApplyToResources -BackupType $BackupType
    }

    # Display policy summary
    $summary = Get-BackupPolicySummary -Policy $policy -BackupType $BackupType
    Write-Host "`n[SUMMARY] Backup Policy Configuration:" -InformationAction Continue
    $summary | Format-List

    Write-Host "[COMPLETE] Backup policy configuration completed successfully" -InformationAction Continue

    # Return the policy object
    return $policy
}
catch {
    $errorDetails = @{
        Message = $_.Exception.Message
        Category = $_.CategoryInfo.Category
        Line = $_.InvocationInfo.ScriptLineNumber
    }

    Write-Error "Backup policy configuration failed: $($errorDetails.Message) at line $($errorDetails.Line)"
    throw
}
finally {
    # Cleanup
    $ProgressPreference = 'Continue'
}

#endregion\n


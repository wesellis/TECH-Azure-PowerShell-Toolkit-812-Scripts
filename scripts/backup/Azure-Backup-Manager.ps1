#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Resources
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Comprehensive Azure backup management

.DESCRIPTION
    Manage Azure VM backups, policies, and recovery operations
    Provides complete backup lifecycle management for Azure Virtual Machines
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER ResourceGroupName
    Resource group containing the recovery vault

.PARAMETER VaultName
    Recovery Services vault name

.PARAMETER VMName
    Virtual machine to backup

.PARAMETER Action
    Action to perform on the backup service
    Valid options: Backup, Restore, Status, Policy, Enable, Disable, Schedule

.PARAMETER VMResourceGroupName
    Resource group containing the VM (if different from vault resource group)

.PARAMETER PolicyName
    Backup policy name (for Enable action)

.PARAMETER RestorePointDate
    Date of restore point for restore operations (format: yyyy-MM-dd)

.PARAMETER Location
    Azure region for vault creation

.EXAMPLE
    .\Azure-Backup-Manager.ps1 -ResourceGroupName "rg-backups" -VaultName "vault-prod" -VMName "vm-web01" -Action "Backup"
    Starts an immediate backup for the specified VM

.EXAMPLE
    .\Azure-Backup-Manager.ps1 -ResourceGroupName "rg-backups" -VaultName "vault-prod" -VMName "vm-web01" -Action "Enable" -PolicyName "DailyPolicy"
    Enables backup protection for a VM with a specific policy

.EXAMPLE
    .\Azure-Backup-Manager.ps1 -ResourceGroupName "rg-backups" -VaultName "vault-prod" -VMName "vm-web01" -Action "Status"
    Gets the backup status and information for the specified VM

.NOTES
    Requires Azure PowerShell modules and appropriate permissions for Recovery Services
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Backup', 'Restore', 'Status', 'Policy', 'Enable', 'Disable', 'Schedule', 'CreateVault')]
    [string]$Action,

    [Parameter()]
    [string]$VMResourceGroupName,

    [Parameter()]
    [string]$PolicyName = "DefaultPolicy",

    [Parameter()]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$RestorePointDate,

    [Parameter()]
    [string]$Location = "East US"
)

# Set error handling preference
$ErrorActionPreference = 'Stop'

# Custom logging function
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    
    $logEntry = "$timestamp [Backup-Manager] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

# Function to create a Recovery Services Vault
function New-RecoveryVault {
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        [string]$VaultName,
        [string]$Location
    )
    
    try {
        Write-LogMessage "Creating Recovery Services Vault: $VaultName" -Level "INFO"
        
        # Check if resource group exists
        try {
            Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogMessage "Creating resource group: $ResourceGroupName" -Level "INFO"
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
        }
        
        $vault = New-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -Location $Location
        
        # Set vault storage redundancy
        Set-AzRecoveryServicesVaultContext -Vault $vault
        $storageConfig = Get-AzRecoveryServicesBackupProperty -Vault $vault
        Set-AzRecoveryServicesBackupProperty -Vault $vault -BackupStorageRedundancy "GeoRedundant"
        
        Write-LogMessage "Recovery Services Vault created successfully" -Level "SUCCESS"
        return $vault
    }
    catch {
        Write-LogMessage "Failed to create Recovery Services Vault: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

# Function to get backup item for a VM
function Get-VMBackupItem {
    [CmdletBinding()]
    param(
        [string]$VMName,
        [string]$VMResourceGroupName
    )
    
    try {
        $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType "AzureVM" -WorkloadType "AzureVM"
        $vmBackup = $backupItems | Where-Object { 
            $_.Name -like "*$VMName*" -or 
            $_.SourceResourceId -like "*$VMName*" -or
            ($_.SourceResourceId -like "*$VMResourceGroupName*" -and $_.Name -like "*$VMName*")
        }
        return $vmBackup
    }
    catch {
        Write-LogMessage "Error retrieving backup items: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

try {
    Write-LogMessage "Starting Azure backup management operation" -Level "INFO"
    Write-LogMessage "Vault: $VaultName" -Level "INFO"
    Write-LogMessage "VM: $VMName" -Level "INFO"
    Write-LogMessage "Action: $Action" -Level "INFO"

    # Validate Azure context
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }
    
    Write-LogMessage "Using Azure subscription: $($context.Subscription.Name)" -Level "INFO"

    # Set VM resource group if not provided
    if (-not $VMResourceGroupName) {
        $VMResourceGroupName = $ResourceGroupName
    }

    # Handle vault creation separately
    if ($Action -eq 'CreateVault') {
        $vault = New-RecoveryVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Location $Location
        return $vault
    }

    # Get and set vault context
    try {
        Write-LogMessage "Connecting to Recovery Services Vault..." -Level "INFO"
        $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction Stop
        Set-AzRecoveryServicesVaultContext -Vault $vault
        Write-LogMessage "Connected to vault: $($vault.Name)" -Level "SUCCESS"
    }
    catch {
        Write-LogMessage "Recovery Services Vault '$VaultName' not found in resource group '$ResourceGroupName'" -Level "ERROR"
        Write-LogMessage "Use -Action 'CreateVault' to create the vault first" -Level "INFO"
        throw "Vault not found: $($_.Exception.Message)"
    }

    switch ($Action) {
        'Status' {
            Write-LogMessage "Getting backup status for VM: $VMName" -Level "INFO"
            
            $vmBackup = Get-VMBackupItem -VMName $VMName -VMResourceGroupName $VMResourceGroupName
            
            if ($vmBackup) {
                $status = [PSCustomObject]@{
                    VMName = $VMName
                    VaultName = $VaultName
                    ProtectionStatus = $vmBackup.ProtectionStatus
                    ProtectionState = $vmBackup.ProtectionState
                    LastBackupTime = $vmBackup.LastBackupTime
                    LastBackupStatus = $vmBackup.LastBackupStatus
                    PolicyName = $vmBackup.PolicyName
                    BackupSizeInBytes = $vmBackup.BackupSizeInBytes
                    SourceResourceId = $vmBackup.SourceResourceId
                    ContainerName = $vmBackup.ContainerName
                    WorkloadType = $vmBackup.WorkloadType
                    LatestRecoveryPoint = $vmBackup.LatestRecoveryPoint
                }
                
                Write-LogMessage "Backup status retrieved successfully" -Level "SUCCESS"
                Write-LogMessage "Protection Status: $($status.ProtectionStatus)" -Level "INFO"
                Write-LogMessage "Last Backup: $($status.LastBackupTime)" -Level "INFO"
                
                return $status
            } else {
                Write-LogMessage "No backup configuration found for VM: $VMName" -Level "WARN"
                Write-LogMessage "VM may not be enabled for backup or may be in a different vault" -Level "WARN"
                return $null
            }
        }

        'Backup' {
            Write-LogMessage "Starting backup for VM: $VMName" -Level "INFO"
            
            if ($PSCmdlet.ShouldProcess($VMName, 'Start backup')) {
                $vmBackup = Get-VMBackupItem -VMName $VMName -VMResourceGroupName $VMResourceGroupName
                
                if ($vmBackup) {
                    Write-LogMessage "Initiating backup job..." -Level "INFO"
                    $job = Backup-AzRecoveryServicesBackupItem -Item $vmBackup
                    
                    Write-LogMessage "Backup job started successfully" -Level "SUCCESS"
                    Write-LogMessage "Job ID: $($job.JobId)" -Level "INFO"
                    Write-LogMessage "Job Status: $($job.Status)" -Level "INFO"
                    
                    $backupResult = [PSCustomObject]@{
                        VMName = $VMName
                        JobId = $job.JobId
                        JobType = $job.Operation
                        Status = $job.Status
                        StartTime = $job.StartTime
                        ActivityId = $job.ActivityId
                    }
                    
                    return $backupResult
                } else {
                    Write-LogMessage "VM '$VMName' is not configured for backup" -Level "ERROR"
                    Write-LogMessage "Use -Action 'Enable' to configure backup first" -Level "INFO"
                    throw "VM not configured for backup"
                }
            }
        }

        'Enable' {
            Write-LogMessage "Enabling backup protection for VM: $VMName" -Level "INFO"
            
            if ($PSCmdlet.ShouldProcess($VMName, 'Enable backup protection')) {
                # Verify VM exists
                try {
                    $vm = Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroupName -ErrorAction Stop
                    Write-LogMessage "VM found: $($vm.Name)" -Level "SUCCESS"
                }
                catch {
                    Write-LogMessage "VM '$VMName' not found in resource group '$VMResourceGroupName'" -Level "ERROR"
                    throw "VM not found: $($_.Exception.Message)"
                }

                # Get backup policy
                try {
                    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -ErrorAction Stop
                    Write-LogMessage "Using backup policy: $($policy.Name)" -Level "INFO"
                }
                catch {
                    Write-LogMessage "Backup policy '$PolicyName' not found, using default policy" -Level "WARN"
                    $policies = Get-AzRecoveryServicesBackupProtectionPolicy
                    $policy = $policies | Where-Object { $_.WorkloadType -eq "AzureVM" } | Select-Object -First 1
                    if (-not $policy) {
                        throw "No suitable backup policy found"
                    }
                }

                # Enable backup protection
                Write-LogMessage "Enabling backup protection..." -Level "INFO"
                $result = Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $VMResourceGroupName -Name $VMName -Policy $policy
                
                Write-LogMessage "Backup protection enabled successfully" -Level "SUCCESS"
                Write-LogMessage "Policy: $($policy.Name)" -Level "INFO"
                
                $enableResult = [PSCustomObject]@{
                    VMName = $VMName
                    ResourceGroupName = $VMResourceGroupName
                    PolicyName = $policy.Name
                    VaultName = $VaultName
                    Status = "Enabled"
                    EnabledDate = Get-Date
                }
                
                return $enableResult
            }
        }

        'Disable' {
            Write-LogMessage "Disabling backup protection for VM: $VMName" -Level "WARN"
            
            if ($PSCmdlet.ShouldProcess($VMName, 'Disable backup protection')) {
                $vmBackup = Get-VMBackupItem -VMName $VMName -VMResourceGroupName $VMResourceGroupName
                
                if ($vmBackup) {
                    Write-LogMessage "WARNING: This will disable backup protection and may delete backup data" -Level "WARN"
                    $confirmation = Read-Host "Type 'DISABLE' to confirm disabling backup for $VMName"
                    
                    if ($confirmation -eq 'DISABLE') {
                        Disable-AzRecoveryServicesBackupProtection -Item $vmBackup -RemoveRecoveryPoints -Force
                        Write-LogMessage "Backup protection disabled for VM: $VMName" -Level "SUCCESS"
                        
                        return [PSCustomObject]@{
                            VMName = $VMName
                            Status = "Disabled"
                            DisabledDate = Get-Date
                        }
                    } else {
                        Write-LogMessage "Disable operation cancelled by user" -Level "INFO"
                        return $null
                    }
                } else {
                    Write-LogMessage "No backup configuration found for VM: $VMName" -Level "WARN"
                    return $null
                }
            }
        }

        'Policy' {
            Write-LogMessage "Retrieving backup policies" -Level "INFO"
            
            $policies = Get-AzRecoveryServicesBackupProtectionPolicy
            $vmPolicies = $policies | Where-Object { $_.WorkloadType -eq "AzureVM" }
            
            Write-LogMessage "Found $($vmPolicies.Count) VM backup policies" -Level "SUCCESS"
            
            $policyInfo = $vmPolicies | Select-Object @{
                Name = 'PolicyName'
                Expression = { $_.Name }
            }, @{
                Name = 'WorkloadType'
                Expression = { $_.WorkloadType }
            }, @{
                Name = 'BackupManagementType'
                Expression = { $_.BackupManagementType }
            }, @{
                Name = 'SchedulePolicy'
                Expression = { $_.SchedulePolicy.ScheduleRunFrequency }
            }, @{
                Name = 'RetentionPolicy'
                Expression = { $_.RetentionPolicy.DailySchedule.DurationCountInDays }
            }
            
            $policyInfo | Format-Table -AutoSize
            return $policyInfo
        }

        'Schedule' {
            Write-LogMessage "Getting backup schedule for VM: $VMName" -Level "INFO"
            
            $vmBackup = Get-VMBackupItem -VMName $VMName -VMResourceGroupName $VMResourceGroupName
            
            if ($vmBackup) {
                $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $vmBackup.PolicyName
                
                $scheduleInfo = [PSCustomObject]@{
                    VMName = $VMName
                    PolicyName = $policy.Name
                    ScheduleFrequency = $policy.SchedulePolicy.ScheduleRunFrequency
                    ScheduleRunTimes = $policy.SchedulePolicy.ScheduleRunTimes
                    ScheduleRunDays = $policy.SchedulePolicy.ScheduleRunDays
                    DailyRetentionDays = $policy.RetentionPolicy.DailySchedule.DurationCountInDays
                    WeeklyRetentionWeeks = $policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks
                    MonthlyRetentionMonths = $policy.RetentionPolicy.MonthlySchedule.DurationCountInMonths
                    YearlyRetentionYears = $policy.RetentionPolicy.YearlySchedule.DurationCountInYears
                }
                
                Write-LogMessage "Schedule information retrieved" -Level "SUCCESS"
                return $scheduleInfo
            } else {
                Write-LogMessage "No backup configuration found for VM: $VMName" -Level "WARN"
                return $null
            }
        }

        'Restore' {
            Write-LogMessage "Preparing restore operation for VM: $VMName" -Level "INFO"
            
            $vmBackup = Get-VMBackupItem -VMName $VMName -VMResourceGroupName $VMResourceGroupName
            
            if ($vmBackup) {
                if ($RestorePointDate) {
                    $startDate = Get-Date $RestorePointDate
                    $endDate = $startDate.AddDays(1)
                } else {
                    $endDate = Get-Date
                    $startDate = $endDate.AddDays(-30)
                }
                
                Write-LogMessage "Searching for recovery points between $startDate and $endDate" -Level "INFO"
                $recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint -Item $vmBackup -StartDate $startDate -EndDate $endDate
                
                if ($recoveryPoints) {
                    $restoreInfo = [PSCustomObject]@{
                        VMName = $VMName
                        AvailableRestorePoints = $recoveryPoints.Count
                        LatestRestorePoint = $recoveryPoints[0].RecoveryPointTime
                        OldestRestorePoint = $recoveryPoints[-1].RecoveryPointTime
                        RestorePoints = $recoveryPoints | Select-Object RecoveryPointTime, RecoveryPointType
                    }
                    
                    Write-LogMessage "Found $($recoveryPoints.Count) recovery points" -Level "SUCCESS"
                    Write-LogMessage "Use Azure Portal or REST API to perform actual restore operation" -Level "INFO"
                    
                    return $restoreInfo
                } else {
                    Write-LogMessage "No recovery points found for the specified date range" -Level "WARN"
                    return $null
                }
            } else {
                Write-LogMessage "No backup configuration found for VM: $VMName" -Level "WARN"
                return $null
            }
        }
    }
}
catch {
    Write-LogMessage "Backup operation failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error "Backup operation failed: $_"
    throw
}

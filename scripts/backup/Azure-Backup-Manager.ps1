#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Resources
#Requires -Modules Az.RecoveryServices, Az.Compute

<#`n.SYNOPSIS
    Comprehensive Azure backup management
.DESCRIPTION
    Manage Azure VM backups, policies, and recovery operations
.PARAMETER ResourceGroupName
    Resource group containing the recovery vault
.PARAMETER VaultName
    Recovery Services vault name
.PARAMETER VMName
    Virtual machine to backup
.PARAMETER Action
    Action to perform (Backup, Restore, Status, Policy)
.EXAMPLE
    ./Azure-Backup-Manager.ps1 -ResourceGroupName "rg-backups" -VaultName "vault-prod" -VMName "vm-web01" -Action "Backup"
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$VaultName,

    [Parameter(Mandatory)]
    [string]$VMName,

    [Parameter(Mandatory)]
    [ValidateSet('Backup', 'Status', 'Policy', 'Enable')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Managing backup for VM: $VMName"

    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName
    Set-AzRecoveryServicesVaultContext -Vault $vault

    switch ($Action) {
        'Status' {
            $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType "AzureVM" -WorkloadType "AzureVM"
            $vmBackup = $backupItems | Where-Object { $_.Name -like "*$VMName*" }

            if ($vmBackup) {
                [PSCustomObject]@{
                    VMName = $VMName
                    ProtectionStatus = $vmBackup.ProtectionStatus
                    LastBackupTime = $vmBackup.LastBackupTime
                    PolicyName = $vmBackup.PolicyName
                    BackupSizeInBytes = $vmBackup.BackupSizeInBytes
                }
            } else {
                Write-Warning "No backup found for VM: $VMName"
                return $null
            }
        }

        'Backup' {
            if ($PSCmdlet.ShouldProcess($VMName, 'Start backup')) {
                $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType "AzureVM" -WorkloadType "AzureVM"
                $vmBackup = $backupItems | Where-Object { $_.Name -like "*$VMName*" }

                if ($vmBackup) {
                    $job = Backup-AzRecoveryServicesBackupItem -Item $vmBackup
                    Write-Host "Backup job started for $VMName. Job ID: $($job.JobId)" -ForegroundColor Green
                    return $job
                } else {
                    Write-Error "VM $VMName is not configured for backup"
                }
            }
        }

        'Enable' {
            if ($PSCmdlet.ShouldProcess($VMName, 'Enable backup')) {
                $vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName
                $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"

                Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $ResourceGroupName -Name $VMName -Policy $policy
                Write-Host "Backup enabled for $VMName with default policy" -ForegroundColor Green
            }
        }

        'Policy' {
            $policies = Get-AzRecoveryServicesBackupProtectionPolicy
            $policies | Select-Object Name, WorkloadType, BackupManagementType | Format-Table -AutoSize
        }
    }
}
catch {
    Write-Error "Backup operation failed: $_"
    throw
}
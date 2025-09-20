#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Check backup status

.DESCRIPTION
    Check backup status
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Backup Status Checker
# Quick backup status verification for VMs and other resources
[CmdletBinding()]

    [Parameter()]
    [string]$ResourceGroupName,
    [Parameter()]
    [string]$VaultName,
    [Parameter()]
    [switch]$ShowUnprotected
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $vaults = if ($VaultName) {
        Get-AzRecoveryServicesVault -Name $VaultName
    } else {
        Get-AzRecoveryServicesVault
    }
    $backupReport = @()
    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault
        $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM
        $backupReport += [PSCustomObject]@{
            VaultName = $vault.Name
            ResourceGroup = $vault.ResourceGroupName
            ProtectedItems = $backupItems.Count
            LastBackupStatus = if ($backupItems) { ($backupItems | Sort-Object LastBackupTime -Descending)[0].LastBackupStatus } else { "No backups" }
        }
    }
    if ($ShowUnprotected) {
        $allVMs = Get-AzVM
        $protectedVMs = $vaults | ForEach-Object {
            Set-AzRecoveryServicesVaultContext -Vault $_
            Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM
        }
        $unprotectedVMs = $allVMs | Where-Object { $_.Name -notin $protectedVMs.Name }
        Write-Host "Unprotected VMs: $($unprotectedVMs.Count)"
        $unprotectedVMs | ForEach-Object { Write-Host "   $($_.Name)" }
    }
    $backupReport | Format-Table -AutoSize
    
} catch { throw }


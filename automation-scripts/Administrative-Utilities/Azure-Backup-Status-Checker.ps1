# Azure Backup Status Checker
# Quick backup status verification for VMs and other resources
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$VaultName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowUnprotected
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Backup Status Checker" -Version "1.0" -Description "Verify backup protection status"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.RecoveryServices'))) {
        throw "Azure connection validation failed"
    }

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
        Write-Host "Unprotected VMs: $($unprotectedVMs.Count)" -ForegroundColor Red
        $unprotectedVMs | ForEach-Object { Write-Host "  • $($_.Name)" -ForegroundColor Yellow }
    }

    $backupReport | Format-Table -AutoSize
    Write-Log "✅ Backup status check completed" -Level SUCCESS

} catch {
    Write-Log "❌ Backup status check failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}

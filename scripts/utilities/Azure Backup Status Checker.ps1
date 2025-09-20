#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Backup Status Checker

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
    [Parameter()]
    [switch]$ShowUnprotected
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    }
    $vaults = if ($VaultName) {
        Get-AzRecoveryServicesVault -Name $VaultName
    } else {
        Get-AzRecoveryServicesVault -ErrorAction Stop
    }
    $backupReport = @()
    foreach ($vault in $vaults) {
        Set-AzRecoveryServicesVaultContext -Vault $vault
        $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM
        $backupReport = $backupReport + [PSCustomObject]@{
            VaultName = $vault.Name
            ResourceGroup = $vault.ResourceGroupName
            ProtectedItems = $backupItems.Count
            LastBackupStatus = if ($backupItems) { ($backupItems | Sort-Object LastBackupTime -Descending)[0].LastBackupStatus } else { "No backups" }
        }
    }
    if ($ShowUnprotected) {
        $allVMs = Get-AzVM -ErrorAction Stop
$protectedVMs = $vaults | ForEach-Object {
            Set-AzRecoveryServicesVaultContext -Vault $_
            Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM
        }
$unprotectedVMs = $allVMs | Where-Object { $_.Name -notin $protectedVMs.Name }
        Write-Host "Unprotected VMs: $($unprotectedVMs.Count)" -ForegroundColor Red
        $unprotectedVMs | ForEach-Object { Write-Host "   $($_.Name)" -ForegroundColor Yellow }
    }
    $backupReport | Format-Table -AutoSize

} catch { throw }



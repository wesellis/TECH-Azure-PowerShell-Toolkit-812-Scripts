<#
.SYNOPSIS
    Azure Backup Status Checker

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
    We Enhanced Azure Backup Status Checker

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVaultName,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEShowUnprotected
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force
Show-Banner -ScriptName " Azure Backup Status Checker" -Version " 1.0" -Description " Verify backup protection status"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.RecoveryServices'))) {
        throw " Azure connection validation failed"
    }

    $vaults = if ($WEVaultName) {
        Get-AzRecoveryServicesVault -Name $WEVaultName
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
            LastBackupStatus = if ($backupItems) { ($backupItems | Sort-Object LastBackupTime -Descending)[0].LastBackupStatus } else { " No backups" }
        }
    }

    if ($WEShowUnprotected) {
        $allVMs = Get-AzVM -ErrorAction Stop
       ;  $protectedVMs = $vaults | ForEach-Object {
            Set-AzRecoveryServicesVaultContext -Vault $_
            Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM
        }
        
       ;  $unprotectedVMs = $allVMs | Where-Object { $_.Name -notin $protectedVMs.Name }
        Write-WELog " Unprotected VMs: $($unprotectedVMs.Count)" " INFO" -ForegroundColor Red
        $unprotectedVMs | ForEach-Object { Write-WELog "  • $($_.Name)" " INFO" -ForegroundColor Yellow }
    }

    $backupReport | Format-Table -AutoSize
    Write-Log " ✅ Backup status check completed" -Level SUCCESS

} catch {
    Write-Log " ❌ Backup status check failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices, Az.Compute

<#
.SYNOPSIS
    Check backup status

.DESCRIPTION
    Check backup status of Azure Recovery Services Vaults and virtual machines

.PARAMETER ResourceGroupName
    Name of the resource group (optional filter)

.PARAMETER VaultName
    Name of the Recovery Services Vault (optional filter)

.PARAMETER ShowUnprotected
    Show VMs that are not protected by any backup vault

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
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

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Host "Script Started" -ForegroundColor Green

try {
    # Ensure Azure connection
    if (-not (Get-AzContext)) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }

    # Get vaults
    $vaults = if ($VaultName) {
        if ($ResourceGroupName) {
            Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName
        } else {
            Get-AzRecoveryServicesVault -Name $VaultName
        }
    } elseif ($ResourceGroupName) {
        Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzRecoveryServicesVault
    }

    if (-not $vaults) {
        Write-Host "No Recovery Services Vaults found" -ForegroundColor Yellow
        return
    }

    # Build backup report
    $backupReport = @()

    foreach ($vault in $vaults) {
        Write-Verbose "Processing vault: $($vault.Name)"
        Set-AzRecoveryServicesVaultContext -Vault $vault

        $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -ErrorAction SilentlyContinue

        $lastBackupStatus = if ($backupItems -and $backupItems.Count -gt 0) {
            ($backupItems | Sort-Object LastBackupTime -Descending | Select-Object -First 1).LastBackupStatus
        } else {
            "No backups"
        }

        $backupReport += [PSCustomObject]@{
            VaultName = $vault.Name
            ResourceGroup = $vault.ResourceGroupName
            ProtectedItems = if ($backupItems) { $backupItems.Count } else { 0 }
            LastBackupStatus = $lastBackupStatus
        }
    }

    # Display report
    Write-Host "`nBackup Status Report:" -ForegroundColor Cyan
    $backupReport | Format-Table -AutoSize

    # Check for unprotected VMs if requested
    if ($ShowUnprotected) {
        Write-Host "`nChecking for unprotected VMs..." -ForegroundColor Yellow

        $allVMs = if ($ResourceGroupName) {
            Get-AzVM -ResourceGroupName $ResourceGroupName
        } else {
            Get-AzVM
        }

        # Get all protected VM names
        $protectedVMNames = @()
        foreach ($vault in $vaults) {
            Set-AzRecoveryServicesVaultContext -Vault $vault
            $items = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -ErrorAction SilentlyContinue
            if ($items) {
                $protectedVMNames += $items | ForEach-Object {
                    if ($_.VirtualMachineId) {
                        $_.VirtualMachineId.Split('/')[-1]
                    }
                }
            }
        }

        # Find unprotected VMs
        $unprotectedVMs = $allVMs | Where-Object { $_.Name -notin $protectedVMNames }

        if ($unprotectedVMs) {
            Write-Host "Unprotected VMs: $($unprotectedVMs.Count)" -ForegroundColor Red
            $unprotectedVMs | ForEach-Object {
                Write-Host "   $($_.Name)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "All VMs are protected" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
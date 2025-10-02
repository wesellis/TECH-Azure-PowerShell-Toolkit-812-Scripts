#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices, Az.Compute

<#
.SYNOPSIS
    Azure Backup Status Checker

.DESCRIPTION
    Checks the status of Azure Recovery Services Vaults and backup items,
    with optional reporting on unprotected VMs

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

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Host "Azure Backup Status Checker - Starting" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor DarkGray

try {
    # Ensure Azure connection
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }

    # Get vaults based on parameters
    Write-Verbose "Retrieving Recovery Services Vaults..."
    $vaults = if ($VaultName) {
        if ($ResourceGroupName) {
            Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction Stop
        } else {
            Get-AzRecoveryServicesVault -Name $VaultName -ErrorAction Stop
        }
    } elseif ($ResourceGroupName) {
        Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    } else {
        Get-AzRecoveryServicesVault -ErrorAction Stop
    }

    if (-not $vaults) {
        Write-Host "No Recovery Services Vaults found" -ForegroundColor Yellow
        return
    }

    Write-Host "Found $($vaults.Count) vault(s)" -ForegroundColor Cyan

    # Build backup report
    $backupReport = @()

    foreach ($vault in $vaults) {
        Write-Verbose "Processing vault: $($vault.Name)"

        # Set vault context
        Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop

        # Get backup items
        $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -ErrorAction SilentlyContinue

        # Get latest backup status
        $latestBackupStatus = if ($backupItems -and $backupItems.Count -gt 0) {
            $latestItem = $backupItems | Sort-Object LastBackupTime -Descending | Select-Object -First 1
            $latestItem.LastBackupStatus
        } else {
            "No backups"
        }

        # Add to report
        $backupReport += [PSCustomObject]@{
            VaultName = $vault.Name
            ResourceGroup = $vault.ResourceGroupName
            Location = $vault.Location
            ProtectedItems = if ($backupItems) { $backupItems.Count } else { 0 }
            LastBackupStatus = $latestBackupStatus
            Type = $vault.Type
        }
    }

    # Display backup report
    Write-Host "`nBackup Status Report:" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor DarkGray
    $backupReport | Format-Table -AutoSize

    # Check for unprotected VMs if requested
    if ($ShowUnprotected) {
        Write-Host "`nChecking for unprotected VMs..." -ForegroundColor Cyan

        # Get all VMs
        $allVMs = if ($ResourceGroupName) {
            Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        } else {
            Get-AzVM -ErrorAction Stop
        }

        # Get all protected VM names
        $protectedVMNames = @()
        foreach ($vault in $vaults) {
            Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop
            $items = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -ErrorAction SilentlyContinue
            if ($items) {
                $protectedVMNames += $items | ForEach-Object {
                    if ($_.VirtualMachineId) {
                        $vmId = $_.VirtualMachineId
                        $vmName = $vmId.Split('/')[-1]
                        $vmName
                    }
                }
            }
        }

        # Find unprotected VMs
        $unprotectedVMs = $allVMs | Where-Object { $_.Name -notin $protectedVMNames }

        if ($unprotectedVMs) {
            Write-Host "`nUnprotected VMs: $($unprotectedVMs.Count)" -ForegroundColor Red
            Write-Host "========================" -ForegroundColor DarkGray
            foreach ($vm in $unprotectedVMs) {
                Write-Host "  • $($vm.Name) (RG: $($vm.ResourceGroupName))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "`nAll VMs are protected!" -ForegroundColor Green
        }
    }

    # Summary statistics
    $totalProtectedItems = ($backupReport | Measure-Object -Property ProtectedItems -Sum).Sum
    $healthyBackups = ($backupReport | Where-Object { $_.LastBackupStatus -eq "Completed" }).Count

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "========" -ForegroundColor DarkGray
    Write-Host "Total Vaults: $($vaults.Count)"
    Write-Host "Total Protected Items: $totalProtectedItems"
    Write-Host "Vaults with Healthy Backups: $healthyBackups"

    Write-Host "`nBackup status check completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
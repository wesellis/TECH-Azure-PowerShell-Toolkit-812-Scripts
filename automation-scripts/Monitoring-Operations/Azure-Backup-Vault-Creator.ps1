#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageType = "GeoRedundant"
)

#region Functions

Write-Information "Creating Recovery Services Vault: $VaultName"

# Create Recovery Services Vault
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $VaultName
    Location = $Location
}
$Vault @params

# Set vault context
Set-AzRecoveryServicesVaultContext -Vault $Vault

# Configure storage redundancy
$params = @{
    BackupStorageRedundancy = $StorageType
    ErrorAction = "Stop"
    Vault = $Vault
}
Set-AzRecoveryServicesBackupProperty @params

Write-Information " Recovery Services Vault created successfully:"
Write-Information "  Name: $($Vault.Name)"
Write-Information "  Location: $($Vault.Location)"
Write-Information "  Storage Type: $StorageType"
Write-Information "  Resource ID: $($Vault.ID)"

# Display backup policies
Write-Information "`nDefault Backup Policies:"
$Policies = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $Vault.ID
foreach ($Policy in $Policies) {
    Write-Information "  • $($Policy.Name) [$($Policy.WorkloadType)]"
}

Write-Information "`nVault Capabilities:"
Write-Information "• VM backup and restore"
Write-Information "• File and folder backup"
Write-Information "• SQL Server backup"
Write-Information "• Azure File Shares backup"
Write-Information "• Cross-region restore"
Write-Information "• Point-in-time recovery"

Write-Information "`nNext Steps:"
Write-Information "1. Configure backup policies"
Write-Information "2. Enable backup for resources"
Write-Information "3. Schedule backup jobs"
Write-Information "4. Test restore procedures"
Write-Information "5. Monitor backup status"

Write-Information "`nSupported Workloads:"
Write-Information "• Azure Virtual Machines"
Write-Information "• Azure File Shares"
Write-Information "• SQL Server in Azure VMs"
Write-Information "• SAP HANA in Azure VMs"


#endregion

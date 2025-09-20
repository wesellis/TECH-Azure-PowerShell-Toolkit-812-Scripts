#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VaultName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$StorageType = "GeoRedundant"
)
Write-Host "Creating Recovery Services Vault: $VaultName"
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
Write-Host "Recovery Services Vault created successfully:"
Write-Host "Name: $($Vault.Name)"
Write-Host "Location: $($Vault.Location)"
Write-Host "Storage Type: $StorageType"
Write-Host "Resource ID: $($Vault.ID)"
# Display backup policies
Write-Host "`nDefault Backup Policies:"
$Policies = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $Vault.ID
foreach ($Policy in $Policies) {
    Write-Host "   $($Policy.Name) [$($Policy.WorkloadType)]"
}
Write-Host "`nVault Capabilities:"
Write-Host "VM backup and restore"
Write-Host "File and folder backup"
Write-Host "SQL Server backup"
Write-Host "Azure File Shares backup"
Write-Host "Cross-region restore"
Write-Host "Point-in-time recovery"
Write-Host "`nNext Steps:"
Write-Host "1. Configure backup policies"
Write-Host "2. Enable backup for resources"
Write-Host "3. Schedule backup jobs"
Write-Host "4. Test restore procedures"
Write-Host "5. Monitor backup status"
Write-Host "`nSupported Workloads:"
Write-Host "Azure Virtual Machines"
Write-Host "Azure File Shares"
Write-Host "SQL Server in Azure VMs"
Write-Host "SAP HANA in Azure VMs"


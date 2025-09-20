#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Backup Vault Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(ValueFromPipeline)]`n    [string]$StorageType = "GeoRedundant"
)
Write-Host "Creating Recovery Services Vault: $VaultName"
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $VaultName
    Location = $Location
}
$Vault @params
Set-AzRecoveryServicesVaultContext -Vault $Vault
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
Write-Host " `nDefault Backup Policies:" ;
$Policies = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $Vault.ID
foreach ($Policy in $Policies) {
    Write-Host "   $($Policy.Name) [$($Policy.WorkloadType)]"
}
Write-Host " `nVault Capabilities:"
Write-Host "VM backup and restore"
Write-Host "File and folder backup"
Write-Host "SQL Server backup"
Write-Host "Azure File Shares backup"
Write-Host "Cross-region restore"
Write-Host "Point-in-time recovery"
Write-Host " `nNext Steps:"
Write-Host " 1. Configure backup policies"
Write-Host " 2. Enable backup for resources"
Write-Host " 3. Schedule backup jobs"
Write-Host " 4. Test restore procedures"
Write-Host " 5. Monitor backup status"
Write-Host " `nSupported Workloads:"
Write-Host "Azure Virtual Machines"
Write-Host "Azure File Shares"
Write-Host "SQL Server in Azure VMs"
Write-Host "SAP HANA in Azure VMs"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n


#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Azure Backup Vault Creator

.DESCRIPTION
    Creates and configures an Azure Recovery Services Vault for backup operations

.PARAMETER ResourceGroupName
    Name of the resource group where the vault will be created

.PARAMETER VaultName
    Name of the Recovery Services Vault

.PARAMETER Location
    Azure region for the vault

.PARAMETER StorageType
    Storage redundancy type (GeoRedundant, LocallyRedundant, ZoneRedundant)

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [ValidateSet('GeoRedundant', 'LocallyRedundant', 'ZoneRedundant')]
    [string]$StorageType = 'GeoRedundant'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $logEntry = "$timestamp [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Starting Recovery Services Vault creation process" -Level INFO

    # Check if resource group exists, create if it doesn't
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-ColorOutput "Creating resource group: $ResourceGroupName" -Level INFO
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
    } else {
        Write-ColorOutput "Using existing resource group: $ResourceGroupName" -Level INFO
    }

    # Check if vault already exists
    $existingVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $VaultName -ErrorAction SilentlyContinue
    if ($existingVault) {
        Write-ColorOutput "Vault '$VaultName' already exists in resource group '$ResourceGroupName'" -Level WARN
        $vault = $existingVault
    } else {
        # Create Recovery Services Vault
        Write-ColorOutput "Creating Recovery Services Vault: $VaultName" -Level INFO
        $vaultParams = @{
            ResourceGroupName = $ResourceGroupName
            Name = $VaultName
            Location = $Location
            ErrorAction = "Stop"
        }
        $vault = New-AzRecoveryServicesVault @vaultParams
        Write-ColorOutput "Recovery Services Vault created successfully" -Level SUCCESS
    }

    # Set vault context
    Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop

    # Configure backup storage redundancy
    Write-ColorOutput "Configuring storage redundancy: $StorageType" -Level INFO
    $backupPropertyParams = @{
        Vault = $vault
        BackupStorageRedundancy = $StorageType
        ErrorAction = "Stop"
    }
    Set-AzRecoveryServicesBackupProperty @backupPropertyParams

    # Display vault information
    Write-ColorOutput "`nVault Configuration Summary:" -Level SUCCESS
    Write-Host "================================"
    Write-Host "Name: $($vault.Name)"
    Write-Host "Location: $($vault.Location)"
    Write-Host "Resource Group: $($vault.ResourceGroupName)"
    Write-Host "Storage Type: $StorageType"
    Write-Host "Resource ID: $($vault.ID)"
    Write-Host "Type: $($vault.Type)"

    # Get and display default backup policies
    Write-ColorOutput "`nDefault Backup Policies:" -Level INFO
    $policies = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $vault.ID -ErrorAction SilentlyContinue
    if ($policies) {
        foreach ($policy in $policies) {
            Write-Host "  - $($policy.Name) [Workload: $($policy.WorkloadType)]"
        }
    } else {
        Write-Host "  No default policies found"
    }

    # Display vault capabilities
    Write-ColorOutput "`nVault Capabilities:" -Level INFO
    $capabilities = @(
        "Azure Virtual Machine backup and restore",
        "Azure File Shares backup",
        "SQL Server in Azure VMs backup",
        "SAP HANA in Azure VMs backup",
        "Azure Database for PostgreSQL backup",
        "Cross-region restore (if GeoRedundant)",
        "Point-in-time recovery",
        "Soft delete protection",
        "Private endpoint support"
    )
    foreach ($capability in $capabilities) {
        Write-Host "  • $capability"
    }

    # Next steps
    Write-ColorOutput "`nRecommended Next Steps:" -Level INFO
    $nextSteps = @(
        "1. Configure backup policies for your workloads",
        "2. Enable backup for your Azure resources",
        "3. Configure backup schedules and retention policies",
        "4. Test restore procedures to ensure recovery readiness",
        "5. Set up monitoring and alerting for backup jobs",
        "6. Review and configure security settings (RBAC, encryption)",
        "7. Enable diagnostic settings for audit logging"
    )
    foreach ($step in $nextSteps) {
        Write-Host "  $step"
    }

    Write-ColorOutput "`nVault creation and configuration completed successfully!" -Level SUCCESS
}
catch {
    Write-ColorOutput "Failed to create or configure Recovery Services Vault: $($_.Exception.Message)" -Level ERROR
    throw
}
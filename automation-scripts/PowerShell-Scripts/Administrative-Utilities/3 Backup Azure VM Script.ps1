#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Backup Azure VM Script

.DESCRIPTION
    Create and monitor Azure VM backup using Recovery Services
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    LastModified: 2025-09-19
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
[OutputType([bool])]
 {
function Write-Host {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
        [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,
        [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
        [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultResourceGroup,
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 30
    )
    try {
        # Ensure Az.RecoveryServices module is imported
        if (-not (Get-Module -Name Az.RecoveryServices -ListAvailable)) {
            Write-Host "Installing Az.RecoveryServices module..." -ForegroundColor Yellow
            Install-Module -Name Az.RecoveryServices -Force -AllowClobber
        }
        Import-Module -Name Az.RecoveryServices
        # Get VM details
        Write-Host "Verifying VM existence..." -ForegroundColor Yellow
        $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
        # Get Recovery Services Vault
        Write-Host "Accessing Recovery Services Vault..." -ForegroundColor Yellow
        $vault = Get-AzRecoveryServicesVault -ResourceGroupName $VaultResourceGroup -Name $VaultName
        # Set vault context
        Set-AzRecoveryServicesVaultContext -Vault $vault
        # Start backup job
        Write-Host "Initiating backup job..." -ForegroundColor Yellow
        $backupJob = Start-AzRecoveryServicesAsrBackupNow -Name $VMName
        # Create backup details object
        $backupDetails = [PSCustomObject]@{
            VMName = $VMName
            ResourceGroup = $ResourceGroupName
            VaultName = $VaultName
            BackupJobId = $backupJob.JobId
            StartTime = Get-Date
            Status = $backupJob.Status
            RetentionDays = $RetentionDays
        }
        # Generate HTML report
        New-HTML -FilePath " .\VMBackupReport.html" -ShowHTML {
            New-HTMLTable -DataTable @($backupDetails) -Title "VM Backup Operation Report" {
                New-HTMLTableHeader -Title "VM Backup - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -BackgroundColor '#007bff' -Color '#ffffff'
            }
        }
        # Export CSV report
        $backupDetails | Export-Csv -Path " .\VMBackupReport.csv" -NoTypeInformation
        # Monitor backup progress
        Write-Host "Monitoring backup progress..." -ForegroundColor Yellow
        while ($backupJob.Status -eq "InProgress") {
            $backupJob = Get-AzRecoveryServicesBackupJob -Job $backupJob
            Write-Host "Backup Status: $($backupJob.Status) - $(Get-Date)" -ForegroundColor Cyan
            Start-Sleep -Seconds 30
        }
        return $backupDetails
    }
    catch {
        Write-Error "Failed to create VM backup: $_"
        throw
    }
}
try {
    Write-Host "Starting Azure VM backup process..." -ForegroundColor Cyan
    # Backup parameters for ArcGisS1
$backupParams = @{
        VMName = 'ArcGisS1'
        ResourceGroupName = 'anteausa'
        VaultName = '' # Need vault name
        VaultResourceGroup = '' # Need vault resource group
        RetentionDays = 30
    }
    Write-Host " `nInitiating backup with following parameters:" -ForegroundColor Yellow
    $backupParams | Format-Table -AutoSize
    # Create backup
    Write-Host " `nCreating backup..." -ForegroundColor Yellow
$backup = New-AzureVMBackup @backupParams
    Write-Host " `nBackup operation completed!" -ForegroundColor Green
    Write-Host "Backup Job ID: $($backup.BackupJobId)" -ForegroundColor Green
    Write-Host "Final Status: $($backup.Status)" -ForegroundColor Green
}
catch {
    Write-Host "Error during backup process: $_" -ForegroundColor Red
    throw
}


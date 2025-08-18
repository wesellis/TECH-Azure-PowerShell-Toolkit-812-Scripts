<#
.SYNOPSIS
    We Enhanced 3 Backup Azure Vm Script

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

function WE-New-AzureVMBackup {
    

function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory = $true)]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVMName,
        
        [Parameter(Mandatory = $true)]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVaultName,
        
        [Parameter(Mandatory = $true)]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVaultResourceGroup,
        
        [Parameter(Mandatory = $false)]
        [int]$WERetentionDays = 30
    )
    
    try {
        # Ensure Az.RecoveryServices module is imported
        if (-not (Get-Module -Name Az.RecoveryServices -ListAvailable)) {
            Write-WELog " Installing Az.RecoveryServices module..." " INFO" -ForegroundColor Yellow
            Install-Module -Name Az.RecoveryServices -Force -AllowClobber
        }
        Import-Module -Name Az.RecoveryServices -ErrorAction Stop

        # Get VM details
        Write-WELog " Verifying VM existence..." " INFO" -ForegroundColor Yellow
        $vm = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName -ErrorAction Stop

        # Get Recovery Services Vault
        Write-WELog " Accessing Recovery Services Vault..." " INFO" -ForegroundColor Yellow
        $vault = Get-AzRecoveryServicesVault -ResourceGroupName $WEVaultResourceGroup -Name $WEVaultName -ErrorAction Stop
        
        # Set vault context
        Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop

        # Start backup job
        Write-WELog " Initiating backup job..." " INFO" -ForegroundColor Yellow
        $backupJob = Start-AzRecoveryServicesAsrBackupNow -Name $WEVMName -ErrorAction Stop

        # Create backup details object
        $backupDetails = [PSCustomObject]@{
            VMName = $WEVMName
            ResourceGroup = $WEResourceGroupName
            VaultName = $WEVaultName
            BackupJobId = $backupJob.JobId
            StartTime = Get-Date
            Status = $backupJob.Status
            RetentionDays = $WERetentionDays
        }

        # Generate HTML report
        New-HTML -FilePath " .\VMBackupReport.html" -ShowHTML {
            New-HTMLTable -DataTable @($backupDetails) -Title " VM Backup Operation Report" {
                New-HTMLTableHeader -Title " VM Backup - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -BackgroundColor '#007bff' -Color '#ffffff'
            }
        }

        # Export CSV report
        $backupDetails | Export-Csv -Path " .\VMBackupReport.csv" -NoTypeInformation

        # Monitor backup progress
        Write-WELog " Monitoring backup progress..." " INFO" -ForegroundColor Yellow
        while ($backupJob.Status -eq " InProgress") {
            $backupJob = Get-AzRecoveryServicesBackupJob -Job $backupJob
            Write-WELog " Backup Status: $($backupJob.Status) - $(Get-Date)" " INFO" -ForegroundColor Cyan
            Start-Sleep -Seconds 30
        }

        return $backupDetails
    }
    catch {
        Write-Error " Failed to create VM backup: $_"
        throw
    }
}


try {
    Write-WELog " Starting Azure VM backup process..." " INFO" -ForegroundColor Cyan
    
    # Backup parameters for ArcGisS1
    $backupParams = @{
        VMName = 'ArcGisS1'
        ResourceGroupName = 'anteausa'
        VaultName = '' # Need vault name
        VaultResourceGroup = '' # Need vault resource group
        RetentionDays = 30
    }
    
    Write-WELog " `nInitiating backup with following parameters:" " INFO" -ForegroundColor Yellow
    $backupParams | Format-Table -AutoSize
    
    # Create backup
    Write-WELog " `nCreating backup..." " INFO" -ForegroundColor Yellow
   ;  $backup = New-AzureVMBackup @backupParams
    
    Write-WELog " `nBackup operation completed!" " INFO" -ForegroundColor Green
    Write-WELog " Backup Job ID: $($backup.BackupJobId)" " INFO" -ForegroundColor Green
    Write-WELog " Final Status: $($backup.Status)" " INFO" -ForegroundColor Green
}
catch {
    Write-WELog " Error during backup process: $_" " INFO" -ForegroundColor Red
    throw
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
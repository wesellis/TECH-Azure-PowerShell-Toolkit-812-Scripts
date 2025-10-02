#Requires -Version 7.4

<#
.SYNOPSIS
    Azure VM backup and restore overview documentation

.DESCRIPTION
    This script provides documentation and guidance for Azure VM backup and restore operations.
    It outlines the important differences between portal-based and PowerShell-based restore operations
    and provides step-by-step guidance for VM recovery procedures.

.NOTES
    Azure VM Restore Process Overview:

    There's an important difference between restoring a VM using the Azure portal and restoring
    a VM using PowerShell. With PowerShell, the restore operation is complete once the disks
    and configuration information from the recovery point are created. The restore operation
    doesn't create the virtual machine. To create a virtual machine from disk, additional steps
    are required.

    If you don't want to restore the entire VM, but want to restore or recover a few files
    from an Azure VM backup, refer to the file recovery section.

    To restore backup data, identify the backed-up item and the recovery point that holds
    the point-in-time data. Use Restore-AzRecoveryServicesBackupItem to restore data from
    the vault to your account.

.EXAMPLE
    The basic steps to restore an Azure VM are:
    1. Select the VM
    2. Choose a recovery point
    3. Restore the disks
    4. Create the VM from stored disks

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Host "Azure VM Backup and Restore Overview" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "This script serves as documentation for Azure VM backup and restore operations." -ForegroundColor Yellow
Write-Host ""
Write-Host "Key Points:" -ForegroundColor Cyan
Write-Host "- PowerShell restore operations only restore disks and configuration" -ForegroundColor White
Write-Host "- VM creation is a separate step after disk restoration" -ForegroundColor White
Write-Host "- File-level recovery is available for selective restore operations" -ForegroundColor White
Write-Host ""
Write-Host "For actual backup and restore operations, please use the specific scripts:" -ForegroundColor Yellow
Write-Host "- Backup-AzRecoveryServicesBackupItem.ps1" -ForegroundColor White
Write-Host "- Restore-AzRecoveryServicesBackupItem.ps1" -ForegroundColor White
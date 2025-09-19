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
# Azure Disk Encryption Status Checker
# Check encryption status of managed disks and VMs
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowUnencrypted,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\encryption-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName "Azure Disk Encryption Status Checker" -Version "1.0" -Description "Check disk and VM encryption status"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

    $encryptionStatus = @()

    # Check VM encryption
    $vms = if ($ResourceGroupName) {
        Get-AzVM -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzVM -ErrorAction Stop
    }

    foreach ($vm in $vms) {
        $vmStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        
        $encryptionStatus += [PSCustomObject]@{
            ResourceType = "VM"
            ResourceName = $vm.Name
            ResourceGroup = $vm.ResourceGroupName
            OSEncrypted = $vmStatus.OsVolumeEncrypted
            DataEncrypted = $vmStatus.DataVolumesEncrypted
            EncryptionSettings = $vmStatus.OsVolumeEncryptionSettings
        }
    }

    # Check managed disk encryption
    $disks = if ($ResourceGroupName) {
        Get-AzDisk -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzDisk -ErrorAction Stop
    }

    foreach ($disk in $disks) {
        $isEncrypted = $disk.EncryptionSettingsCollection -or $disk.Encryption.Type -ne "EncryptionAtRestWithPlatformKey"
        
        $encryptionStatus += [PSCustomObject]@{
            ResourceType = "Disk"
            ResourceName = $disk.Name
            ResourceGroup = $disk.ResourceGroupName
            OSEncrypted = $isEncrypted
            DataEncrypted = "N/A"
            EncryptionSettings = $disk.Encryption.Type
        }
    }

    if ($ShowUnencrypted) {
        $unencrypted = $encryptionStatus | Where-Object { $_.OSEncrypted -eq $false -or $_.OSEncrypted -eq "NotEncrypted" }
        Write-Information "Unencrypted Resources: $($unencrypted.Count)"
        $unencrypted | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted
    } else {
        Write-Information "Encryption Status Summary:"
        $encryptionStatus | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted, DataEncrypted
    }

    if ($ExportReport) {
        $encryptionStatus | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Log "[OK] Encryption report exported to: $OutputPath" -Level SUCCESS
    }

    $totalResources = $encryptionStatus.Count
    $encryptedResources = ($encryptionStatus | Where-Object { $_.OSEncrypted -eq $true -or $_.OSEncrypted -eq "Encrypted" }).Count
    $encryptionRate = if ($totalResources -gt 0) { [math]::Round(($encryptedResources / $totalResources) * 100, 2) } else { 0 }

    Write-Information "Encryption Summary:"
    Write-Information "  Total Resources: $totalResources"
    Write-Information "  Encrypted: $encryptedResources"
    Write-Information "  Encryption Rate: $encryptionRate%"

} catch {
    Write-Log " Encryption status check failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion

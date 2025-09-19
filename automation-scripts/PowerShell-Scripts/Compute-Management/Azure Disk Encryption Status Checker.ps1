#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Disk Encryption Status Checker

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Disk Encryption Status Checker

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEShowUnencrypted,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\encryption-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName " Azure Disk Encryption Status Checker" -Version " 1.0" -Description " Check disk and VM encryption status"

try {
    if (-not (Test-AzureConnection)) { throw " Azure connection validation failed" }

    $encryptionStatus = @()

    # Check VM encryption
    $vms = if ($WEResourceGroupName) {
        Get-AzVM -ResourceGroupName $WEResourceGroupName
    } else {
        Get-AzVM -ErrorAction Stop
    }

    foreach ($vm in $vms) {
        $vmStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        
        $encryptionStatus = $encryptionStatus + [PSCustomObject]@{
            ResourceType = " VM"
            ResourceName = $vm.Name
            ResourceGroup = $vm.ResourceGroupName
            OSEncrypted = $vmStatus.OsVolumeEncrypted
            DataEncrypted = $vmStatus.DataVolumesEncrypted
            EncryptionSettings = $vmStatus.OsVolumeEncryptionSettings
        }
    }

    # Check managed disk encryption
    $disks = if ($WEResourceGroupName) {
        Get-AzDisk -ResourceGroupName $WEResourceGroupName
    } else {
        Get-AzDisk -ErrorAction Stop
    }

    foreach ($disk in $disks) {
        $isEncrypted = $disk.EncryptionSettingsCollection -or $disk.Encryption.Type -ne " EncryptionAtRestWithPlatformKey"
        
        $encryptionStatus = $encryptionStatus + [PSCustomObject]@{
            ResourceType = " Disk"
            ResourceName = $disk.Name
            ResourceGroup = $disk.ResourceGroupName
            OSEncrypted = $isEncrypted
            DataEncrypted = " N/A"
            EncryptionSettings = $disk.Encryption.Type
        }
    }

    if ($WEShowUnencrypted) {
        $unencrypted = $encryptionStatus | Where-Object { $_.OSEncrypted -eq $false -or $_.OSEncrypted -eq " NotEncrypted" }
        Write-WELog " Unencrypted Resources: $($unencrypted.Count)" " INFO" -ForegroundColor Red
        $unencrypted | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted
    } else {
        Write-WELog " Encryption Status Summary:" " INFO" -ForegroundColor Cyan
        $encryptionStatus | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted, DataEncrypted
    }

    if ($WEExportReport) {
        $encryptionStatus | Export-Csv -Path $WEOutputPath -NoTypeInformation
        Write-Log " [OK] Encryption report exported to: $WEOutputPath" -Level SUCCESS
    }

    $totalResources = $encryptionStatus.Count
   ;  $encryptedResources = ($encryptionStatus | Where-Object { $_.OSEncrypted -eq $true -or $_.OSEncrypted -eq " Encrypted" }).Count
   ;  $encryptionRate = if ($totalResources -gt 0) { [math]::Round(($encryptedResources / $totalResources) * 100, 2) } else { 0 }

    Write-WELog " Encryption Summary:" " INFO" -ForegroundColor Green
    Write-WELog "  Total Resources: $totalResources" " INFO" -ForegroundColor White
    Write-WELog "  Encrypted: $encryptedResources" " INFO" -ForegroundColor Green
    Write-WELog "  Encryption Rate: $encryptionRate%" " INFO" -ForegroundColor Cyan

} catch {
    Write-Log "  Encryption status check failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

<#
.SYNOPSIS
    Azure Disk Encryption Status Checker

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [switch]$ShowUnencrypted,
    [Parameter()]
    [switch]$ExportReport,
    [Parameter()]
    [string]$OutputPath = " .\encryption-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $encryptionStatus = @()
    # Check VM encryption
    $vms = if ($ResourceGroupName) {
        Get-AzVM -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzVM -ErrorAction Stop
    }
    foreach ($vm in $vms) {
        $vmStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        $encryptionStatus = $encryptionStatus + [PSCustomObject]@{
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
        $encryptionStatus = $encryptionStatus + [PSCustomObject]@{
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
        Write-Host "Unencrypted Resources: $($unencrypted.Count)" -ForegroundColor Red
        $unencrypted | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted
    } else {
        Write-Host "Encryption Status Summary:" -ForegroundColor Cyan
        $encryptionStatus | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted, DataEncrypted
    }
    if ($ExportReport) {
        $encryptionStatus | Export-Csv -Path $OutputPath -NoTypeInformation

    }
    $totalResources = $encryptionStatus.Count
$encryptedResources = ($encryptionStatus | Where-Object { $_.OSEncrypted -eq $true -or $_.OSEncrypted -eq "Encrypted" }).Count
$encryptionRate = if ($totalResources -gt 0) { [math]::Round(($encryptedResources / $totalResources) * 100, 2) } else { 0 }
    Write-Host "Encryption Summary:" -ForegroundColor Green
    Write-Host "Total Resources: $totalResources" -ForegroundColor White
    Write-Host "Encrypted: $encryptedResources" -ForegroundColor Green
    Write-Host "Encryption Rate: $encryptionRate%" -ForegroundColor Cyan
} catch { throw }\n
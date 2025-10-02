#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Disk Encryption Status Checker

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [switch]$ShowUnencrypted,
    [Parameter()]
    [switch]$ExportReport,
    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = " .\encryption-status-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    [string]$EncryptionStatus = @()
    [string]$vms = if ($ResourceGroupName) {
        Get-AzVM -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzVM -ErrorAction Stop
    }
    foreach ($vm in $vms) {
    $VmStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
    [string]$EncryptionStatus = $EncryptionStatus + [PSCustomObject]@{
            ResourceType = "VM"
            ResourceName = $vm.Name
            ResourceGroup = $vm.ResourceGroupName
            OSEncrypted = $VmStatus.OsVolumeEncrypted
            DataEncrypted = $VmStatus.DataVolumesEncrypted
            EncryptionSettings = $VmStatus.OsVolumeEncryptionSettings
        }
    }
    [string]$disks = if ($ResourceGroupName) {
        Get-AzDisk -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzDisk -ErrorAction Stop
    }
    foreach ($disk in $disks) {
    [string]$IsEncrypted = $disk.EncryptionSettingsCollection -or $disk.Encryption.Type -ne "EncryptionAtRestWithPlatformKey"
    [string]$EncryptionStatus = $EncryptionStatus + [PSCustomObject]@{
            ResourceType = "Disk"
            ResourceName = $disk.Name
            ResourceGroup = $disk.ResourceGroupName
            OSEncrypted = $IsEncrypted
            DataEncrypted = "N/A"
            EncryptionSettings = $disk.Encryption.Type
        }
    }
    if ($ShowUnencrypted) {
    [string]$unencrypted = $EncryptionStatus | Where-Object { $_.OSEncrypted -eq $false -or $_.OSEncrypted -eq "NotEncrypted" }
        Write-Host "Unencrypted Resources: $($unencrypted.Count)" -ForegroundColor Green
    [string]$unencrypted | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted
    } else {
        Write-Host "Encryption Status Summary:" -ForegroundColor Green
    [string]$EncryptionStatus | Format-Table ResourceType, ResourceName, ResourceGroup, OSEncrypted, DataEncrypted
    }
    if ($ExportReport) {
    [string]$EncryptionStatus | Export-Csv -Path $OutputPath -NoTypeInformation

    }
    [string]$TotalResources = $EncryptionStatus.Count
    [string]$EncryptedResources = ($EncryptionStatus | Where-Object { $_.OSEncrypted -eq $true -or $_.OSEncrypted -eq "Encrypted" }).Count
    [string]$EncryptionRate = if ($TotalResources -gt 0) { [math]::Round(($EncryptedResources / $TotalResources) * 100, 2) } else { 0 }
    Write-Host "Encryption Summary:" -ForegroundColor Green
    Write-Host "Total Resources: $TotalResources" -ForegroundColor Green
    Write-Host "Encrypted: $EncryptedResources" -ForegroundColor Green
    Write-Host "Encryption Rate: $EncryptionRate%" -ForegroundColor Green
} catch { throw`n}

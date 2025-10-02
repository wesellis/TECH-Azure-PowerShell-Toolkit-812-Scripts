#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Resizes Azure managed disks with safety checks

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Resizes Azure managed disks with basic validation and safety checks.
    Supports both OS and data disks.
.PARAMETER ResourceGroupName
    Name of the resource group containing the disk
.PARAMETER DiskName
    Name of the managed disk to resize
.PARAMETER NewSizeGB
    New size for the disk in GB (must be larger than current size)
.PARAMETER Force
    Skip confirmation
    .\Azure-Disk-Resize-Tool.ps1 -ResourceGroupName "RG-Production" -DiskName "VM-WebServer01_disk1" -NewSizeGB 128
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DiskName,
    [Parameter(Mandatory = $true)]
    [int]$NewSizeGB,
    [Parameter()]
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    Write-Host "Retrieving disk information..." -ForegroundColor Green
    $disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName
    if (-not $disk) {
        throw "Disk '$DiskName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "Current disk size: $($disk.DiskSizeGB) GB" -ForegroundColor Green
    Write-Host "New disk size: $NewSizeGB GB" -ForegroundColor Green
    if ($NewSizeGB -le $disk.DiskSizeGB) {
        throw "New size ($NewSizeGB GB) must be larger than current size ($($disk.DiskSizeGB) GB)"
    }
    if ($disk.ManagedBy) {
        $VmName = ($disk.ManagedBy -split '/')[-1]
        Write-Host "Warning: Disk is attached to VM: $VmName" -ForegroundColor Green
    }
    if (-not $Force) {
        $confirmation = Read-Host "Resize disk '$DiskName' from $($disk.DiskSizeGB) GB to $NewSizeGB GB? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "Resizing disk..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($DiskName, "Resize disk to $NewSizeGB GB")) {
        $disk.DiskSizeGB = $NewSizeGB
        Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName -Disk $disk
        Write-Host "Disk resized successfully!" -ForegroundColor Green

} catch {
    Write-Error "Failed to resize disk: $_"
    throw`n}

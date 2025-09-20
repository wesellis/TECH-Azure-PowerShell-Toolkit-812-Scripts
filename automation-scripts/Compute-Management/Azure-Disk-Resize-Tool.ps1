#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Resizes Azure managed disks with safety checks

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding()]

    [Parameter(Mandatory = $true)]
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
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    # Get current disk information
    Write-Host "Retrieving disk information..." -ForegroundColor Yellow
    $disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName
    if (-not $disk) {
        throw "Disk '$DiskName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "Current disk size: $($disk.DiskSizeGB) GB" -ForegroundColor Cyan
    Write-Host "New disk size: $NewSizeGB GB" -ForegroundColor Cyan
    # Validate new size
    if ($NewSizeGB -le $disk.DiskSizeGB) {
        throw "New size ($NewSizeGB GB) must be larger than current size ($($disk.DiskSizeGB) GB)"
    }
    # Check if disk is attached to a VM
    if ($disk.ManagedBy) {
        $vmName = ($disk.ManagedBy -split '/')[-1]
        Write-Host "Warning: Disk is attached to VM: $vmName" -ForegroundColor Yellow
    }
    # Confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Resize disk '$DiskName' from $($disk.DiskSizeGB) GB to $NewSizeGB GB? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    # Perform the resize
    Write-Host "Resizing disk..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($DiskName, "Resize disk to $NewSizeGB GB")) {
        $disk.DiskSizeGB = $NewSizeGB
        Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName -Disk $disk
        Write-Host "Disk resized successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to resize disk: $_"
    throw
}\n


#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Creates snapshots of Azure managed disks with validation and tagging

.DESCRIPTION
    Creates point-in-time snapshots of Azure managed disks with proper validation,
    tagging, and cleanup options. Supports both manual and automated snapshot creation.
.PARAMETER ResourceGroupName
    Name of the resource group containing the disk
.PARAMETER DiskName
    Name of the managed disk to snapshot
.PARAMETER SnapshotName
    Name for the snapshot (auto-generated if not provided)
.PARAMETER Tags
    Hashtable of tags to apply to the snapshot
.PARAMETER Force
    Skip confirmation
.PARAMETER RetentionDays
    Days to retain the snapshot (adds retention tag)
    .\Azure-Disk-Snapshot-Creator.ps1 -ResourceGroupName "RG-Production" -DiskName "VM-WebServer01_OsDisk"
    .\Azure-Disk-Snapshot-Creator.ps1 -ResourceGroupName "RG-Production" -DiskName "VM-DB01_DataDisk" -RetentionDays 30 -Tags @{Backup="Daily"}
#>
[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding()]

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DiskName,
    [Parameter()]
    [string]$SnapshotName,
    [Parameter()]
    [hashtable]$Tags = @{},
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [int]$RetentionDays
)
$ErrorActionPreference = 'Stop'
try {
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    # Auto-generate snapshot name if not provided
    if (-not $SnapshotName) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $SnapshotName = "$DiskName-snapshot-$timestamp"
    }
    Write-Host "Creating snapshot of disk: $DiskName" -ForegroundColor Yellow
    # Get disk information
    Write-Host "Retrieving disk information..." -ForegroundColor Yellow
    $Disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName
    if (-not $Disk) {
        throw "Disk '$DiskName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "Disk Details:" -ForegroundColor Cyan
    Write-Host "Name: $($Disk.Name)"
    Write-Host "Size: $($Disk.DiskSizeGB) GB"
    Write-Host "Location: $($Disk.Location)"
    Write-Host "Disk State: $($Disk.DiskState)"
    # Check if disk is attached
    if ($Disk.ManagedBy) {
        $vmName = ($Disk.ManagedBy -split '/')[-1]
        Write-Host "Attached to VM: $vmName" -ForegroundColor Yellow
    } else {
        Write-Host "Status: Unattached" -ForegroundColor Green
    }
    # Prepare tags
    $defaultTags = @{
        CreatedBy = "Azure-PowerShell-Toolkit"
        CreatedOn = (Get-Date).ToString("yyyy-MM-dd")
        SourceDisk = $DiskName
    }
    if ($RetentionDays) {
        $retentionDate = (Get-Date).AddDays($RetentionDays).ToString("yyyy-MM-dd")
        $defaultTags.RetainUntil = $retentionDate
        $defaultTags.RetentionDays = $RetentionDays.ToString()
    }
    foreach ($tag in $Tags.GetEnumerator()) {
        $defaultTags[$tag.Key] = $tag.Value
    }
    # Confirmation
    if (-not $Force) {
        Write-Host "`nSnapshot Configuration:" -ForegroundColor Cyan
        Write-Host "Snapshot Name: $SnapshotName"
        Write-Host "Source Disk: $DiskName ($($Disk.DiskSizeGB) GB)"
        Write-Host "Location: $($Disk.Location)"
        if ($RetentionDays) {
            Write-Host "Retention: $RetentionDays days"
        }
        $confirmation = Read-Host "`nCreate snapshot? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    # Create snapshot configuration
    Write-Host "`nConfiguring snapshot..." -ForegroundColor Yellow
    $SnapshotConfig = New-AzSnapshotConfig -SourceUri $Disk.Id -Location $Disk.Location -CreateOption Copy -Tag $defaultTags
    # Create the snapshot
    Write-Host "Creating snapshot..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($SnapshotName, "Create disk snapshot")) {
        $Snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig
        Write-Host "`nSnapshot created successfully!" -ForegroundColor Green
        Write-Host "Snapshot Details:" -ForegroundColor Cyan
        Write-Host "Name: $($Snapshot.Name)"
        Write-Host "Size: $($Snapshot.DiskSizeGB) GB"
        Write-Host "Location: $($Snapshot.Location)"
        Write-Host "Creation Time: $($Snapshot.TimeCreated)"
        if ($RetentionDays) {
            $retentionDate = (Get-Date).AddDays($RetentionDays).ToString("yyyy-MM-dd")
            Write-Host "Retention Until: $retentionDate" -ForegroundColor Yellow
        }
        # Show resource ID for automation scenarios
        Write-Host "`nResource Information:" -ForegroundColor Cyan
        Write-Host "Resource ID: $($Snapshot.Id)"
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Verify snapshot integrity if needed"
        Write-Host "2. Set up automated cleanup if retention is configured"
        Write-Host "3. Use snapshot to create new disks or restore as needed"
    
} catch {
    Write-Error "Failed to create snapshot: $_"
    throw
}\n


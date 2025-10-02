#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Creates snapshots of Azure managed disks with validation and tagging

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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
param(
[Parameter(Mandatory = $true)]
)
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
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    if (-not $SnapshotName) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $SnapshotName = "$DiskName-snapshot-$timestamp"
    }
    Write-Host "Creating snapshot of disk: $DiskName" -ForegroundColor Green
    Write-Host "Retrieving disk information..." -ForegroundColor Green
    $Disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName
    if (-not $Disk) {
        throw "Disk '$DiskName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "Disk Details:" -ForegroundColor Green
    Write-Output "Name: $($Disk.Name)"
    Write-Output "Size: $($Disk.DiskSizeGB) GB"
    Write-Output "Location: $($Disk.Location)"
    Write-Output "Disk State: $($Disk.DiskState)"
    if ($Disk.ManagedBy) {
        $VmName = ($Disk.ManagedBy -split '/')[-1]
        Write-Host "Attached to VM: $VmName" -ForegroundColor Green
    } else {
        Write-Host "Status: Unattached" -ForegroundColor Green
    }
    $DefaultTags = @{
        CreatedBy = "Azure-PowerShell-Toolkit"
        CreatedOn = (Get-Date).ToString("yyyy-MM-dd")
        SourceDisk = $DiskName
    }
    if ($RetentionDays) {
        $RetentionDate = (Get-Date).AddDays($RetentionDays).ToString("yyyy-MM-dd")
        $DefaultTags.RetainUntil = $RetentionDate
        $DefaultTags.RetentionDays = $RetentionDays.ToString()
    }
    foreach ($tag in $Tags.GetEnumerator()) {
        $DefaultTags[$tag.Key] = $tag.Value
    }
    if (-not $Force) {
        Write-Host "`nSnapshot Configuration:" -ForegroundColor Green
        Write-Output "Snapshot Name: $SnapshotName"
        Write-Output "Source Disk: $DiskName ($($Disk.DiskSizeGB) GB)"
        Write-Output "Location: $($Disk.Location)"
        if ($RetentionDays) {
            Write-Output "Retention: $RetentionDays days"
        }
        $confirmation = Read-Host "`nCreate snapshot? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "`nConfiguring snapshot..." -ForegroundColor Green
    $SnapshotConfig = New-AzSnapshotConfig -SourceUri $Disk.Id -Location $Disk.Location -CreateOption Copy -Tag $DefaultTags
    Write-Host "Creating snapshot..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($SnapshotName, "Create disk snapshot")) {
        $Snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig
        Write-Host "`nSnapshot created successfully!" -ForegroundColor Green
        Write-Host "Snapshot Details:" -ForegroundColor Green
        Write-Output "Name: $($Snapshot.Name)"
        Write-Output "Size: $($Snapshot.DiskSizeGB) GB"
        Write-Output "Location: $($Snapshot.Location)"
        Write-Output "Creation Time: $($Snapshot.TimeCreated)"
        if ($RetentionDays) {
            $RetentionDate = (Get-Date).AddDays($RetentionDays).ToString("yyyy-MM-dd")
            Write-Host "Retention Until: $RetentionDate" -ForegroundColor Green
        }
        Write-Host "`nResource Information:" -ForegroundColor Green
        Write-Output "Resource ID: $($Snapshot.Id)"
        Write-Host "`nNext Steps:" -ForegroundColor Green
        Write-Output "1. Verify snapshot integrity if needed"
        Write-Output "2. Set up automated cleanup if retention is configured"
        Write-Output "3. Use snapshot to create new disks or restore as needed"

} catch {
    Write-Error "Failed to create snapshot: $_"
    throw`n}

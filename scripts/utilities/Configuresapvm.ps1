#Requires -Version 7.4

<#
.SYNOPSIS
    Configure SAP VM

.DESCRIPTION
    Azure automation script for SAP VM configuration with disk setup

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [String]$DBDataLUNS = "0,1,2",
    [String]$DBLogLUNS = "3",
    [String]$DBDataDrive = "S:",
    [String]$DBLogDrive = "L:",
    [String]$DBDataName = "dbdata",
    [String]$DBLogName = "dblog"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Verbose "[$Timestamp] $Message"
}

try {
    Write-Log "Starting SAP VM configuration"

    # Parse LUN numbers
    $DataLUNs = $DBDataLUNS -split ',' | ForEach-Object { [int]$_.Trim() }
    $LogLUNs = $DBLogLUNS -split ',' | ForEach-Object { [int]$_.Trim() }

    Write-Log "Data LUNs: $($DataLUNs -join ', ')"
    Write-Log "Log LUNs: $($LogLUNs -join ', ')"

    # Get disks by LUN
    $DataDisks = @()
    $LogDisks = @()

    foreach ($lun in $DataLUNs) {
        $disk = Get-Disk | Where-Object { $_.Location -match "LUN $lun" }
        if ($disk) {
            $DataDisks += $disk
            Write-Log "Found data disk at LUN $lun"
        }
    }

    foreach ($lun in $LogLUNs) {
        $disk = Get-Disk | Where-Object { $_.Location -match "LUN $lun" }
        if ($disk) {
            $LogDisks += $disk
            Write-Log "Found log disk at LUN $lun"
        }
    }

    # Initialize disks if needed
    foreach ($disk in $DataDisks) {
        if ($disk.PartitionStyle -eq 'RAW') {
            Write-Log "Initializing data disk $($disk.Number)"
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT -ErrorAction SilentlyContinue
        }
    }

    foreach ($disk in $LogDisks) {
        if ($disk.PartitionStyle -eq 'RAW') {
            Write-Log "Initializing log disk $($disk.Number)"
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT -ErrorAction SilentlyContinue
        }
    }

    # Create storage pools if multiple disks
    if ($DataDisks.Count -gt 1) {
        Write-Log "Creating storage pool for data disks"

        $PhysicalDisks = $DataDisks | ForEach-Object { Get-PhysicalDisk -UniqueId $_.UniqueId }

        New-StoragePool -FriendlyName $DBDataName `
                       -StorageSubSystemFriendlyName "Windows Storage*" `
                       -PhysicalDisks $PhysicalDisks

        New-VirtualDisk -StoragePoolFriendlyName $DBDataName `
                       -FriendlyName "${DBDataName}_VDisk" `
                       -ResiliencySettingName Simple `
                       -UseMaximumSize

        Get-VirtualDisk -FriendlyName "${DBDataName}_VDisk" |
            Get-Disk |
            Initialize-Disk -PartitionStyle GPT -PassThru |
            New-Partition -DriveLetter $DBDataDrive.TrimEnd(':') -UseMaximumSize |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel $DBDataName -Confirm:$false
    }
    elseif ($DataDisks.Count -eq 1) {
        Write-Log "Creating simple volume for data disk"

        $DataDisks[0] |
            New-Partition -DriveLetter $DBDataDrive.TrimEnd(':') -UseMaximumSize |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel $DBDataName -Confirm:$false
    }

    if ($LogDisks.Count -gt 0) {
        if ($LogDisks.Count -gt 1) {
            Write-Log "Creating storage pool for log disks"

            $PhysicalDisks = $LogDisks | ForEach-Object { Get-PhysicalDisk -UniqueId $_.UniqueId }

            New-StoragePool -FriendlyName $DBLogName `
                           -StorageSubSystemFriendlyName "Windows Storage*" `
                           -PhysicalDisks $PhysicalDisks

            New-VirtualDisk -StoragePoolFriendlyName $DBLogName `
                           -FriendlyName "${DBLogName}_VDisk" `
                           -ResiliencySettingName Simple `
                           -UseMaximumSize

            Get-VirtualDisk -FriendlyName "${DBLogName}_VDisk" |
                Get-Disk |
                Initialize-Disk -PartitionStyle GPT -PassThru |
                New-Partition -DriveLetter $DBLogDrive.TrimEnd(':') -UseMaximumSize |
                Format-Volume -FileSystem NTFS -NewFileSystemLabel $DBLogName -Confirm:$false
        }
        else {
            Write-Log "Creating simple volume for log disk"

            $LogDisks[0] |
                New-Partition -DriveLetter $DBLogDrive.TrimEnd(':') -UseMaximumSize |
                Format-Volume -FileSystem NTFS -NewFileSystemLabel $DBLogName -Confirm:$false
        }
    }

    Write-Log "SAP VM configuration completed successfully"
}
catch {
    Write-Error "Failed to configure SAP VM: $($_.Exception.Message)"
    throw
}
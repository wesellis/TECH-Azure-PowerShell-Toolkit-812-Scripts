#Requires -Version 7.4
#Requires -Modules Storage

<#
.SYNOPSIS
    Configures disk storage pools and partitions for Azure VMs

.DESCRIPTION
    This script configures disk storage by creating storage pools from multiple LUNs,
    or configuring individual disks with custom partitions, drive letters, and mount points.
    It supports both pooled storage configurations and single disk configurations.

.PARAMETER Luns
    Comma-separated list of LUN numbers to configure. Use '#' to separate different configurations.

.PARAMETER Names
    Names for the storage pools or disk labels. Use '#' to separate different configurations.

.PARAMETER Paths
    Drive letters or mount paths for the volumes. Use '#' to separate configurations and ',' for multiple partitions.

.PARAMETER Sizes
    Percentage of disk space for each partition. Use '#' to separate configurations and ',' for multiple partitions.

.EXAMPLE
    .\Diskconfig.ps1 -Luns "0,1,2" -Names "DataPool" -Paths "S:" -Sizes "100"
    Creates a storage pool from LUNs 0,1,2 with a single volume on drive S: using all available space

.EXAMPLE
    .\Diskconfig.ps1 -Luns "3" -Names "LogDisk" -Paths "L:,C:\Logs" -Sizes "50,50"
    Configures LUN 3 as a single disk with two partitions: 50% on L: drive and 50% mounted to C:\Logs

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    2.0

.NOTES
    Requires appropriate permissions and Storage module
    Updated for better error handling and modern PowerShell practices
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Luns = "0,1,2",

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Names = "DataPool",

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Paths = "S:",

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Sizes = "100"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp : $Message"
    Write-Output $logMessage

    $logPath = "C:\sapcd"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }

    $logMessage | Out-File -Append -FilePath "$logPath\log.txt"
}

try {
    Write-Log "Starting disk configuration process"

    $SEP_CONFIGS = "#"
    $SEP_DISKS = ","
    $SEP_PARTS = ","

    $LunsSplit = @($Luns -split $SEP_CONFIGS)
    $NamesSplit = @($Names -split $SEP_CONFIGS)
    $PathsSplit = @($Paths -split $SEP_CONFIGS)
    $SizesSplit = @($Sizes -split $SEP_CONFIGS)

    for ($index = 0; $index -lt $LunsSplit.Count; $index++) {
        $LunParts = @($LunsSplit[$index] -split $SEP_DISKS)
        $poolname = $NamesSplit[$index].Trim()
        $PathsPartSplit = $PathsSplit[$index] -split $SEP_PARTS
        $SizesPartSplit = $SizesSplit[$index] -split $SEP_PARTS

        if ($LunParts.Count -gt 1) {
            # Multiple LUNs - create storage pool
            Write-Log "Processing storage pool configuration with multiple LUNs: $($LunParts -join ',')"

            $subsystem = Get-StorageSubSystem
            $pool = Get-StoragePool -FriendlyName $poolname -ErrorAction SilentlyContinue

            if (-not $pool) {
                Write-Log "Creating storage pool: $poolname"
                $disks = Get-CimInstance Win32_DiskDrive -ErrorAction Stop |
                    Where-Object { $_.InterfaceType -eq "SCSI" -and $_.SCSILogicalUnit -in $LunParts } |
                    ForEach-Object { Get-PhysicalDisk | Where-Object DeviceId -eq $_.Index }

                if ($disks.Count -eq 0) {
                    throw "No physical disks found for LUNs: $($LunParts -join ',')"
                }

                $pool = New-StoragePool -FriendlyName $poolname -StorageSubSystemUniqueId $subsystem.UniqueId -PhysicalDisks $disks -ResiliencySettingNameDefault Simple -ProvisioningTypeDefault Fixed
            }

            $diskname = $poolname
            $disk = Get-VirtualDisk -FriendlyName $diskname -ErrorAction SilentlyContinue

            if (-not $disk) {
                Write-Log "Creating virtual disk: $diskname"
                $disk = New-VirtualDisk -StoragePoolUniqueId $pool.UniqueId -FriendlyName $diskname -UseMaximumSize
            }

            Initialize-Disk -PartitionStyle GPT -UniqueId $disk.UniqueId -ErrorAction SilentlyContinue

            for ($PartIndex = 0; $PartIndex -lt $PathsPartSplit.Count; $PartIndex++) {
                $name = "$poolname-$PartIndex"
                $path = $PathsPartSplit[$PartIndex].Trim()
                $size = $SizesPartSplit[$PartIndex].Trim()
                $args = @{}

                if ($path.Length -eq 2 -and $path.EndsWith(":")) {
                    $args["DriveLetter"] = $path[0]
                }

                if ($size -eq "100") {
                    $args["UseMaximumSize"] = $true
                }
                else {
                    $physicalDisk = $disk | Get-Disk
                    $UnallocatedSize = $physicalDisk.Size - ($physicalDisk | Get-Partition | Measure-Object -Property Size -Sum).Sum
                    [UInt64]$SizeToUse = ($UnallocatedSize / 100) * ([int]$size)
                    $args["Size"] = $SizeToUse
                }

                $volume = $disk | Get-Disk | Get-Partition | Get-Volume | Where-Object FileSystemLabel -eq $name
                if (-not $volume) {
                    Write-Log "Creating partition: $name"
                    $partition = New-Partition -DiskId $disk.UniqueId @args
                    $partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $name -Confirm:$false
                }

                if ($path.Length -ne 2 -or -not $path.EndsWith(":")) {
                    $partition = $disk | Get-Disk | Get-Partition | Get-Volume | Where-Object FileSystemLabel -eq $name | Get-Partition
                    $physicalDisk = $disk | Get-Disk
                    $DiskMounted = $false

                    foreach ($AccessPath in $partition.AccessPaths) {
                        $DiskMounted = (Join-Path $AccessPath '') -eq (Join-Path $path '')
                        if ($DiskMounted) {
                            break
                        }
                    }

                    if (-not $DiskMounted) {
                        if (-not (Test-Path $path)) {
                            New-Item -ItemType Directory -Path $path -Force | Out-Null
                        }
                        Add-PartitionAccessPath -PartitionNumber $partition.PartitionNumber -DiskNumber $physicalDisk.Number -AccessPath $path
                    }
                }
            }
        }
        elseif ($LunParts.Count -eq 1) {
            # Single LUN - configure individual disk
            $lun = $LunParts[0].Trim()
            Write-Log "Processing single disk configuration for LUN: $lun"

            $disk = Get-CimInstance Win32_DiskDrive -ErrorAction Stop |
                Where-Object { $_.InterfaceType -eq "SCSI" -and $_.SCSILogicalUnit -eq $lun } |
                ForEach-Object { Get-Disk -Number $_.Index } |
                Select-Object -First 1

            if (-not $disk) {
                throw "No disk found for LUN: $lun"
            }

            Initialize-Disk -PartitionStyle GPT -UniqueId $disk.UniqueId -ErrorAction SilentlyContinue

            for ($PartIndex = 0; $PartIndex -lt $PathsPartSplit.Count; $PartIndex++) {
                $name = "$poolname-$PartIndex"
                $path = $PathsPartSplit[$PartIndex].Trim()
                $size = $SizesPartSplit[$PartIndex].Trim()
                $args = @{}

                if ($path.Length -eq 2 -and $path.EndsWith(":")) {
                    $args["DriveLetter"] = $path[0]
                }

                if ($size -eq "100") {
                    $args["UseMaximumSize"] = $true
                }
                else {
                    $UnallocatedSize = $disk.Size - $disk.AllocatedSize
                    [UInt64]$SizeToUse = ($UnallocatedSize / 100) * ([int]$size)
                    $args["Size"] = $SizeToUse
                }

                $volume = $disk | Get-Partition | Get-Volume | Where-Object FileSystemLabel -eq $name
                if (-not $volume) {
                    Write-Log "Creating partition: $name on disk $($disk.Number)"
                    $partition = New-Partition -DiskId $disk.UniqueId @args
                    $partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $name -Confirm:$false
                }

                if ($path.Length -ne 2 -or -not $path.EndsWith(":")) {
                    $partition = $disk | Get-Partition | Get-Volume | Where-Object FileSystemLabel -eq $name | Get-Partition
                    $DiskMounted = $false

                    foreach ($AccessPath in $partition.AccessPaths) {
                        $DiskMounted = (Join-Path $AccessPath '') -eq (Join-Path $path '')
                        if ($DiskMounted) {
                            break
                        }
                    }

                    if (-not $DiskMounted) {
                        if (-not (Test-Path $path)) {
                            New-Item -ItemType Directory -Path $path -Force | Out-Null
                        }
                        Add-PartitionAccessPath -PartitionNumber $partition.PartitionNumber -DiskNumber $disk.Number -AccessPath $path
                    }
                }
            }
        }
    }

    Write-Log "Disk configuration completed successfully"
}
catch {
    $errorMessage = "Script execution failed: $($_.Exception.Message)"
    Write-Log $errorMessage
    Write-Error $errorMessage
    throw
}

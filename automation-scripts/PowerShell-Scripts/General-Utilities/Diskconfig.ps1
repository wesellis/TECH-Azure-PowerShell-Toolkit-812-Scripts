<#
.SYNOPSIS
    We Enhanced Diskconfig

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [String] $luns = "0,1,2" ,	
    [String] $names = "3" ,
    [string] $paths = "S:" ,
    [string] $sizes = "L:"
)
; 
$WEErrorActionPreference = " Stop";
function WE-Log
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [string] $message
    )
    $message = (Get-Date).ToString() + " : " + $message;
    Write-Host $message;
    if (-not (Test-Path (" c:" + [char]92 + " sapcd")))
    {
        $nul = mkdir (" c:" + [char]92 + " sapcd");
    }
    $message | Out-File -Append -FilePath (" c:" + [char]92 + " sapcd" + [char]92 + " log.txt");
}

$WESEP_CONFIGS = " #"
$WESEP_DISKS = " ,"
$WESEP_PARTS = " ,"

$lunsSplit  = @($luns  -split $WESEP_CONFIGS)
$namesSplit = @($names -split $WESEP_CONFIGS)
$pathsSplit = @($paths -split $WESEP_CONFIGS); 
$sizesSplit = @($sizes -split $WESEP_CONFIGS)


for ($index = 0; $index -lt $lunsSplit.Count; $index++)
{
    $lunParts = @($lunsSplit[$index]  -split $WESEP_DISKS)
    $poolname = $namesSplit[$index]

    $pathsPartSplit = $pathsSplit[$index] -split $WESEP_PARTS
    $sizesPartSplit = $sizesSplit[$index] -split $WESEP_PARTS
    #todo parts must be same size

    if ($lunParts.Count -gt 1)
    {
       ;  $count = 0;
        
        $subsystem = Get-StorageSubSystem;
        $pool = Get-StoragePool -FriendlyName $poolname -ErrorAction SilentlyContinue
        if (-not ($pool))
        {
            Log " Creating Pool";
            $disks = Get-CimInstance Win32_DiskDrive | where InterfaceType -eq SCSI | where SCSILogicalUnit -In $lunParts | % { Get-PhysicalDisk | where DeviceId -eq $_.Index }
           ;  $pool = New-StoragePool -FriendlyName $poolname -StorageSubSystemUniqueId $subsystem.UniqueId -PhysicalDisks $disks -ResiliencySettingNameDefault Simple -ProvisioningTypeDefault Fixed;
        }
        
        $diskname = " $($poolname)"
       ;  $disk = Get-VirtualDisk -FriendlyName $diskname -ErrorAction SilentlyContinue
        if (-not $disk)
        {
            Log " Creating disk";                
            $disk = New-VirtualDisk -StoragePoolUniqueId $pool.UniqueId -FriendlyName $diskname -UseMaximumSize
        }
        Initialize-Disk -PartitionStyle GPT -UniqueId $disk.UniqueId -ErrorAction SilentlyContinue
        
        for ($partIndex = 0; $partIndex -lt $pathsPartSplit.Count; $partIndex++)
        {            
            $name = " $($poolname)-$($partIndex)"
            $path = $pathsPartSplit[$partIndex]
            $size = $sizesPartSplit[$partIndex]
            $args = @{}

            if ($path.Length -eq 1)
            {
                $args = $args + @{" DriveLetter"=$path}
            }
            if ($size -eq " 100")
            {
                $args = $args + @{" UseMaximumSize"=$true}
            }
            else
            {
                $unallocatedSize = $disk.Size - ($disk | Get-Disk | Get-Partition | Measure-Object -Property Size -Sum).Sum
                [UInt64] $sizeToUse = ($unallocatedSize / 100) * ([int]$size)
                $args = $args + @{" Size"=$sizeToUse}
            }

            $volume = $disk | Get-Disk | Get-Partition | Get-Volume | where FileSystemLabel -eq $name
            if (-not $volume)
            {
               ;  $partition = New-Partition -DiskId $disk.UniqueId @args
                $partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $name -Confirm:$false;
            }

            if ($path.Length -ne 1)
            {
                $partition = $disk | Get-Disk | Get-Partition | Get-Volume | where FileSystemLabel -eq $name | Get-Partition
                $ddisk = $disk | Get-Disk

                $diskMounted = $false
                foreach ($accessPath in $partition.AccessPaths)
                {
                    $diskMounted = (Join-Path $accessPath '') -eq (Join-Path $path '')
                    if ($diskMounted)
                    {
                        break
                    }
                }

                if (-not $diskMounted)
                {
                    if (-not (Test-Path $path))
                    {
                        $nul = mkdir $path
                    }
                    Add-PartitionAccessPath -PartitionNumber $partition.PartitionNumber -DiskNumber $ddisk.Number -AccessPath $path
                }
            }
        }
    }
    elseif ($lunParts.Length -eq 1)
    {		
       ;  $lun = $lunParts[0];
        Log (" Creating volume for disk " + $lun);
        $disk = Get-CimInstance Win32_DiskDrive | where InterfaceType -eq SCSI | where SCSILogicalUnit -eq $lun | % { Get-Disk -Number $_.Index } | select -First 1;
        Initialize-Disk -PartitionStyle GPT -UniqueId $disk.UniqueId -ErrorAction SilentlyContinue

        for ($partIndex = 0; $partIndex -lt $pathsPartSplit.Count; $partIndex++)
        {
            $name = " $($poolname)-$($partIndex)"
            $path = $pathsPartSplit[$partIndex]
            $size = $sizesPartSplit[$partIndex]

            $args = @{}

            if ($path.Length -eq 1)
            {
                $args = $args + @{" DriveLetter"=$path}
            }
            if ($size -eq " 100")
            {
                $args = $args + @{" UseMaximumSize"=$true}
            }
            else
            {
                $unallocatedSize = $disk.Size - $disk.AllocatedSize
                [UInt64] $sizeToUse = ($unallocatedSize / 100) * ([int]$size)
                $args = $args + @{" Size"=$sizeToUse}
            }

            $volume = $disk | Get-Disk | Get-Partition | Get-Volume | where FileSystemLabel -eq $name
            if (-not $volume)
            {
               ;  $partition = New-Partition -DiskId $disk.UniqueId @args
                $partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $name -Confirm:$false;
            }

            if ($path.Length -ne 1)
            {
                $partition = $disk | Get-Disk | Get-Partition | Get-Volume | where FileSystemLabel -eq $name | Get-Partition
                $ddisk = $disk | Get-Disk

                $diskMounted = $false
                foreach ($accessPath in $partition.AccessPaths)
                {
                    $diskMounted = (Join-Path $accessPath '') -eq (Join-Path $path '')
                    if ($diskMounted)
                    {
                        break
                    }
                }

                if (-not $diskMounted)
                {
                    if (-not (Test-Path $path))
                    {
                       ;  $nul = mkdir $path
                    }
                    Add-PartitionAccessPath -PartitionNumber $partition.PartitionNumber -DiskNumber $ddisk.Number -AccessPath $path
                }
            }
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

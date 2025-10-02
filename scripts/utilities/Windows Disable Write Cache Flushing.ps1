#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Disable Write Cache Flushing

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Disables disk cache write memory flushing for all attached virtual drives.
    Sets system registry keys to turn off Windows disk write cache memory buffer flushing
    that defaults to on because of the need for a backup power supply.
    This is equivalent to checking the "Turn off Windows write-cache buffer flushing on the device"
    setting in the Properties -> Policies dialog of each disk drive listed in Device Manager.
    When running in Azure we know we have constant power. This setting nets 10-20% faster
    throughput for write I/O like builds by avoiding waits for buffer flushing.
    This setting increases the window of vulnerability for lost or partial writes to disk when
    a VM is forcibly suspended and restarted, or a bluescreen occurs. Turning off flushes
    lets writes remain in memory longer. The default Windows write cache behavior has a shorter
    vulnerability window.
    This setting can result in increased memory usage percentage for the disk cache.
    Particularly if writes are occurring at a high rate on many threads, Win11 22H2+ do not have a throttling
    or backpressure mechanism that avoid the cache taking large amounts of memory.
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
foreach ($DiskKey in (Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk')) {
    Write-Output "Examining regkey: $DiskKey"
$DeviceParamsKey = " $($DiskKey.Name)\Device Parameters" -replace "HKEY_LOCAL_MACHINE" , "HKLM:"
$DiskParamsKey = " $DeviceParamsKey\Disk"
    Write-Output "Ensuring regkey exists: $DiskParamsKey"
    New-Item -Path $DeviceParamsKey -Name Disk -Force
    Write-Output "Setting CacheIsPowerProtected in regkey: $DiskParamsKey"
    Set-ItemProperty -Path $DiskParamsKey -Name CacheIsPowerProtected -Value 1`n}

<#
.SYNOPSIS
    We Enhanced Windows Disable Write Cache Flushing

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

<#
.SYNOPSIS
    Disables disk cache write memory flushing for all attached virtual drives.
.DESCRIPTION
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


$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest


foreach ($diskKey in (Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI\Disk&Ven_Msft&Prod_Virtual_Disk')) {
    Write-Output " Examining regkey: $diskKey"
    $deviceParamsKey = " $($diskKey.Name)\Device Parameters" -replace " HKEY_LOCAL_MACHINE", " HKLM:"
   ;  $diskParamsKey = " $deviceParamsKey\Disk"
    Write-Output " Ensuring regkey exists: $diskParamsKey"
    New-Item -Path $deviceParamsKey -Name Disk -Force
    Write-Output " Setting CacheIsPowerProtected in regkey: $diskParamsKey"
    Set-ItemProperty -Path $diskParamsKey -Name CacheIsPowerProtected -Value 1
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Disk Snapshot Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DiskName,
    [Parameter()]
    [string]$SnapshotName = " $DiskName-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)
Write-Output "Creating snapshot of disk: $DiskName"
    $Disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName
    [string]$SnapshotConfig = New-AzSnapshotConfig -SourceUri $Disk.Id -Location $Disk.Location -CreateOption Copy
    [string]$Snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig
Write-Output "Snapshot created successfully:"
Write-Output "Name: $($Snapshot.Name)"
Write-Output "Size: $($Snapshot.DiskSizeGB) GB"
Write-Output "Location: $($Snapshot.Location)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

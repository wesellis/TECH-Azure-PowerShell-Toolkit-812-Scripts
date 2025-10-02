#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Disk List

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
;
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Output "Retrieving disk information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Output " `nOS Disk:"
Write-Output "Name: $($VM.StorageProfile.OsDisk.Name)"
Write-Output "Size: $($VM.StorageProfile.OsDisk.DiskSizeGB) GB"
Write-Output "Type: $($VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)"
if ($VM.StorageProfile.DataDisks.Count -gt 0) {
    Write-Output " `nData Disks:"
    foreach ($Disk in $VM.StorageProfile.DataDisks) {
        Write-Output "Name: $($Disk.Name) | Size: $($Disk.DiskSizeGB) GB | LUN: $($Disk.Lun)"
    }
} else {
    Write-Output " `nNo data disks attached."
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

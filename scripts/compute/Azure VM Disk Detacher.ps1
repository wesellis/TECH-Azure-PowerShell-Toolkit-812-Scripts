#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Disk Detacher

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
function Write-Log {
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
    [string]$VmName,
    [Parameter(Mandatory)]
    [string]$DiskName
)
Write-Output "Detaching disk from VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
    [string]$DiskToDetach = $VM.StorageProfile.DataDisks | Where-Object { $_.Name -eq $DiskName }
if (-not $DiskToDetach) {
    Write-Error "Disk '$DiskName' not found on VM '$VmName'"
    return
}
Write-Output "Found disk: $DiskName (LUN: $($DiskToDetach.Lun))"
Remove-AzVMDataDisk -VM $VM -Name $DiskName
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Output "Disk detached successfully:"
Write-Output "Disk: $DiskName"
Write-Output "VM: $VmName"
Write-Output "LUN: $($DiskToDetach.Lun)"
Write-Output "Note: Disk is now available for attachment to other VMs"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

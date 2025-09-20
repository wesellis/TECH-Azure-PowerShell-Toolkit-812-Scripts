#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Azure Vm Disk Detacher

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([PSObject])]
 {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Detaching disk from VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
$DiskToDetach = $VM.StorageProfile.DataDisks | Where-Object { $_.Name -eq $DiskName }
if (-not $DiskToDetach) {
    Write-Error "Disk '$DiskName' not found on VM '$VmName'"
    return
}
Write-Host "Found disk: $DiskName (LUN: $($DiskToDetach.Lun))"
Remove-AzVMDataDisk -VM $VM -Name $DiskName
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Host "Disk detached successfully:"
Write-Host "Disk: $DiskName"
Write-Host "VM: $VmName"
Write-Host "LUN: $($DiskToDetach.Lun)"
Write-Host "Note: Disk is now available for attachment to other VMs"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n


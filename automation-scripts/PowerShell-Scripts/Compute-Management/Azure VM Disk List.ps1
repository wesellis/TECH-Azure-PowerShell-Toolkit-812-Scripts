<#
.SYNOPSIS
    Azure Vm Disk List

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
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
[CmdletBinding()];
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Host "Retrieving disk information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Host " `nOS Disk:"
Write-Host "Name: $($VM.StorageProfile.OsDisk.Name)"
Write-Host "Size: $($VM.StorageProfile.OsDisk.DiskSizeGB) GB"
Write-Host "Type: $($VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)"
if ($VM.StorageProfile.DataDisks.Count -gt 0) {
    Write-Host " `nData Disks:"
    foreach ($Disk in $VM.StorageProfile.DataDisks) {
        Write-Host "Name: $($Disk.Name) | Size: $($Disk.DiskSizeGB) GB | LUN: $($Disk.Lun)"
    }
} else {
    Write-Host " `nNo data disks attached."
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


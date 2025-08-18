<#
.SYNOPSIS
    Azure Vm Disk List

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
    We Enhanced Azure Vm Disk List

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WEVmName
)

Write-WELog " Retrieving disk information for VM: $WEVmName" " INFO"
; 
$WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVmName

Write-WELog " `nOS Disk:" " INFO"
Write-WELog "  Name: $($WEVM.StorageProfile.OsDisk.Name)" " INFO"
Write-WELog "  Size: $($WEVM.StorageProfile.OsDisk.DiskSizeGB) GB" " INFO"
Write-WELog "  Type: $($WEVM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType)" " INFO"

if ($WEVM.StorageProfile.DataDisks.Count -gt 0) {
    Write-WELog " `nData Disks:" " INFO"
    foreach ($WEDisk in $WEVM.StorageProfile.DataDisks) {
        Write-WELog "  Name: $($WEDisk.Name) | Size: $($WEDisk.DiskSizeGB) GB | LUN: $($WEDisk.Lun)" " INFO"
    }
} else {
    Write-WELog " `nNo data disks attached." " INFO"
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

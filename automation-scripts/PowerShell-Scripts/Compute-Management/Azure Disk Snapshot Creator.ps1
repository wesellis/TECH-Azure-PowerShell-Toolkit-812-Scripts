<#
.SYNOPSIS
    Azure Disk Snapshot Creator

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
    We Enhanced Azure Disk Snapshot Creator

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



[CmdletBinding()]
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDiskName,
    
    [Parameter(Mandatory=$false)]
    [string]$WESnapshotName = " $WEDiskName-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

Write-WELog " Creating snapshot of disk: $WEDiskName" " INFO"

$WEDisk = Get-AzDisk -ResourceGroupName $WEResourceGroupName -DiskName $WEDiskName
; 
$WESnapshotConfig = New-AzSnapshotConfig -SourceUri $WEDisk.Id -Location $WEDisk.Location -CreateOption Copy
; 
$WESnapshot = New-AzSnapshot -ResourceGroupName $WEResourceGroupName -SnapshotName $WESnapshotName -Snapshot $WESnapshotConfig

Write-WELog " Snapshot created successfully:" " INFO"
Write-WELog "  Name: $($WESnapshot.Name)" " INFO"
Write-WELog "  Size: $($WESnapshot.DiskSizeGB) GB" " INFO"
Write-WELog "  Location: $($WESnapshot.Location)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

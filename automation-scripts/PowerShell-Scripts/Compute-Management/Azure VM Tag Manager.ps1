<#
.SYNOPSIS
    We Enhanced Azure Vm Tag Manager

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVmName,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$WETags
)

Write-WELog " Updating tags for VM: $WEVmName" " INFO"

$WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVmName


$WEExistingTags = $WEVM.Tags
if (-not $WEExistingTags) {;  $WEExistingTags = @{} }

foreach ($WETag in $WETags.GetEnumerator()) {
    $WEExistingTags[$WETag.Key] = $WETag.Value
    Write-WELog " Added/Updated tag: $($WETag.Key) = $($WETag.Value)" " INFO"
}

Update-AzVM -ResourceGroupName $WEResourceGroupName -VM $WEVM -Tag $WEExistingTags
Write-WELog " Tags updated successfully for VM: $WEVmName" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

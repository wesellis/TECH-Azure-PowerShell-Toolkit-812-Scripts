<#
.SYNOPSIS
    Azure Vm Bootdiagnostics Enabler

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
    We Enhanced Azure Vm Bootdiagnostics Enabler

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVmName,
    
    [Parameter(Mandatory=$false)]
    [string]$WEStorageAccountName
)

Write-WELog " Enabling boot diagnostics for VM: $WEVmName" " INFO"
; 
$WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVmName

if ($WEStorageAccountName) {
    Set-AzVMBootDiagnostic -VM $WEVM -Enable -ResourceGroupName $WEResourceGroupName -StorageAccountName $WEStorageAccountName
    Write-WELog " Using storage account: $WEStorageAccountName" " INFO"
} else {
    Set-AzVMBootDiagnostic -VM $WEVM -Enable
    Write-WELog " Using managed storage" " INFO"
}

Update-AzVM -ResourceGroupName $WEResourceGroupName -VM $WEVM

Write-WELog " ✅ Boot diagnostics enabled successfully:" " INFO"
Write-WELog "  VM: $WEVmName" " INFO"
Write-WELog "  Resource Group: $WEResourceGroupName" " INFO"
if ($WEStorageAccountName) {
    Write-WELog "  Storage Account: $WEStorageAccountName" " INFO"
}
Write-WELog "  Status: Enabled" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

<#
.SYNOPSIS
    Azure Vm Extension Manager

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
    We Enhanced Azure Vm Extension Manager

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
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEExtensionName,
    
    [Parameter(Mandatory=$false)]
    [string]$WEExtensionType = " CustomScriptExtension" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEPublisher = " Microsoft.Compute"
)

Write-WELog " Managing VM extension: $WEExtensionName" " INFO"
; 
$WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVmName


Set-AzVMExtension `
    -ResourceGroupName $WEResourceGroupName `
    -VMName $WEVmName `
    -Name $WEExtensionName `
    -Publisher $WEPublisher `
    -ExtensionType $WEExtensionType `
    -TypeHandlerVersion " 1.10" `
    -Location $WEVM.Location

Write-WELog " ✅ Extension '$WEExtensionName' installed successfully" " INFO"
Write-WELog " VM: $WEVmName" " INFO"
Write-WELog " Publisher: $WEPublisher" " INFO"
Write-WELog " Type: $WEExtensionType" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

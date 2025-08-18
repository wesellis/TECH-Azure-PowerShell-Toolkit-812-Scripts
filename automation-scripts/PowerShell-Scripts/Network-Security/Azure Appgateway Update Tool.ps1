<#
.SYNOPSIS
    We Enhanced Azure Appgateway Update Tool

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGatewayName,
    [hashtable]$WESettings
)

; 
$WEGateway = Get-AzApplicationGateway -ResourceGroupName $WEResourceGroupName -Name $WEGatewayName

Write-WELog " Updating Application Gateway: $WEGatewayName" " INFO"
Write-WELog " Current SKU: $($WEGateway.Sku.Name)" " INFO"
Write-WELog " Current Tier: $($WEGateway.Sku.Tier)" " INFO"
Write-WELog " Current Capacity: $($WEGateway.Sku.Capacity)" " INFO"


if ($WESettings) {
    foreach ($WESetting in $WESettings.GetEnumerator()) {
        Write-WELog " Applying setting: $($WESetting.Key) = $($WESetting.Value)" " INFO"
    }
}


Set-AzApplicationGateway -ApplicationGateway $WEGateway

Write-WELog " Application Gateway $WEGatewayName updated successfully" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

<#
.SYNOPSIS
    We Enhanced Azure Cdn Profile Creator

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
    [string]$WEProfileName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEndpointName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOriginHostName,
    
    [Parameter(Mandatory=$false)]
    [string]$WESku = " Standard_Microsoft"
)

Write-WELog " Creating CDN Profile: $WEProfileName" " INFO"


$WECdnProfile = New-AzCdnProfile `
    -ResourceGroupName $WEResourceGroupName `
    -ProfileName $WEProfileName `
    -Location $WELocation `
    -Sku $WESku

Write-WELog " CDN Profile created: $($WECdnProfile.Name)" " INFO"


Write-WELog " Creating CDN Endpoint: $WEEndpointName" " INFO"
; 
$WECdnEndpoint = New-AzCdnEndpoint `
    -ResourceGroupName $WEResourceGroupName `
    -ProfileName $WEProfileName `
    -EndpointName $WEEndpointName `
    -Location $WELocation `
    -OriginHostName $WEOriginHostName `
    -OriginName " origin1"

Write-WELog " ✅ CDN Profile and Endpoint created successfully:" " INFO"
Write-WELog "  Profile Name: $($WECdnProfile.Name)" " INFO"
Write-WELog "  SKU: $($WECdnProfile.Sku.Name)" " INFO"
Write-WELog "  Endpoint Name: $($WECdnEndpoint.Name)" " INFO"
Write-WELog "  Endpoint URL: https://$($WECdnEndpoint.HostName)" " INFO"
Write-WELog "  Origin: $WEOriginHostName" " INFO"

Write-WELog " `nCDN Benefits:" " INFO"
Write-WELog " • Global content delivery" " INFO"
Write-WELog " • Reduced latency" " INFO"
Write-WELog " • Improved performance" " INFO"
Write-WELog " • Bandwidth cost optimization" " INFO"
Write-WELog " • Origin server protection" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Configure caching rules" " INFO"
Write-WELog " 2. Set up custom domains" " INFO"
Write-WELog " 3. Enable HTTPS" " INFO"
Write-WELog " 4. Configure compression" " INFO"
Write-WELog " 5. Test global distribution" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

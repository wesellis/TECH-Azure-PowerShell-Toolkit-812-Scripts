<#
.SYNOPSIS
    Azure Api Management Creator

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
    We Enhanced Azure Api Management Creator

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
    [string]$WEServiceName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOrganization,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAdminEmail,
    
    [Parameter(Mandatory=$false)]
    [string]$WESku = " Developer"
)

Write-WELog " Creating API Management service: $WEServiceName" " INFO"
Write-WELog " This process may take 30-45 minutes..." " INFO"
; 
$WEApiManagement = New-AzApiManagement `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEServiceName `
    -Location $WELocation `
    -Organization $WEOrganization `
    -AdminEmail $WEAdminEmail `
    -Sku $WESku

Write-WELog " ✅ API Management service created successfully:" " INFO"
Write-WELog "  Name: $($WEApiManagement.Name)" " INFO"
Write-WELog "  Location: $($WEApiManagement.Location)" " INFO"
Write-WELog "  SKU: $($WEApiManagement.Sku)" " INFO"
Write-WELog "  Gateway URL: $($WEApiManagement.GatewayUrl)" " INFO"
Write-WELog "  Portal URL: $($WEApiManagement.PortalUrl)" " INFO"
Write-WELog "  Management URL: $($WEApiManagement.ManagementApiUrl)" " INFO"

Write-WELog " `nAPI Management Features:" " INFO"
Write-WELog " • API Gateway functionality" " INFO"
Write-WELog " • Developer portal" " INFO"
Write-WELog " • API versioning and documentation" " INFO"
Write-WELog " • Rate limiting and quotas" " INFO"
Write-WELog " • Authentication and authorization" " INFO"
Write-WELog " • Analytics and monitoring" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Configure APIs and operations" " INFO"
Write-WELog " 2. Set up authentication policies" " INFO"
Write-WELog " 3. Configure rate limiting" " INFO"
Write-WELog " 4. Customize developer portal" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

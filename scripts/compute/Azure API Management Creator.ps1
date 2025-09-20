#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Api Management Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Organization,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminEmail,
    [Parameter()]
    [string]$Sku = "Developer"
)
Write-Host "Creating API Management service: $ServiceName"
Write-Host "This process may take 30-45 minutes..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Organization = $Organization
    Location = $Location
    AdminEmail = $AdminEmail
    ErrorAction = "Stop"
    Name = $ServiceName
}
$ApiManagement @params
Write-Host "API Management service created successfully:"
Write-Host "Name: $($ApiManagement.Name)"
Write-Host "Location: $($ApiManagement.Location)"
Write-Host "SKU: $($ApiManagement.Sku)"
Write-Host "Gateway URL: $($ApiManagement.GatewayUrl)"
Write-Host "Portal URL: $($ApiManagement.PortalUrl)"
Write-Host "Management URL: $($ApiManagement.ManagementApiUrl)"
Write-Host " `nAPI Management Features:"
Write-Host "API Gateway functionality"
Write-Host "Developer portal"
Write-Host "API versioning and documentation"
Write-Host "Rate limiting and quotas"
Write-Host "Authentication and authorization"
Write-Host "Analytics and monitoring"
Write-Host " `nNext Steps:"
Write-Host " 1. Configure APIs and operations"
Write-Host " 2. Set up authentication policies"
Write-Host " 3. Configure rate limiting"
Write-Host " 4. Customize developer portal"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

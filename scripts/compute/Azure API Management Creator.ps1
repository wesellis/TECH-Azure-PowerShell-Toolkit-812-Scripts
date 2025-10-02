#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Api Management Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
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
Write-Output "Creating API Management service: $ServiceName"
Write-Output "This process may take 30-45 minutes..."
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Organization = $Organization
    Location = $Location
    AdminEmail = $AdminEmail
    ErrorAction = "Stop"
    Name = $ServiceName
}
    [string]$ApiManagement @params
Write-Output "API Management service created successfully:"
Write-Output "Name: $($ApiManagement.Name)"
Write-Output "Location: $($ApiManagement.Location)"
Write-Output "SKU: $($ApiManagement.Sku)"
Write-Output "Gateway URL: $($ApiManagement.GatewayUrl)"
Write-Output "Portal URL: $($ApiManagement.PortalUrl)"
Write-Output "Management URL: $($ApiManagement.ManagementApiUrl)"
Write-Output " `nAPI Management Features:"
Write-Output "API Gateway functionality"
Write-Output "Developer portal"
Write-Output "API versioning and documentation"
Write-Output "Rate limiting and quotas"
Write-Output "Authentication and authorization"
Write-Output "Analytics and monitoring"
Write-Output " `nNext Steps:"
Write-Output " 1. Configure APIs and operations"
Write-Output " 2. Set up authentication policies"
Write-Output " 3. Configure rate limiting"
Write-Output " 4. Customize developer portal"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

<#
.SYNOPSIS
    Manage API Management

.DESCRIPTION
    Manage API Management
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ServiceName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter(Mandatory)]
    [string]$Organization,
    [Parameter(Mandatory)]
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
Write-Host "`nAPI Management Features:"
Write-Host "API Gateway functionality"
Write-Host "Developer portal"
Write-Host "API versioning and documentation"
Write-Host "Rate limiting and quotas"
Write-Host "Authentication and authorization"
Write-Host "Analytics and monitoring"
Write-Host "`nNext Steps:"
Write-Host "1. Configure APIs and operations"
Write-Host "2. Set up authentication policies"
Write-Host "3. Configure rate limiting"
Write-Host "4. Customize developer portal"


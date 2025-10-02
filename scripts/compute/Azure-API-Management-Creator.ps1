#Requires -Version 7.4
#Requires -Modules Az.ApiManagement

<#`n.SYNOPSIS
    Manage API Management

.DESCRIPTION
    Manage API Management
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
$ApiManagement @params
Write-Output "API Management service created successfully:"
Write-Output "Name: $($ApiManagement.Name)"
Write-Output "Location: $($ApiManagement.Location)"
Write-Output "SKU: $($ApiManagement.Sku)"
Write-Output "Gateway URL: $($ApiManagement.GatewayUrl)"
Write-Output "Portal URL: $($ApiManagement.PortalUrl)"
Write-Output "Management URL: $($ApiManagement.ManagementApiUrl)"
Write-Output "`nAPI Management Features:"
Write-Output "API Gateway functionality"
Write-Output "Developer portal"
Write-Output "API versioning and documentation"
Write-Output "Rate limiting and quotas"
Write-Output "Authentication and authorization"
Write-Output "Analytics and monitoring"
Write-Output "`nNext Steps:"
Write-Output "1. Configure APIs and operations"
Write-Output "2. Set up authentication policies"
Write-Output "3. Configure rate limiting"
Write-Output "4. Customize developer portal"




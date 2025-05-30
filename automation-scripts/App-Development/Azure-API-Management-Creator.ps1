# ============================================================================
# Script Name: Azure API Management Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure API Management service for API gateway functionality
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$Organization,
    
    [Parameter(Mandatory=$true)]
    [string]$AdminEmail,
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "Developer"
)

Write-Host "Creating API Management service: $ServiceName"
Write-Host "This process may take 30-45 minutes..."

$ApiManagement = New-AzApiManagement `
    -ResourceGroupName $ResourceGroupName `
    -Name $ServiceName `
    -Location $Location `
    -Organization $Organization `
    -AdminEmail $AdminEmail `
    -Sku $Sku

Write-Host "✅ API Management service created successfully:"
Write-Host "  Name: $($ApiManagement.Name)"
Write-Host "  Location: $($ApiManagement.Location)"
Write-Host "  SKU: $($ApiManagement.Sku)"
Write-Host "  Gateway URL: $($ApiManagement.GatewayUrl)"
Write-Host "  Portal URL: $($ApiManagement.PortalUrl)"
Write-Host "  Management URL: $($ApiManagement.ManagementApiUrl)"

Write-Host "`nAPI Management Features:"
Write-Host "• API Gateway functionality"
Write-Host "• Developer portal"
Write-Host "• API versioning and documentation"
Write-Host "• Rate limiting and quotas"
Write-Host "• Authentication and authorization"
Write-Host "• Analytics and monitoring"

Write-Host "`nNext Steps:"
Write-Host "1. Configure APIs and operations"
Write-Host "2. Set up authentication policies"
Write-Host "3. Configure rate limiting"
Write-Host "4. Customize developer portal"

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

Write-Information "Creating API Management service: $ServiceName"
Write-Information "This process may take 30-45 minutes..."

$ApiManagement = New-AzApiManagement -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $ServiceName `
    -Location $Location `
    -Organization $Organization `
    -AdminEmail $AdminEmail `
    -Sku $Sku

Write-Information "✅ API Management service created successfully:"
Write-Information "  Name: $($ApiManagement.Name)"
Write-Information "  Location: $($ApiManagement.Location)"
Write-Information "  SKU: $($ApiManagement.Sku)"
Write-Information "  Gateway URL: $($ApiManagement.GatewayUrl)"
Write-Information "  Portal URL: $($ApiManagement.PortalUrl)"
Write-Information "  Management URL: $($ApiManagement.ManagementApiUrl)"

Write-Information "`nAPI Management Features:"
Write-Information "• API Gateway functionality"
Write-Information "• Developer portal"
Write-Information "• API versioning and documentation"
Write-Information "• Rate limiting and quotas"
Write-Information "• Authentication and authorization"
Write-Information "• Analytics and monitoring"

Write-Information "`nNext Steps:"
Write-Information "1. Configure APIs and operations"
Write-Information "2. Set up authentication policies"
Write-Information "3. Configure rate limiting"
Write-Information "4. Customize developer portal"

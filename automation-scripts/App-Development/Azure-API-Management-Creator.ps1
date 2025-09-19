#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
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

#region Functions

Write-Information "Creating API Management service: $ServiceName"
Write-Information "This process may take 30-45 minutes..."

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

Write-Information " API Management service created successfully:"
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


#endregion

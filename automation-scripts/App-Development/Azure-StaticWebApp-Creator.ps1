# ============================================================================
# Script Name: Azure Static Web App Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Static Web Apps for JAMstack applications
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main",
    
    [Parameter(Mandatory=$false)]
    [string]$AppLocation = "/",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputLocation = "dist"
)

Write-Information "Creating Static Web App: $Name"

# Create Static Web App
$StaticWebApp = New-AzStaticWebApp -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $Name `
    -Location $Location

Write-Information "✅ Static Web App created successfully:"
Write-Information "  Name: $($StaticWebApp.Name)"
Write-Information "  Location: $($StaticWebApp.Location)"
Write-Information "  Default Hostname: $($StaticWebApp.DefaultHostname)"
Write-Information "  Resource ID: $($StaticWebApp.Id)"

if ($RepositoryUrl) {
    Write-Information "  Repository: $RepositoryUrl"
    Write-Information "  Branch: $Branch"
    Write-Information "  App Location: $AppLocation"
    Write-Information "  Output Location: $OutputLocation"
}

Write-Information "`nStatic Web App Features:"
Write-Information "• Global CDN distribution"
Write-Information "• Automatic HTTPS"
Write-Information "• Custom domains"
Write-Information "• Staging environments"
Write-Information "• GitHub/Azure DevOps integration"
Write-Information "• Built-in authentication"
Write-Information "• Serverless API support"

Write-Information "`nNext Steps:"
Write-Information "1. Connect to Git repository"
Write-Information "2. Configure build and deployment"
Write-Information "3. Set up custom domain"
Write-Information "4. Configure authentication providers"
Write-Information "5. Add API functions if needed"

Write-Information "`nAccess your app at: https://$($StaticWebApp.DefaultHostname)"

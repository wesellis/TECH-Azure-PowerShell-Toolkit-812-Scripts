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

Write-Host "Creating Static Web App: $Name"

# Prepare deployment properties
$Properties = @{
    repositoryUrl = $RepositoryUrl
    branch = $Branch
    buildProperties = @{
        appLocation = $AppLocation
        outputLocation = $OutputLocation
    }
}

# Create Static Web App
$StaticWebApp = New-AzStaticWebApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $Name `
    -Location $Location

Write-Host "✅ Static Web App created successfully:"
Write-Host "  Name: $($StaticWebApp.Name)"
Write-Host "  Location: $($StaticWebApp.Location)"
Write-Host "  Default Hostname: $($StaticWebApp.DefaultHostname)"
Write-Host "  Resource ID: $($StaticWebApp.Id)"

if ($RepositoryUrl) {
    Write-Host "  Repository: $RepositoryUrl"
    Write-Host "  Branch: $Branch"
    Write-Host "  App Location: $AppLocation"
    Write-Host "  Output Location: $OutputLocation"
}

Write-Host "`nStatic Web App Features:"
Write-Host "• Global CDN distribution"
Write-Host "• Automatic HTTPS"
Write-Host "• Custom domains"
Write-Host "• Staging environments"
Write-Host "• GitHub/Azure DevOps integration"
Write-Host "• Built-in authentication"
Write-Host "• Serverless API support"

Write-Host "`nNext Steps:"
Write-Host "1. Connect to Git repository"
Write-Host "2. Configure build and deployment"
Write-Host "3. Set up custom domain"
Write-Host "4. Configure authentication providers"
Write-Host "5. Add API functions if needed"

Write-Host "`nAccess your app at: https://$($StaticWebApp.DefaultHostname)"

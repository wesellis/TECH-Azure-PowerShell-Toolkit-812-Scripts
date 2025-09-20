#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$Name,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$RepositoryUrl,
    [Parameter()]
    [string]$Branch = "main",
    [Parameter()]
    [string]$AppLocation = "/",
    [Parameter()]
    [string]$OutputLocation = "dist"
)
Write-Host "Creating Static Web App: $Name"
# Create Static Web App
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    Location = $Location
}
$StaticWebApp @params
Write-Host "Static Web App created successfully:"
Write-Host "Name: $($StaticWebApp.Name)"
Write-Host "Location: $($StaticWebApp.Location)"
Write-Host "Default Hostname: $($StaticWebApp.DefaultHostname)"
Write-Host "Resource ID: $($StaticWebApp.Id)"
if ($RepositoryUrl) {
    Write-Host "Repository: $RepositoryUrl"
    Write-Host "Branch: $Branch"
    Write-Host "App Location: $AppLocation"
    Write-Host "Output Location: $OutputLocation"
}
Write-Host "`nStatic Web App Features:"
Write-Host "Global CDN distribution"
Write-Host "Automatic HTTPS"
Write-Host "Custom domains"
Write-Host "Staging environments"
Write-Host "GitHub/Azure DevOps integration"
Write-Host "Built-in authentication"
Write-Host "Serverless API support"
Write-Host "`nNext Steps:"
Write-Host "1. Connect to Git repository"
Write-Host "2. Configure build and deployment"
Write-Host "3. Set up custom domain"
Write-Host "4. Configure authentication providers"
Write-Host "5. Add API functions if needed"
Write-Host "`nAccess your app at: https://$($StaticWebApp.DefaultHostname)"


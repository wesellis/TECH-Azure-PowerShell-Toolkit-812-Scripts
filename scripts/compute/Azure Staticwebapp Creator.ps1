#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Staticwebapp Creator

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
    [string]$Name,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryUrl,
    [Parameter()]
    [string]$Branch = " main" ,
    [Parameter()]
    [string]$AppLocation = "/" ,
    [Parameter()]
    [string]$OutputLocation = " dist"
)
Write-Output "Creating Static Web App: $Name"
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    Location = $Location
}
    [string]$StaticWebApp @params
Write-Output "Static Web App created successfully:"
Write-Output "Name: $($StaticWebApp.Name)"
Write-Output "Location: $($StaticWebApp.Location)"
Write-Output "Default Hostname: $($StaticWebApp.DefaultHostname)"
Write-Output "Resource ID: $($StaticWebApp.Id)"
if ($RepositoryUrl) {
    Write-Output "Repository: $RepositoryUrl"
    Write-Output "Branch: $Branch"
    Write-Output "App Location: $AppLocation"
    Write-Output "Output Location: $OutputLocation"
}
Write-Output " `nStatic Web App Features:"
Write-Output "Global CDN distribution"
Write-Output "Automatic HTTPS"
Write-Output "Custom domains"
Write-Output "Staging environments"
Write-Output "GitHub/Azure DevOps integration"
Write-Output "Built-in authentication"
Write-Output "Serverless API support"
Write-Output " `nNext Steps:"
Write-Output " 1. Connect to Git repository"
Write-Output " 2. Configure build and deployment"
Write-Output " 3. Set up custom domain"
Write-Output " 4. Configure authentication providers"
Write-Output " 5. Add API functions if needed"
Write-Output " `nAccess your app at: https://$($StaticWebApp.DefaultHostname)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

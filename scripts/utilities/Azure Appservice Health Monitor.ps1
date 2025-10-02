#Requires -Version 7.4
#Requires -Modules Az.Websites

<#
.SYNOPSIS
    Azure App Service Health Monitor

.DESCRIPTION
    Monitors the health and configuration of Azure App Services,
    including deployment slots, settings, and runtime information

.PARAMETER ResourceGroupName
    Name of the resource group containing the App Service

.PARAMETER AppName
    Name of the App Service to monitor

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    $logEntry = "$timestamp [AppService-Monitor] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Starting App Service Health Monitor" -Level INFO
    Write-Host "============================================" -ForegroundColor DarkGray
    Write-ColorOutput "Monitoring App Service: $AppName" -Level INFO
    Write-ColorOutput "Resource Group: $ResourceGroupName" -Level INFO
    Write-Host "============================================" -ForegroundColor DarkGray

    # Get App Service details
    Write-Verbose "Retrieving App Service information..."
    $webApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction Stop

    Write-Host "`nApp Service Information:" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray
    Write-Host "Name: $($webApp.Name)"

    # Display state with color coding
    $stateColor = switch ($webApp.State) {
        "Running" { "Green" }
        "Stopped" { "Red" }
        default { "Yellow" }
    }
    Write-Host "State: " -NoNewline
    Write-Host $webApp.State -ForegroundColor $stateColor

    Write-Host "Location: $($webApp.Location)"
    Write-Host "Default Hostname: $($webApp.DefaultHostName)"
    Write-Host "Repository Site Name: $($webApp.RepositorySiteName)"

    # Extract App Service Plan name
    $appServicePlanName = $webApp.ServerFarmId.Split('/')[-1]
    Write-Host "App Service Plan: $appServicePlanName"

    # Runtime configuration
    Write-Host "`nRuntime Configuration:" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray

    if ($webApp.SiteConfig.NetFrameworkVersion) {
        Write-Host ".NET Framework Version: $($webApp.SiteConfig.NetFrameworkVersion)"
    }

    if ($webApp.SiteConfig.PhpVersion) {
        Write-Host "PHP Version: $($webApp.SiteConfig.PhpVersion)"
    }

    if ($webApp.SiteConfig.NodeVersion) {
        Write-Host "Node Version: $($webApp.SiteConfig.NodeVersion)"
    }

    if ($webApp.SiteConfig.PythonVersion) {
        Write-Host "Python Version: $($webApp.SiteConfig.PythonVersion)"
    }

    if ($webApp.SiteConfig.JavaVersion) {
        Write-Host "Java Version: $($webApp.SiteConfig.JavaVersion)"
    }

    $platform = if ($webApp.SiteConfig.Use32BitWorkerProcess) { "32-bit" } else { "64-bit" }
    Write-Host "Platform Architecture: $platform"
    Write-Host "Always On: $($webApp.SiteConfig.AlwaysOn)"
    Write-Host "HTTP Version: $($webApp.SiteConfig.Http20Enabled ? 'HTTP/2.0' : 'HTTP/1.1')"
    Write-Host "Managed Pipeline Mode: $($webApp.SiteConfig.ManagedPipelineMode)"

    # Security settings
    Write-Host "`nSecurity Settings:" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray
    Write-Host "HTTPS Only: $($webApp.HttpsOnly)"
    Write-Host "Client Certificate Enabled: $($webApp.ClientCertEnabled)"
    Write-Host "TLS Version: $($webApp.SiteConfig.MinTlsVersion)"

    # App Settings
    $appSettingsCount = if ($webApp.SiteConfig.AppSettings) {
        $webApp.SiteConfig.AppSettings.Count
    } else {
        0
    }
    Write-Host "`nConfiguration:" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray
    Write-Host "App Settings Count: $appSettingsCount"

    $connectionStringsCount = if ($webApp.SiteConfig.ConnectionStrings) {
        $webApp.SiteConfig.ConnectionStrings.Count
    } else {
        0
    }
    Write-Host "Connection Strings Count: $connectionStringsCount"

    # Deployment slots
    Write-Host "`nDeployment Slots:" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray

    $slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction SilentlyContinue

    if ($slots) {
        Write-Host "Deployment Slots Count: $($slots.Count)"
        foreach ($slot in $slots) {
            $slotStateColor = if ($slot.State -eq "Running") { "Green" } else { "Red" }
            Write-Host "  - $($slot.Name.Split('/')[-1]): " -NoNewline
            Write-Host $slot.State -ForegroundColor $slotStateColor
        }
    } else {
        Write-Host "Deployment Slots: None configured"
    }

    # Check recent metrics if available
    Write-Host "`nHealth Check:" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray

    if ($webApp.State -eq "Running") {
        Write-ColorOutput "App Service is running and accessible" -Level SUCCESS

        # Test default hostname connectivity
        $uri = "https://$($webApp.DefaultHostName)"
        try {
            $response = Invoke-WebRequest -Uri $uri -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-ColorOutput "Default hostname is responding (HTTP $($response.StatusCode))" -Level SUCCESS
            } else {
                Write-ColorOutput "Default hostname returned status: HTTP $($response.StatusCode)" -Level WARN
            }
        }
        catch {
            Write-ColorOutput "Could not reach default hostname (may require authentication)" -Level WARN
        }
    }
    else {
        Write-ColorOutput "App Service is not running" -Level WARN
    }

    Write-Host "`n============================================" -ForegroundColor DarkGray
    Write-ColorOutput "App Service monitoring completed at $(Get-Date)" -Level SUCCESS
}
catch {
    Write-ColorOutput "Failed to monitor App Service: $($_.Exception.Message)" -Level ERROR
    throw
}
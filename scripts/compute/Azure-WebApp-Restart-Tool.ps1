#Requires -Version 7.4
#Requires -Modules Az.Websites

<#
.SYNOPSIS
    Restart Azure Web App

.DESCRIPTION
    Restarts an Azure Web App or App Service with proper error handling and validation
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER ResourceGroupName
    Name of the resource group containing the web app

.PARAMETER AppName
    Name of the Azure Web App to restart

.PARAMETER Force
    Skip confirmation prompt

.EXAMPLE
    .\Azure-WebApp-Restart-Tool.ps1 -ResourceGroupName "rg-prod" -AppName "webapp-prod"
    Restarts the specified web app with confirmation

.EXAMPLE
    .\Azure-WebApp-Restart-Tool.ps1 -ResourceGroupName "rg-prod" -AppName "webapp-prod" -Force
    Restarts the web app without confirmation

.NOTES
    Requires Az.Websites module and appropriate permissions
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO"    = "Cyan"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "SUCCESS" = "Green"
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

try {
    Write-LogMessage "Starting Web App restart operation" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "App Name: $AppName" -Level "INFO"

    # Verify the web app exists
    Write-LogMessage "Verifying web app exists..." -Level "INFO"
    $webApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction Stop

    if (-not $webApp) {
        throw "Web app '$AppName' not found in resource group '$ResourceGroupName'"
    }

    Write-LogMessage "Web app found: $($webApp.Name)" -Level "SUCCESS"
    Write-LogMessage "Location: $($webApp.Location)" -Level "INFO"
    Write-LogMessage "State: $($webApp.State)" -Level "INFO"

    # Confirm restart if not using -Force
    if (-not $Force -and $PSCmdlet.ShouldProcess($AppName, "Restart Web App")) {
        $confirmation = Read-Host "Are you sure you want to restart '$AppName'? (Y/N)"
        if ($confirmation -ne 'Y') {
            Write-LogMessage "Restart cancelled by user" -Level "WARN"
            return
        }
    }

    # Restart the web app
    Write-LogMessage "Restarting web app..." -Level "INFO"
    Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -ErrorAction Stop

    Write-LogMessage "Web app restarted successfully" -Level "SUCCESS"

    # Wait a moment and check status
    Start-Sleep -Seconds 2
    $updatedWebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
    Write-LogMessage "Current state: $($updatedWebApp.State)" -Level "INFO"

} catch {
    Write-LogMessage "Failed to restart web app: $($_.Exception.Message)" -Level "ERROR"
    throw
}

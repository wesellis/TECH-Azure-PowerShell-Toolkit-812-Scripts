# ============================================================================
# Script Name: Azure CLI PowerShell Bridge
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Bridge Azure CLI commands with PowerShell for cross-platform automation
# ============================================================================

param (
    [string]$Command,
    [string]$OutputFormat = "json",
    [switch]$PassThru
)

Write-Host "Azure CLI PowerShell Bridge" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Check if Azure CLI is installed
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "✓ Azure CLI Version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    return
}

# Check if logged in to Azure CLI
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "✓ Subscription: $($account.name)" -ForegroundColor Green
} catch {
    Write-Warning "Not logged in to Azure CLI. Please run 'az login' first."
    if (-not $Force) {
        return
    }
}

if (-not $Command) {
    Write-Host "`nUsage Examples:" -ForegroundColor Yellow
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az vm list'" -ForegroundColor White
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az group list' -OutputFormat 'table'" -ForegroundColor White
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az account show' -PassThru" -ForegroundColor White
    return
}

Write-Host "`nExecuting: $Command --output $OutputFormat" -ForegroundColor Yellow

try {
    # Execute Azure CLI command safely without Invoke-Expression
    $commandParts = $Command.Split(' ') + @('--output', $OutputFormat)
    $result = & $commandParts[0] @commandParts[1..($commandParts.Length-1)]
    
    if ($OutputFormat -eq "json" -and -not $PassThru) {
        # Parse JSON and return as PowerShell objects
        $jsonResult = $result | ConvertFrom-Json
        Write-Host "`n✓ Command executed successfully" -ForegroundColor Green
        return $jsonResult
    } else {
        # Return raw output
        Write-Host "`n✓ Command executed successfully" -ForegroundColor Green
        return $result
    }
} catch {
    Write-Error "Failed to execute Azure CLI command: $($_.Exception.Message)"
    return $null
}

Write-Host "`nAzure CLI bridge completed at $(Get-Date)" -ForegroundColor Cyan
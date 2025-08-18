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

Write-Information "Azure CLI PowerShell Bridge"
Write-Information "==========================="

# Check if Azure CLI is installed
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Information "✓ Azure CLI Version: $($azVersion.'azure-cli')"
} catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    return
}

# Check if logged in to Azure CLI
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Information "✓ Logged in as: $($account.user.name)"
    Write-Information "✓ Subscription: $($account.name)"
} catch {
    Write-Warning "Not logged in to Azure CLI. Please run 'az login' first."
    if (-not $Force) {
        return
    }
}

if (-not $Command) {
    Write-Information "`nUsage Examples:"
    Write-Information "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az vm list'"
    Write-Information "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az group list' -OutputFormat 'table'"
    Write-Information "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az account show' -PassThru"
    return
}

Write-Information "`nExecuting: $Command --output $OutputFormat"

try {
    # Execute Azure CLI command safely without Invoke-Expression
    $commandParts = $Command.Split(' ') + @('--output', $OutputFormat)
    $result = & $commandParts[0] $commandParts[1..($commandParts.Length-1)]
    
    if ($OutputFormat -eq "json" -and -not $PassThru) {
        # Parse JSON and return as PowerShell objects
        $jsonResult = $result | ConvertFrom-Json
        Write-Information "`n✓ Command executed successfully"
        return $jsonResult
    } else {
        # Return raw output
        Write-Information "`n✓ Command executed successfully"
        return $result
    }
} catch {
    Write-Error "Failed to execute Azure CLI command: $($_.Exception.Message)"
    return $null
}

Write-Information "`nAzure CLI bridge completed at $(Get-Date)"
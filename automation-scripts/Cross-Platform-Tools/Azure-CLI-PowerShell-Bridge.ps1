<#
.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [string]$Command,
    [string]$OutputFormat = "json",
    [switch]$PassThru
)
Write-Host "Azure CLI PowerShell Bridge"
Write-Host "==========================="
# Check if Azure CLI is installed
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "[OK] Azure CLI Version: $($azVersion.'azure-cli')"
} catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    return
}
# Check if logged in to Azure CLI
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "[OK] Logged in as: $($account.user.name)"
    Write-Host "[OK] Subscription: $($account.name)"
} catch {
    Write-Warning "Not logged in to Azure CLI. Please run 'az login' first."
    if (-not $Force) {
        return
    }
}
if (-not $Command) {
    Write-Host "`nUsage Examples:"
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az vm list'"
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az group list' -OutputFormat 'table'"
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az account show' -PassThru"
    return
}
Write-Host "`nExecuting: $Command --output $OutputFormat"
try {
    # Execute Azure CLI command safely without Invoke-Expression
    $commandParts = $Command.Split(' ') + @('--output', $OutputFormat)
    $result = & $commandParts[0] $commandParts[1..($commandParts.Length-1)]
    if ($OutputFormat -eq "json" -and -not $PassThru) {
        # Parse JSON and return as PowerShell objects
        $jsonResult = $result | ConvertFrom-Json
        Write-Host "`n[OK] Command executed successfully"
        return $jsonResult
    } else {
        # Return raw output
        Write-Host "`n[OK] Command executed successfully"
        return $result
    }
} catch {
    Write-Error "Failed to execute Azure CLI command: $($_.Exception.Message)"
    return $null
}
Write-Host "`nAzure CLI bridge completed at $(Get-Date)"


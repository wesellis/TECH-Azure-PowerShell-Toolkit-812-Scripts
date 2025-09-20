<#
.SYNOPSIS
    Azure Cli Powershell Bridge

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([PSObject])]
 {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $logEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Command,
    [string]$OutputFormat = "json",
    [switch]$PassThru
)
Write-Host "Azure CLI PowerShell Bridge" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "[OK] Azure CLI Version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    return
}
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "[OK] Subscription: $($account.name)" -ForegroundColor Green
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
Write-Host " `nExecuting: $Command --output $OutputFormat" -ForegroundColor Yellow
try {
    # Execute Azure CLI command safely without Invoke-Expression
    $commandParts = $Command.Split(' ') + @('--output', $OutputFormat)
$result = & $commandParts[0] $commandParts[1..($commandParts.Length-1)]
    if ($OutputFormat -eq " json" -and -not $PassThru) {
        # Parse JSON and return as PowerShell objects
$jsonResult = $result | ConvertFrom-Json
        Write-Host " `n[OK] Command executed successfully" -ForegroundColor Green
        return $jsonResult
    } else {
        # Return raw output
        Write-Host " `n[OK] Command executed successfully" -ForegroundColor Green
        return $result
    }
} catch {
    Write-Error "Failed to execute Azure CLI command: $($_.Exception.Message)"
    return $null
}
Write-Host " `nAzure CLI bridge completed at $(Get-Date)" -ForegroundColor Cyan


#Requires -Version 7.4

<#
.SYNOPSIS
    Manage Azure resources using CLI bridge

.DESCRIPTION
    Automate Azure operations using Azure CLI commands from PowerShell

.PARAMETER Command
    The Azure CLI command to execute

.PARAMETER OutputFormat
    Output format for the command (json, table, tsv, yaml)

.PARAMETER PassThru
    Return raw output without conversion

.PARAMETER Force
    Force execution even if not logged in

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires Azure CLI installed
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Command,

    [Parameter()]
    [ValidateSet("json", "table", "tsv", "yaml")]
    [string]$OutputFormat = "json",

    [Parameter()]
    [switch]$PassThru,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Write-Host "Azure CLI PowerShell Bridge" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor DarkGray

# Check Azure CLI installation
try {
    $AzVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "[OK] Azure CLI Version: $($AzVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    return
}

# Check authentication
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "[OK] Subscription: $($account.name)" -ForegroundColor Green
}
catch {
    Write-Warning "Not logged in to Azure CLI. Please run 'az login' first."
    if (-not $Force) {
        return
    }
}

# Show usage if no command provided
if (-not $Command) {
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az vm list'" -ForegroundColor DarkGray
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az group list' -OutputFormat 'table'" -ForegroundColor DarkGray
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az account show' -PassThru" -ForegroundColor DarkGray
    return
}

Write-Host "`nExecuting: $Command --output $OutputFormat" -ForegroundColor Yellow

try {
    # Parse and execute the command
    $CommandParts = $Command.Split(' ') + @('--output', $OutputFormat)
    $result = & $CommandParts[0] $CommandParts[1..($CommandParts.Length-1)]

    if ($OutputFormat -eq "json" -and -not $PassThru) {
        $JsonResult = $result | ConvertFrom-Json
        Write-Host "`n[OK] Command executed successfully" -ForegroundColor Green
        return $JsonResult
    }
    else {
        Write-Host "`n[OK] Command executed successfully" -ForegroundColor Green
        return $result
    }
}
catch {
    Write-Error "Failed to execute Azure CLI command: $($_.Exception.Message)"
    return $null
}
finally {
    Write-Verbose "Azure CLI bridge completed at $(Get-Date)"
}
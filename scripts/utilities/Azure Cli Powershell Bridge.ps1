#Requires -Version 7.4

<#
.SYNOPSIS
    Azure CLI PowerShell Bridge

.DESCRIPTION
    Provides a bridge between Azure CLI and PowerShell, allowing seamless
    execution of Azure CLI commands within PowerShell scripts with output conversion

.PARAMETER Command
    The Azure CLI command to execute (without 'az' prefix)

.PARAMETER OutputFormat
    Output format for Azure CLI (json, table, tsv, yaml)

.PARAMETER PassThru
    Return raw output without conversion

.PARAMETER Force
    Force execution even if not logged in

.EXAMPLE
    .\Azure-CLI-PowerShell-Bridge.ps1 -Command "vm list" -OutputFormat "json"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and Azure CLI installed
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Command,

    [Parameter()]
    [ValidateSet("json", "table", "tsv", "yaml")]
    [string]$OutputFormat = "json",

    [Parameter()]
    [switch]$PassThru,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    $LogEntry = "$timestamp [CLI-Bridge] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

Write-Host "Azure CLI PowerShell Bridge" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor DarkGray

# Check Azure CLI installation
try {
    $azVersionOutput = az version 2>$null
    if ($azVersionOutput) {
        $AzVersion = $azVersionOutput | ConvertFrom-Json
        Write-Log "[OK] Azure CLI Version: $($AzVersion.'azure-cli')" -Level SUCCESS
    } else {
        throw "Unable to get Azure CLI version"
    }
}
catch {
    Write-Log "Azure CLI is not installed or not in PATH. Please install Azure CLI first." -Level ERROR
    return
}

# Check Azure CLI authentication
try {
    $accountOutput = az account show 2>$null
    if ($accountOutput) {
        $account = $accountOutput | ConvertFrom-Json
        Write-Log "Logged in as: $($account.user.name)" -Level SUCCESS
        Write-Log "Subscription: $($account.name)" -Level INFO
    } else {
        throw "Not authenticated"
    }
}
catch {
    Write-Log "Not logged in to Azure CLI. Please run 'az login' first." -Level WARN
    if (-not $Force) {
        return
    }
    Write-Log "Continuing with Force parameter..." -Level INFO
}

# Show usage if no command provided
if (-not $Command) {
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'vm list'" -ForegroundColor DarkGray
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'group list' -OutputFormat 'table'" -ForegroundColor DarkGray
    Write-Host "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'account show' -PassThru" -ForegroundColor DarkGray
    Write-Host "`nCommon Commands:" -ForegroundColor Cyan
    Write-Host "  vm list                  - List all VMs" -ForegroundColor DarkGray
    Write-Host "  group list               - List resource groups" -ForegroundColor DarkGray
    Write-Host "  storage account list     - List storage accounts" -ForegroundColor DarkGray
    Write-Host "  webapp list              - List web apps" -ForegroundColor DarkGray
    Write-Host "  network vnet list        - List virtual networks" -ForegroundColor DarkGray
    return
}

# Execute Azure CLI command
Write-Log "Executing: az $Command --output $OutputFormat" -Level INFO

try {
    # Build the full command
    $fullCommand = "az $Command --output $OutputFormat"
    Write-Verbose "Full command: $fullCommand"

    # Execute the command
    $result = Invoke-Expression $fullCommand 2>&1

    # Check for errors
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed with exit code $LASTEXITCODE"
    }

    # Process output based on format
    if ($OutputFormat -eq "json" -and -not $PassThru) {
        try {
            $JsonResult = $result | ConvertFrom-Json
            Write-Log "Command executed successfully" -Level SUCCESS
            Write-Verbose "Converted JSON output to PowerShell object"

            # Display summary if applicable
            if ($JsonResult -is [array]) {
                Write-Host "`nResults: $($JsonResult.Count) items returned" -ForegroundColor Cyan
            }

            return $JsonResult
        }
        catch {
            Write-Log "Failed to parse JSON output. Returning raw result." -Level WARN
            return $result
        }
    }
    else {
        Write-Log "Command executed successfully" -Level SUCCESS
        return $result
    }
}
catch {
    Write-Log "Failed to execute Azure CLI command: $($_.Exception.Message)" -Level ERROR

    # Provide helpful error messages
    if ($_.Exception.Message -like "*az: command not found*") {
        Write-Host "`nPlease ensure Azure CLI is installed and in your PATH" -ForegroundColor Yellow
        Write-Host "Installation guide: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    }
    elseif ($_.Exception.Message -like "*Please run 'az login'*") {
        Write-Host "`nYou need to authenticate first. Run: az login" -ForegroundColor Yellow
    }

    return $null
}
finally {
    Write-Verbose "Azure CLI bridge completed at $(Get-Date)"
}
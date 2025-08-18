<#
.SYNOPSIS
    Azure Cli Powershell Bridge

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Cli Powershell Bridge

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECommand,
    [string]$WEOutputFormat = " json" ,
    [switch]$WEPassThru
)

Write-WELog " Azure CLI PowerShell Bridge" " INFO" -ForegroundColor Cyan
Write-WELog " ===========================" " INFO" -ForegroundColor Cyan


try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-WELog " ✓ Azure CLI Version: $($azVersion.'azure-cli')" " INFO" -ForegroundColor Green
} catch {
    Write-Error " Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    return
}


try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-WELog " ✓ Logged in as: $($account.user.name)" " INFO" -ForegroundColor Green
    Write-WELog " ✓ Subscription: $($account.name)" " INFO" -ForegroundColor Green
} catch {
    Write-Warning " Not logged in to Azure CLI. Please run 'az login' first."
    if (-not $WEForce) {
        return
    }
}

if (-not $WECommand) {
    Write-WELog " `nUsage Examples:" " INFO" -ForegroundColor Yellow
    Write-WELog "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az vm list'" " INFO" -ForegroundColor White
    Write-WELog "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az group list' -OutputFormat 'table'" " INFO" -ForegroundColor White
    Write-WELog "  .\Azure-CLI-PowerShell-Bridge.ps1 -Command 'az account show' -PassThru" " INFO" -ForegroundColor White
    return
}

Write-WELog " `nExecuting: $WECommand --output $WEOutputFormat" " INFO" -ForegroundColor Yellow

try {
    # Execute Azure CLI command safely without Invoke-Expression
    $commandParts = $WECommand.Split(' ') + @('--output', $WEOutputFormat)
   ;  $result = & $commandParts[0] $commandParts[1..($commandParts.Length-1)]
    
    if ($WEOutputFormat -eq " json" -and -not $WEPassThru) {
        # Parse JSON and return as PowerShell objects
       ;  $jsonResult = $result | ConvertFrom-Json
        Write-WELog " `n✓ Command executed successfully" " INFO" -ForegroundColor Green
        return $jsonResult
    } else {
        # Return raw output
        Write-WELog " `n✓ Command executed successfully" " INFO" -ForegroundColor Green
        return $result
    }
} catch {
    Write-Error " Failed to execute Azure CLI command: $($_.Exception.Message)"
    return $null
}

Write-WELog " `nAzure CLI bridge completed at $(Get-Date)" " INFO" -ForegroundColor Cyan


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
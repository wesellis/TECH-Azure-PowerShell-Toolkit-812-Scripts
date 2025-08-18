<#
.SYNOPSIS
    We Enhanced Azure Subscription Switcher

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    [switch]$WEList,
    [switch]$WECurrent
)

Write-WELog " Azure Subscription Switcher" " INFO" -ForegroundColor Cyan
Write-WELog " ===========================" " INFO" -ForegroundColor Cyan


if ($WECurrent) {
    $context = Get-AzContext
    if ($context) {
        Write-WELog " Current Subscription:" " INFO" -ForegroundColor Green
        Write-WELog "  Name: $($context.Subscription.Name)" " INFO" -ForegroundColor White
        Write-WELog "  ID: $($context.Subscription.Id)" " INFO" -ForegroundColor White
        Write-WELog "  Tenant: $($context.Tenant.Id)" " INFO" -ForegroundColor White
    } else {
        Write-WELog " No active Azure context. Please run Connect-AzAccount first." " INFO" -ForegroundColor Red
    }
    return
}


if ($WEList) {
    Write-WELog " Available Subscriptions:" " INFO" -ForegroundColor Green
    $subscriptions = Get-AzSubscription
    foreach ($sub in $subscriptions) {
        $status = if ($sub.State -eq " Enabled") { " ✓" } else { " ✗" }
        Write-WELog "  $status $($sub.Name) ($($sub.Id))" " INFO" -ForegroundColor White
    }
    return
}


if ($WESubscriptionName) {
    try {
        $subscription = Get-AzSubscription -SubscriptionName $WESubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-WELog " ✓ Switched to subscription: $($subscription.Name)" " INFO" -ForegroundColor Green
    } catch {
        Write-Error " Failed to switch to subscription '$WESubscriptionName': $($_.Exception.Message)"
    }
} elseif ($WESubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $WESubscriptionId
       ;  $subscription = Get-AzSubscription -SubscriptionId $WESubscriptionId
        Write-WELog " ✓ Switched to subscription: $($subscription.Name)" " INFO" -ForegroundColor Green
    } catch {
        Write-Error " Failed to switch to subscription '$WESubscriptionId': $($_.Exception.Message)"
    }
} else {
    Write-WELog " Usage Examples:" " INFO" -ForegroundColor Yellow
    Write-WELog "  .\Azure-Subscription-Switcher.ps1 -List" " INFO" -ForegroundColor White
    Write-WELog "  .\Azure-Subscription-Switcher.ps1 -Current" " INFO" -ForegroundColor White
    Write-WELog "  .\Azure-Subscription-Switcher.ps1 -SubscriptionName 'Production'" " INFO" -ForegroundColor White
    Write-WELog "  .\Azure-Subscription-Switcher.ps1 -SubscriptionId '12345678-1234-1234-1234-123456789012'" " INFO" -ForegroundColor White
}

Write-WELog " `nSubscription switching completed at $(Get-Date)" " INFO" -ForegroundColor Cyan


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
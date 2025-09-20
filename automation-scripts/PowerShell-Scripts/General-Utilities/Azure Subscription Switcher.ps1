<#
.SYNOPSIS
    Azure Subscription Switcher

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [switch]$List,
    [switch]$Current
)
Write-Host "Azure Subscription Switcher" -ForegroundColor Cyan
Write-Host " ===========================" -ForegroundColor Cyan
if ($Current) {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Host "Current Subscription:" -ForegroundColor Green
        Write-Host "Name: $($context.Subscription.Name)" -ForegroundColor White
        Write-Host "ID: $($context.Subscription.Id)" -ForegroundColor White
        Write-Host "Tenant: $($context.Tenant.Id)" -ForegroundColor White
    } else {
        Write-Host "No active Azure context. Please run Connect-AzAccount first." -ForegroundColor Red
    }
    return
}
if ($List) {
    Write-Host "Available Subscriptions:" -ForegroundColor Green
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    foreach ($sub in $subscriptions) {
        $status = if ($sub.State -eq "Enabled" ) { "[OK]" } else { " [FAIL]" }
        Write-Host "  $status $($sub.Name) ($($sub.Id))" -ForegroundColor White
    }
    return
}
if ($SubscriptionName) {
    try {
$subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Host "[OK] Switched to subscription: $($subscription.Name)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
$subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Host "[OK] Switched to subscription: $($subscription.Name)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionId': $($_.Exception.Message)"
    }
} else {
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -List" -ForegroundColor White
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -Current" -ForegroundColor White
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -SubscriptionName 'Production'" -ForegroundColor White
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -SubscriptionId '12345678-1234-1234-1234-123456789012'" -ForegroundColor White
}
Write-Host " `nSubscription switching completed at $(Get-Date)" -ForegroundColor Cyan\n
# ============================================================================
# Script Name: Azure Subscription Switcher
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Quick Azure subscription context switching utility
# ============================================================================

param (
    [string]$SubscriptionName,
    [string]$SubscriptionId,
    [switch]$List,
    [switch]$Current
)

Write-Host "Azure Subscription Switcher" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Show current subscription
if ($Current) {
    $context = Get-AzContext
    if ($context) {
        Write-Host "Current Subscription:" -ForegroundColor Green
        Write-Host "  Name: $($context.Subscription.Name)" -ForegroundColor White
        Write-Host "  ID: $($context.Subscription.Id)" -ForegroundColor White
        Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor White
    } else {
        Write-Host "No active Azure context. Please run Connect-AzAccount first." -ForegroundColor Red
    }
    return
}

# List available subscriptions
if ($List) {
    Write-Host "Available Subscriptions:" -ForegroundColor Green
    $subscriptions = Get-AzSubscription
    foreach ($sub in $subscriptions) {
        $status = if ($sub.State -eq "Enabled") { "✓" } else { "✗" }
        Write-Host "  $status $($sub.Name) ($($sub.Id))" -ForegroundColor White
    }
    return
}

# Switch to specified subscription
if ($SubscriptionName) {
    try {
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Host "✓ Switched to subscription: $($subscription.Name)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Host "✓ Switched to subscription: $($subscription.Name)" -ForegroundColor Green
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

Write-Host "`nSubscription switching completed at $(Get-Date)" -ForegroundColor Cyan
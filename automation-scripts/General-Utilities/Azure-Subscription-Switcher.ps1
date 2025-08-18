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

Write-Information "Azure Subscription Switcher"
Write-Information "==========================="

# Show current subscription
if ($Current) {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Information "Current Subscription:"
        Write-Information "  Name: $($context.Subscription.Name)"
        Write-Information "  ID: $($context.Subscription.Id)"
        Write-Information "  Tenant: $($context.Tenant.Id)"
    } else {
        Write-Information "No active Azure context. Please run Connect-AzAccount first."
    }
    return
}

# List available subscriptions
if ($List) {
    Write-Information "Available Subscriptions:"
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    foreach ($sub in $subscriptions) {
        $status = if ($sub.State -eq "Enabled") { "✓" } else { "✗" }
        Write-Information "  $status $($sub.Name) ($($sub.Id))"
    }
    return
}

# Switch to specified subscription
if ($SubscriptionName) {
    try {
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Information "✓ Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Information "✓ Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionId': $($_.Exception.Message)"
    }
} else {
    Write-Information "Usage Examples:"
    Write-Information "  .\Azure-Subscription-Switcher.ps1 -List"
    Write-Information "  .\Azure-Subscription-Switcher.ps1 -Current"
    Write-Information "  .\Azure-Subscription-Switcher.ps1 -SubscriptionName 'Production'"
    Write-Information "  .\Azure-Subscription-Switcher.ps1 -SubscriptionId '12345678-1234-1234-1234-123456789012'"
}

Write-Information "`nSubscription switching completed at $(Get-Date)"
#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$SubscriptionName,
    [string]$SubscriptionId,
    [switch]$List,
    [switch]$Current
)

#region Functions

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
        $status = if ($sub.State -eq "Enabled") { "[OK]" } else { "[FAIL]" }
        Write-Information "  $status $($sub.Name) ($($sub.Id))"
    }
    return
}

# Switch to specified subscription
if ($SubscriptionName) {
    try {
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Information "[OK] Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Information "[OK] Switched to subscription: $($subscription.Name)"
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

#endregion

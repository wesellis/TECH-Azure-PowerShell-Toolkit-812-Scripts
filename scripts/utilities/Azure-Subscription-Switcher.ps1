#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    $SubscriptionName,
    $SubscriptionId,
    [switch]$List,
    [switch]$Current
)
Write-Output "Azure Subscription Switcher"
Write-Output "==========================="
if ($Current) {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Output "Current Subscription:"
        Write-Output "Name: $($context.Subscription.Name)"
        Write-Output "ID: $($context.Subscription.Id)"
        Write-Output "Tenant: $($context.Tenant.Id)"
    } else {
        Write-Output "No active Azure context. Please run Connect-AzAccount first."
    }
    return
}
if ($List) {
    Write-Output "Available Subscriptions:"
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    foreach ($sub in $subscriptions) {
        $status = if ($sub.State -eq "Enabled") { "[OK]" } else { "[FAIL]" }
        Write-Output "  $status $($sub.Name) ($($sub.Id))"
    }
    return
}
if ($SubscriptionName) {
    try {
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Output "[OK] Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Output "[OK] Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionId': $($_.Exception.Message)"
    }
} else {
    Write-Output "Usage Examples:"
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -List"
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -Current"
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -SubscriptionName 'Production'"
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -SubscriptionId '12345678-1234-1234-1234-123456789012'"
}
Write-Output "`nSubscription switching completed at $(Get-Date)"




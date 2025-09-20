#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [string]$SubscriptionName,
    [string]$SubscriptionId,
    [switch]$List,
    [switch]$Current
)
Write-Host "Azure Subscription Switcher"
Write-Host "==========================="
# Show current subscription
if ($Current) {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Host "Current Subscription:"
        Write-Host "Name: $($context.Subscription.Name)"
        Write-Host "ID: $($context.Subscription.Id)"
        Write-Host "Tenant: $($context.Tenant.Id)"
    } else {
        Write-Host "No active Azure context. Please run Connect-AzAccount first."
    }
    return
}
# List available subscriptions
if ($List) {
    Write-Host "Available Subscriptions:"
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    foreach ($sub in $subscriptions) {
        $status = if ($sub.State -eq "Enabled") { "[OK]" } else { "[FAIL]" }
        Write-Host "  $status $($sub.Name) ($($sub.Id))"
    }
    return
}
# Switch to specified subscription
if ($SubscriptionName) {
    try {
        $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Host "[OK] Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Host "[OK] Switched to subscription: $($subscription.Name)"
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionId': $($_.Exception.Message)"
    }
} else {
    Write-Host "Usage Examples:"
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -List"
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -Current"
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -SubscriptionName 'Production'"
    Write-Host "  .\Azure-Subscription-Switcher.ps1 -SubscriptionId '12345678-1234-1234-1234-123456789012'"
}
Write-Host "`nSubscription switching completed at $(Get-Date)"


#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Subscription Switcher

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Log {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionId,
    [switch]$List,
    [switch]$Current
)
Write-Output "Azure Subscription Switcher" # Color: $2
Write-Output " ===========================" # Color: $2
if ($Current) {
    $context = Get-AzContext -ErrorAction Stop
    if ($context) {
        Write-Output "Current Subscription:" # Color: $2
        Write-Output "Name: $($context.Subscription.Name)" # Color: $2
        Write-Output "ID: $($context.Subscription.Id)" # Color: $2
        Write-Output "Tenant: $($context.Tenant.Id)" # Color: $2
    } else {
        Write-Output "No active Azure context. Please run Connect-AzAccount first." # Color: $2
    }
    return
}
if ($List) {
    Write-Output "Available Subscriptions:" # Color: $2
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    foreach ($sub in $subscriptions) {
    $status = if ($sub.State -eq "Enabled" ) { "[OK]" } else { " [FAIL]" }
        Write-Output "  $status $($sub.Name) ($($sub.Id))" # Color: $2
    }
    return
}
if ($SubscriptionName) {
    try {
    $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext -SubscriptionId $subscription.Id
        Write-Output "[OK] Switched to subscription: $($subscription.Name)" # Color: $2
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionName': $($_.Exception.Message)"
    }
} elseif ($SubscriptionId) {
    try {
        Set-AzContext -SubscriptionId $SubscriptionId
    $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Output "[OK] Switched to subscription: $($subscription.Name)" # Color: $2
    } catch {
        Write-Error "Failed to switch to subscription '$SubscriptionId': $($_.Exception.Message)"
    }
} else {
    Write-Output "Usage Examples:" # Color: $2
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -List" # Color: $2
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -Current" # Color: $2
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -SubscriptionName 'Production'" # Color: $2
    Write-Output "  .\Azure-Subscription-Switcher.ps1 -SubscriptionId '12345678-1234-1234-1234-123456789012'" # Color: $2
}
Write-Output " `nSubscription switching completed at $(Get-Date)" # Color: $2




#Requires -Version 7.4
#Requires -Modules Az.Accounts

<#
.SYNOPSIS
    Selects an Azure subscription

.DESCRIPTION
    This script lists available Azure subscriptions and allows selection of a specific
    subscription to be used as the current context for Azure operations.

.PARAMETER SubscriptionId
    The ID of the subscription to select

.EXAMPLE
    PS C:\> .\Select-AzSubscription.ps1 -SubscriptionId '3532a85c-c00a-4465-9b09-388248166360'
    Selects the specified Azure subscription

.EXAMPLE
    PS C:\> Get-AzSubscription | Select-AzSubscription
    Lists and interactively selects an Azure subscription

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

param(
    [Parameter(Mandatory = $false)]
    $SubscriptionId
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Get all available subscriptions
Write-Host "Available Azure subscriptions:" -ForegroundColor Green
Get-AzSubscription -ErrorAction Stop

# Select subscription if ID provided, otherwise prompt for selection
if ($SubscriptionId) {
    Select-AzSubscription -SubscriptionId $SubscriptionId
    Write-Host "Selected subscription: $SubscriptionId" -ForegroundColor Green
} else {
    Write-Host "Please run: Select-AzSubscription -SubscriptionId '<your-subscription-id>'" -ForegroundColor Yellow
}
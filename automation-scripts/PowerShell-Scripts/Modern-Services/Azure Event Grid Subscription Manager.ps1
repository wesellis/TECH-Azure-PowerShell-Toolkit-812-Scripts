#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Event Grid Subscription Manager

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateSet("CreateTopic", "CreateSubscription", "ListEvents", "DeleteTopic")]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TopicName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EndpointUrl,
    [Parameter()]
    [string]$Location = "East US"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    switch ($Action) {
        "CreateTopic" {
            $topic = New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $Location

            Write-Host "Endpoint: $($topic.Endpoint)" -ForegroundColor Green
        }
        "CreateSubscription" {
            $subscription = New-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName -EventSubscriptionName $SubscriptionName -Endpoint $EndpointUrl

        }
        "ListEvents" {
$topic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
$subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
            Write-Host "Topic: $($topic.Name)" -ForegroundColor Cyan
            Write-Host "Subscriptions: $($subscriptions.Count)" -ForegroundColor White
            $subscriptions | Format-Table EventSubscriptionName, Destination
        }
        "DeleteTopic" {
            Remove-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Force

        }
    }
} catch { throw }


<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Event Grid Subscription Manager
# Manage Event Grid topics and subscriptions
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateSet("CreateTopic", "CreateSubscription", "ListEvents", "DeleteTopic")]
    [string]$Action,
    [Parameter()]
    [string]$TopicName,
    [Parameter()]
    [string]$SubscriptionName,
    [Parameter()]
    [string]$EndpointUrl,
    [Parameter()]
    [string]$Location = "East US"
)
riptName "Azure Event Grid Subscription Manager" -Version "1.0" -Description "Manage Event Grid topics and subscriptions"
try {
    if (-not ((Get-AzContext) -RequiredModules @('Az.EventGrid'))) {
        throw "Azure connection validation failed"
    }
    switch ($Action) {
        "CreateTopic" {
            $topic = New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $Location
            
            Write-Host "Endpoint: $($topic.Endpoint)"
        }
        "CreateSubscription" {
            $subscription = New-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName -EventSubscriptionName $SubscriptionName -Endpoint $EndpointUrl
            
        }
        "ListEvents" {
            $topic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
            $subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
            Write-Host "Topic: $($topic.Name)"
            Write-Host "Subscriptions: $($subscriptions.Count)"
            $subscriptions | Format-Table EventSubscriptionName, Destination
        }
        "DeleteTopic" {
            Remove-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Force
            
        }
    }
} catch { throw }


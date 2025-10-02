#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateSet("CreateTopic", "CreateSubscription", "ListEvents", "DeleteTopic")]
    $Action,
    [Parameter()]
    $TopicName,
    [Parameter()]
    $SubscriptionName,
    [Parameter()]
    $EndpointUrl,
    [Parameter()]
    $Location = "East US"
)
riptName "Azure Event Grid Subscription Manager" -Version "1.0" -Description "Manage Event Grid topics and subscriptions"
try {
    if (-not ((Get-AzContext) -RequiredModules @('Az.EventGrid'))) {
        throw "Azure connection validation failed"
    }
    switch ($Action) {
        "CreateTopic" {
            $topic = New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $Location

            Write-Output "Endpoint: $($topic.Endpoint)"
        }
        "CreateSubscription" {
            $subscription = New-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName -EventSubscriptionName $SubscriptionName -Endpoint $EndpointUrl

        }
        "ListEvents" {
            $topic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
            $subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
            Write-Output "Topic: $($topic.Name)"
            Write-Output "Subscriptions: $($subscriptions.Count)"
            $subscriptions | Format-Table EventSubscriptionName, Destination
        }
        "DeleteTopic" {
            if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }

        }
    }
} catch { throw`n}

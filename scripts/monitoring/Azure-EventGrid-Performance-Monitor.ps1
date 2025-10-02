#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Event Grid

.DESCRIPTION
    Manage Event Grid
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$TopicName
)
Write-Output "Monitoring Event Grid Topic: $TopicName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$EventGridTopic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
Write-Output "Event Grid Topic Information:"
Write-Output "Name: $($EventGridTopic.TopicName)"
Write-Output "Location: $($EventGridTopic.Location)"
Write-Output "Provisioning State: $($EventGridTopic.ProvisioningState)"
Write-Output "Endpoint: $($EventGridTopic.Endpoint)"
Write-Output "Input Schema: $($EventGridTopic.InputSchema)"
try {
    $TopicKeys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Output "Access Keys: Available (Key1: $($TopicKeys.Key1.Substring(0,8))...)"
} catch {
    Write-Output "Access Keys: Unable to retrieve"
}
Write-Output "`nEvent Subscriptions:"
try {
    $Subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
    if ($Subscriptions.Count -eq 0) {
        Write-Output "No event subscriptions found"
    } else {
        foreach ($Subscription in $Subscriptions) {
            Write-Output "  - Subscription: $($Subscription.EventSubscriptionName)"
            Write-Output "    Provisioning State: $($Subscription.ProvisioningState)"
            Write-Output "    Endpoint Type: $($Subscription.EndpointType)"
            if ($Subscription.Destination) {
                switch ($Subscription.EndpointType) {
                    "webhook" {
                        $EndpointUrl = $Subscription.Destination.EndpointUrl
                        if ($EndpointUrl) {
                            $SafeUrl = $EndpointUrl.Substring(0, [Math]::Min(50, $EndpointUrl.Length))
                            Write-Output "    Endpoint: $SafeUrl..."
                        }
                    }
                    "eventhub" {
                        Write-Output "    Event Hub: $($Subscription.Destination.ResourceId.Split('/')[-1])"
                    }
                    "storagequeue" {
                        Write-Output "    Storage Queue: $($Subscription.Destination.QueueName)"
                    }
                    "servicebusqueue" {
                        Write-Output "    Service Bus Queue: $($Subscription.Destination.ResourceId.Split('/')[-1])"
                    }
                }
            }
            if ($Subscription.Filter) {
                if ($Subscription.Filter.IncludedEventTypes) {
                    Write-Output "    Event Types: $($Subscription.Filter.IncludedEventTypes -join ', ')"
                }
                if ($Subscription.Filter.SubjectBeginsWith) {
                    Write-Output "    Subject Filter (begins): $($Subscription.Filter.SubjectBeginsWith)"
                }
                if ($Subscription.Filter.SubjectEndsWith) {
                    Write-Output "    Subject Filter (ends): $($Subscription.Filter.SubjectEndsWith)"
                }
                if ($Subscription.Filter.IsSubjectCaseSensitive) {
                    Write-Output "    Case Sensitive: $($Subscription.Filter.IsSubjectCaseSensitive)"
                }
            }
            if ($Subscription.RetryPolicy) {
                Write-Output "    Max Delivery Attempts: $($Subscription.RetryPolicy.MaxDeliveryAttempts)"
                Write-Output "    Event TTL: $($Subscription.RetryPolicy.EventTimeToLiveInMinutes) minutes"
            }
            if ($Subscription.DeadLetterDestination) {
                Write-Output "    Dead Letter: Configured"
            }
            Write-Output "    ---"
        }
    }
} catch {
    Write-Output "Unable to retrieve event subscriptions: $($_.Exception.Message)"
}
Write-Output "`nEvent Grid Configuration:"
Write-Output "Input Schema: $($EventGridTopic.InputSchema)"
Write-Output "Public Network Access: Enabled"
Write-Output "`nSample Event Format ($($EventGridTopic.InputSchema)):"
if ($EventGridTopic.InputSchema -eq "EventGridSchema") {
    Write-Information @"
  {
    "id": "unique-event-id",
    "eventType": "Custom.Event.Type",
    "subject": "/myapp/resource/action",
    "eventTime": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")",
    "data": {
      "property1": "value1",
      "property2": "value2"
    },
    "dataVersion": "1.0"
  }
"@
} elseif ($EventGridTopic.InputSchema -eq "CloudEventSchemaV1_0") {
    Write-Information @"
  {
    "specversion": "1.0",
    "type": "Custom.Event.Type",
    "source": "/myapp/resource",
    "id": "unique-event-id",
    "time": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")",
    "data": {
      "property1": "value1",
      "property2": "value2"
    }
  }
"@
}
Write-Output "`nPublishing Events:"
Write-Output "POST $($EventGridTopic.Endpoint)"
Write-Output "Headers:"
Write-Output "    aeg-sas-key: [access-key]"
Write-Output "    Content-Type: application/json"
Write-Output "`nMonitoring Recommendations:"
Write-Output "1. Monitor event delivery success rates"
Write-Output "2. Set up alerts for failed deliveries"
Write-Output "3. Review dead letter queues regularly"
Write-Output "4. Monitor event throughput and latency"
Write-Output "5. Validate event schema compliance"
Write-Output "`nEvent Grid Portal Access:"
Write-Output "URL: https://portal.azure.com/#@/resource$($EventGridTopic.Id)"
Write-Output "`nEvent Grid Topic monitoring completed at $(Get-Date)"




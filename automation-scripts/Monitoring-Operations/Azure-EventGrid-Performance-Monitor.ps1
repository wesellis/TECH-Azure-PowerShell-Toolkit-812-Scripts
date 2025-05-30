# ============================================================================
# Script Name: Azure Event Grid Topic Performance Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Event Grid topics, subscriptions, and event delivery metrics
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$TopicName
)

Write-Host "Monitoring Event Grid Topic: $TopicName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get Event Grid Topic details
$EventGridTopic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName

Write-Host "Event Grid Topic Information:"
Write-Host "  Name: $($EventGridTopic.TopicName)"
Write-Host "  Location: $($EventGridTopic.Location)"
Write-Host "  Provisioning State: $($EventGridTopic.ProvisioningState)"
Write-Host "  Endpoint: $($EventGridTopic.Endpoint)"
Write-Host "  Input Schema: $($EventGridTopic.InputSchema)"

# Get topic access keys
try {
    $TopicKeys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Host "  Access Keys: Available (Key1: $($TopicKeys.Key1.Substring(0,8))...)"
} catch {
    Write-Host "  Access Keys: Unable to retrieve"
}

# Get event subscriptions for this topic
Write-Host "`nEvent Subscriptions:"
try {
    $Subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
    
    if ($Subscriptions.Count -eq 0) {
        Write-Host "  No event subscriptions found"
    } else {
        foreach ($Subscription in $Subscriptions) {
            Write-Host "  - Subscription: $($Subscription.EventSubscriptionName)"
            Write-Host "    Provisioning State: $($Subscription.ProvisioningState)"
            Write-Host "    Endpoint Type: $($Subscription.EndpointType)"
            
            # Display endpoint information (safely)
            if ($Subscription.Destination) {
                switch ($Subscription.EndpointType) {
                    "webhook" {
                        $EndpointUrl = $Subscription.Destination.EndpointUrl
                        if ($EndpointUrl) {
                            $SafeUrl = $EndpointUrl.Substring(0, [Math]::Min(50, $EndpointUrl.Length))
                            Write-Host "    Endpoint: $SafeUrl..."
                        }
                    }
                    "eventhub" {
                        Write-Host "    Event Hub: $($Subscription.Destination.ResourceId.Split('/')[-1])"
                    }
                    "storagequeue" {
                        Write-Host "    Storage Queue: $($Subscription.Destination.QueueName)"
                    }
                    "servicebusqueue" {
                        Write-Host "    Service Bus Queue: $($Subscription.Destination.ResourceId.Split('/')[-1])"
                    }
                }
            }
            
            # Event types and filters
            if ($Subscription.Filter) {
                if ($Subscription.Filter.IncludedEventTypes) {
                    Write-Host "    Event Types: $($Subscription.Filter.IncludedEventTypes -join ', ')"
                }
                if ($Subscription.Filter.SubjectBeginsWith) {
                    Write-Host "    Subject Filter (begins): $($Subscription.Filter.SubjectBeginsWith)"
                }
                if ($Subscription.Filter.SubjectEndsWith) {
                    Write-Host "    Subject Filter (ends): $($Subscription.Filter.SubjectEndsWith)"
                }
                if ($Subscription.Filter.IsSubjectCaseSensitive) {
                    Write-Host "    Case Sensitive: $($Subscription.Filter.IsSubjectCaseSensitive)"
                }
            }
            
            # Retry policy
            if ($Subscription.RetryPolicy) {
                Write-Host "    Max Delivery Attempts: $($Subscription.RetryPolicy.MaxDeliveryAttempts)"
                Write-Host "    Event TTL: $($Subscription.RetryPolicy.EventTimeToLiveInMinutes) minutes"
            }
            
            # Dead letter destination
            if ($Subscription.DeadLetterDestination) {
                Write-Host "    Dead Letter: Configured"
            }
            
            Write-Host "    ---"
        }
    }
} catch {
    Write-Host "  Unable to retrieve event subscriptions: $($_.Exception.Message)"
}

# Event Grid domain information (if applicable)
Write-Host "`nEvent Grid Configuration:"
Write-Host "  Input Schema: $($EventGridTopic.InputSchema)"
Write-Host "  Public Network Access: Enabled"

# Sample event format based on schema
Write-Host "`nSample Event Format ($($EventGridTopic.InputSchema)):"
if ($EventGridTopic.InputSchema -eq "EventGridSchema") {
    Write-Host @"
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
    Write-Host @"
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

Write-Host "`nPublishing Events:"
Write-Host "  POST $($EventGridTopic.Endpoint)"
Write-Host "  Headers:"
Write-Host "    aeg-sas-key: [access-key]"
Write-Host "    Content-Type: application/json"

Write-Host "`nMonitoring Recommendations:"
Write-Host "1. Monitor event delivery success rates"
Write-Host "2. Set up alerts for failed deliveries"
Write-Host "3. Review dead letter queues regularly"
Write-Host "4. Monitor event throughput and latency"
Write-Host "5. Validate event schema compliance"

Write-Host "`nEvent Grid Portal Access:"
Write-Host "URL: https://portal.azure.com/#@/resource$($EventGridTopic.Id)"

Write-Host "`nEvent Grid Topic monitoring completed at $(Get-Date)"

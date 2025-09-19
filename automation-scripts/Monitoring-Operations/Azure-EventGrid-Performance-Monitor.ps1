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
    [string]$ResourceGroupName,
    [string]$TopicName
)

#region Functions

Write-Information "Monitoring Event Grid Topic: $TopicName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get Event Grid Topic details
$EventGridTopic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName

Write-Information "Event Grid Topic Information:"
Write-Information "  Name: $($EventGridTopic.TopicName)"
Write-Information "  Location: $($EventGridTopic.Location)"
Write-Information "  Provisioning State: $($EventGridTopic.ProvisioningState)"
Write-Information "  Endpoint: $($EventGridTopic.Endpoint)"
Write-Information "  Input Schema: $($EventGridTopic.InputSchema)"

# Get topic access keys
try {
    $TopicKeys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Information "  Access Keys: Available (Key1: $($TopicKeys.Key1.Substring(0,8))...)"
} catch {
    Write-Information "  Access Keys: Unable to retrieve"
}

# Get event subscriptions for this topic
Write-Information "`nEvent Subscriptions:"
try {
    $Subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
    
    if ($Subscriptions.Count -eq 0) {
        Write-Information "  No event subscriptions found"
    } else {
        foreach ($Subscription in $Subscriptions) {
            Write-Information "  - Subscription: $($Subscription.EventSubscriptionName)"
            Write-Information "    Provisioning State: $($Subscription.ProvisioningState)"
            Write-Information "    Endpoint Type: $($Subscription.EndpointType)"
            
            # Display endpoint information (safely)
            if ($Subscription.Destination) {
                switch ($Subscription.EndpointType) {
                    "webhook" {
                        $EndpointUrl = $Subscription.Destination.EndpointUrl
                        if ($EndpointUrl) {
                            $SafeUrl = $EndpointUrl.Substring(0, [Math]::Min(50, $EndpointUrl.Length))
                            Write-Information "    Endpoint: $SafeUrl..."
                        }
                    }
                    "eventhub" {
                        Write-Information "    Event Hub: $($Subscription.Destination.ResourceId.Split('/')[-1])"
                    }
                    "storagequeue" {
                        Write-Information "    Storage Queue: $($Subscription.Destination.QueueName)"
                    }
                    "servicebusqueue" {
                        Write-Information "    Service Bus Queue: $($Subscription.Destination.ResourceId.Split('/')[-1])"
                    }
                }
            }
            
            # Event types and filters
            if ($Subscription.Filter) {
                if ($Subscription.Filter.IncludedEventTypes) {
                    Write-Information "    Event Types: $($Subscription.Filter.IncludedEventTypes -join ', ')"
                }
                if ($Subscription.Filter.SubjectBeginsWith) {
                    Write-Information "    Subject Filter (begins): $($Subscription.Filter.SubjectBeginsWith)"
                }
                if ($Subscription.Filter.SubjectEndsWith) {
                    Write-Information "    Subject Filter (ends): $($Subscription.Filter.SubjectEndsWith)"
                }
                if ($Subscription.Filter.IsSubjectCaseSensitive) {
                    Write-Information "    Case Sensitive: $($Subscription.Filter.IsSubjectCaseSensitive)"
                }
            }
            
            # Retry policy
            if ($Subscription.RetryPolicy) {
                Write-Information "    Max Delivery Attempts: $($Subscription.RetryPolicy.MaxDeliveryAttempts)"
                Write-Information "    Event TTL: $($Subscription.RetryPolicy.EventTimeToLiveInMinutes) minutes"
            }
            
            # Dead letter destination
            if ($Subscription.DeadLetterDestination) {
                Write-Information "    Dead Letter: Configured"
            }
            
            Write-Information "    ---"
        }
    }
} catch {
    Write-Information "  Unable to retrieve event subscriptions: $($_.Exception.Message)"
}

# Event Grid domain information (if applicable)
Write-Information "`nEvent Grid Configuration:"
Write-Information "  Input Schema: $($EventGridTopic.InputSchema)"
Write-Information "  Public Network Access: Enabled"

# Sample event format based on schema
Write-Information "`nSample Event Format ($($EventGridTopic.InputSchema)):"
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

Write-Information "`nPublishing Events:"
Write-Information "  POST $($EventGridTopic.Endpoint)"
Write-Information "  Headers:"
Write-Information "    aeg-sas-key: [access-key]"
Write-Information "    Content-Type: application/json"

Write-Information "`nMonitoring Recommendations:"
Write-Information "1. Monitor event delivery success rates"
Write-Information "2. Set up alerts for failed deliveries"
Write-Information "3. Review dead letter queues regularly"
Write-Information "4. Monitor event throughput and latency"
Write-Information "5. Validate event schema compliance"

Write-Information "`nEvent Grid Portal Access:"
Write-Information "URL: https://portal.azure.com/#@/resource$($EventGridTopic.Id)"

Write-Information "`nEvent Grid Topic monitoring completed at $(Get-Date)"


#endregion

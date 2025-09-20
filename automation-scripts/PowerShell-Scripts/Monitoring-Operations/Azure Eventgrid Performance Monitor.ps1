<#
.SYNOPSIS
    Azure Eventgrid Performance Monitor

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$TopicName
)
Write-Host "Monitoring Event Grid Topic: $TopicName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host " ============================================" "INFO"
$EventGridTopic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
Write-Host "Event Grid Topic Information:" "INFO"
Write-Host "Name: $($EventGridTopic.TopicName)" "INFO"
Write-Host "Location: $($EventGridTopic.Location)" "INFO"
Write-Host "Provisioning State: $($EventGridTopic.ProvisioningState)" "INFO"
Write-Host "Endpoint: $($EventGridTopic.Endpoint)" "INFO"
Write-Host "Input Schema: $($EventGridTopic.InputSchema)" "INFO"
try {
    $TopicKeys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Host "Access Keys: Available (Key1: $($TopicKeys.Key1.Substring(0,8))...)" "INFO"
} catch {
    Write-Host "Access Keys: Unable to retrieve" "INFO"
}
Write-Host " `nEvent Subscriptions:" "INFO"
try {
    $Subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
    if ($Subscriptions.Count -eq 0) {
        Write-Host "No event subscriptions found" "INFO"
    } else {
        foreach ($Subscription in $Subscriptions) {
            Write-Host "  - Subscription: $($Subscription.EventSubscriptionName)" "INFO"
            Write-Host "    Provisioning State: $($Subscription.ProvisioningState)" "INFO"
            Write-Host "    Endpoint Type: $($Subscription.EndpointType)" "INFO"
            # Display endpoint information (safely)
            if ($Subscription.Destination) {
                switch ($Subscription.EndpointType) {
                    " webhook" {
$EndpointUrl = $Subscription.Destination.EndpointUrl
                        if ($EndpointUrl) {
$SafeUrl = $EndpointUrl.Substring(0, [Math]::Min(50, $EndpointUrl.Length))
                            Write-Host "    Endpoint: $SafeUrl..." "INFO"
                        }
                    }
                    " eventhub" {
                        Write-Host "    Event Hub: $($Subscription.Destination.ResourceId.Split('/')[-1])" "INFO"
                    }
                    " storagequeue" {
                        Write-Host "    Storage Queue: $($Subscription.Destination.QueueName)" "INFO"
                    }
                    " servicebusqueue" {
                        Write-Host "    Service Bus Queue: $($Subscription.Destination.ResourceId.Split('/')[-1])" "INFO"
                    }
                }
            }
            # Event types and filters
            if ($Subscription.Filter) {
                if ($Subscription.Filter.IncludedEventTypes) {
                    Write-Host "    Event Types: $($Subscription.Filter.IncludedEventTypes -join ', ')" "INFO"
                }
                if ($Subscription.Filter.SubjectBeginsWith) {
                    Write-Host "    Subject Filter (begins): $($Subscription.Filter.SubjectBeginsWith)" "INFO"
                }
                if ($Subscription.Filter.SubjectEndsWith) {
                    Write-Host "    Subject Filter (ends): $($Subscription.Filter.SubjectEndsWith)" "INFO"
                }
                if ($Subscription.Filter.IsSubjectCaseSensitive) {
                    Write-Host "    Case Sensitive: $($Subscription.Filter.IsSubjectCaseSensitive)" "INFO"
                }
            }
            # Retry policy
            if ($Subscription.RetryPolicy) {
                Write-Host "    Max Delivery Attempts: $($Subscription.RetryPolicy.MaxDeliveryAttempts)" "INFO"
                Write-Host "    Event TTL: $($Subscription.RetryPolicy.EventTimeToLiveInMinutes) minutes" "INFO"
            }
            # Dead letter destination
            if ($Subscription.DeadLetterDestination) {
                Write-Host "    Dead Letter: Configured" "INFO"
            }
            Write-Host "    ---" "INFO"
        }
    }
} catch {
    Write-Host "Unable to retrieve event subscriptions: $($_.Exception.Message)" "INFO"
}
Write-Host " `nEvent Grid Configuration:" "INFO"
Write-Host "Input Schema: $($EventGridTopic.InputSchema)" "INFO"
Write-Host "Public Network Access: Enabled" "INFO"
Write-Host " `nSample Event Format ($($EventGridTopic.InputSchema)):" "INFO"
if ($EventGridTopic.InputSchema -eq "EventGridSchema" ) {
    Write-Information @"
  {
    " id" : " unique-event-id" ,
    " eventType" : "Custom.Event.Type" ,
    " subject" : " /myapp/resource/action" ,
    " eventTime" : " $(Get-Date -Format " yyyy-MM-ddTHH:mm:ssZ" )" ,
    " data" : {
      " property1" : " value1" ,
      " property2" : " value2"
    },
    " dataVersion" : " 1.0"
  }
" @
} elseif ($EventGridTopic.InputSchema -eq "CloudEventSchemaV1_0" ) {
    Write-Information @"
  {
    " specversion" : " 1.0" ,
    " type" : "Custom.Event.Type" ,
    " source" : " /myapp/resource" ,
    " id" : " unique-event-id" ,
    " time" : " $(Get-Date -Format " yyyy-MM-ddTHH:mm:ssZ" )" ,
    " data" : {
      " property1" : " value1" ,
      " property2" : " value2"
    }
  }
" @
}
Write-Host " `nPublishing Events:" "INFO"
Write-Host "POST $($EventGridTopic.Endpoint)" "INFO"
Write-Host "Headers:" "INFO"
Write-Host "    aeg-sas-key: [access-key]" "INFO"
Write-Host "    Content-Type: application/json" "INFO"
Write-Host " `nMonitoring Recommendations:" "INFO"
Write-Host " 1. Monitor event delivery success rates" "INFO"
Write-Host " 2. Set up alerts for failed deliveries" "INFO"
Write-Host " 3. Review dead letter queues regularly" "INFO"
Write-Host " 4. Monitor event throughput and latency" "INFO"
Write-Host " 5. Validate event schema compliance" "INFO"
Write-Host " `nEvent Grid Portal Access:" "INFO"
Write-Host "URL: https://portal.azure.com/#@/resource$($EventGridTopic.Id)" "INFO"
Write-Host " `nEvent Grid Topic monitoring completed at $(Get-Date)" "INFO"


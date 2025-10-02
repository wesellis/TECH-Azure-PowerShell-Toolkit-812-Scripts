#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Eventgrid Performance Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$TopicName
)
Write-Output "Monitoring Event Grid Topic: $TopicName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output " ============================================" "INFO"
    [string]$EventGridTopic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
Write-Output "Event Grid Topic Information:" "INFO"
Write-Output "Name: $($EventGridTopic.TopicName)" "INFO"
Write-Output "Location: $($EventGridTopic.Location)" "INFO"
Write-Output "Provisioning State: $($EventGridTopic.ProvisioningState)" "INFO"
Write-Output "Endpoint: $($EventGridTopic.Endpoint)" "INFO"
Write-Output "Input Schema: $($EventGridTopic.InputSchema)" "INFO"
try {
    [string]$TopicKeys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Output "Access Keys: Available (Key1: $($TopicKeys.Key1.Substring(0,8))...)" "INFO"
} catch {
    Write-Output "Access Keys: Unable to retrieve" "INFO"
}
Write-Output " `nEvent Subscriptions:" "INFO"
try {
    [string]$Subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
    if ($Subscriptions.Count -eq 0) {
        Write-Output "No event subscriptions found" "INFO"
    } else {
        foreach ($Subscription in $Subscriptions) {
            Write-Output "  - Subscription: $($Subscription.EventSubscriptionName)" "INFO"
            Write-Output "    Provisioning State: $($Subscription.ProvisioningState)" "INFO"
            Write-Output "    Endpoint Type: $($Subscription.EndpointType)" "INFO"
            if ($Subscription.Destination) {
                switch ($Subscription.EndpointType) {
                    " webhook" {
    [string]$EndpointUrl = $Subscription.Destination.EndpointUrl
                        if ($EndpointUrl) {
    [string]$SafeUrl = $EndpointUrl.Substring(0, [Math]::Min(50, $EndpointUrl.Length))
                            Write-Output "    Endpoint: $SafeUrl..." "INFO"
                        }
                    }
                    " eventhub" {
                        Write-Output "    Event Hub: $($Subscription.Destination.ResourceId.Split('/')[-1])" "INFO"
                    }
                    " storagequeue" {
                        Write-Output "    Storage Queue: $($Subscription.Destination.QueueName)" "INFO"
                    }
                    " servicebusqueue" {
                        Write-Output "    Service Bus Queue: $($Subscription.Destination.ResourceId.Split('/')[-1])" "INFO"
                    }
                }
            }
            if ($Subscription.Filter) {
                if ($Subscription.Filter.IncludedEventTypes) {
                    Write-Output "    Event Types: $($Subscription.Filter.IncludedEventTypes -join ', ')" "INFO"
                }
                if ($Subscription.Filter.SubjectBeginsWith) {
                    Write-Output "    Subject Filter (begins): $($Subscription.Filter.SubjectBeginsWith)" "INFO"
                }
                if ($Subscription.Filter.SubjectEndsWith) {
                    Write-Output "    Subject Filter (ends): $($Subscription.Filter.SubjectEndsWith)" "INFO"
                }
                if ($Subscription.Filter.IsSubjectCaseSensitive) {
                    Write-Output "    Case Sensitive: $($Subscription.Filter.IsSubjectCaseSensitive)" "INFO"
                }
            }
            if ($Subscription.RetryPolicy) {
                Write-Output "    Max Delivery Attempts: $($Subscription.RetryPolicy.MaxDeliveryAttempts)" "INFO"
                Write-Output "    Event TTL: $($Subscription.RetryPolicy.EventTimeToLiveInMinutes) minutes" "INFO"
            }
            if ($Subscription.DeadLetterDestination) {
                Write-Output "    Dead Letter: Configured" "INFO"
            }
            Write-Output "    ---" "INFO"
        }
    }
} catch {
    Write-Output "Unable to retrieve event subscriptions: $($_.Exception.Message)" "INFO"
}
Write-Output " `nEvent Grid Configuration:" "INFO"
Write-Output "Input Schema: $($EventGridTopic.InputSchema)" "INFO"
Write-Output "Public Network Access: Enabled" "INFO"
Write-Output " `nSample Event Format ($($EventGridTopic.InputSchema)):" "INFO"
if ($EventGridTopic.InputSchema -eq "EventGridSchema" ) {
    Write-Information @"
  {
    " id" : " unique-event-id" ,
    " eventType" : "Custom.Event.Type" ,
    " subject" : "/myapp/resource/action" ,
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
    " source" : "/myapp/resource" ,
    " id" : " unique-event-id" ,
    " time" : " $(Get-Date -Format " yyyy-MM-ddTHH:mm:ssZ" )" ,
    " data" : {
      " property1" : " value1" ,
      " property2" : " value2"
    }
  }
" @
}
Write-Output " `nPublishing Events:" "INFO"
Write-Output "POST $($EventGridTopic.Endpoint)" "INFO"
Write-Output "Headers:" "INFO"
Write-Output "    aeg-sas-key: [access-key]" "INFO"
Write-Output "    Content-Type: application/json" "INFO"
Write-Output " `nMonitoring Recommendations:" "INFO"
Write-Output " 1. Monitor event delivery success rates" "INFO"
Write-Output " 2. Set up alerts for failed deliveries" "INFO"
Write-Output " 3. Review dead letter queues regularly" "INFO"
Write-Output " 4. Monitor event throughput and latency" "INFO"
Write-Output " 5. Validate event schema compliance" "INFO"
Write-Output " `nEvent Grid Portal Access:" "INFO"
Write-Output "URL: https://portal.azure.com/#@/resource$($EventGridTopic.Id)" "INFO"
Write-Output " `nEvent Grid Topic monitoring completed at $(Get-Date)" "INFO"




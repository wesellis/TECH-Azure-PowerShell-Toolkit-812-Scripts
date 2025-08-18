<#
.SYNOPSIS
    Azure Eventgrid Performance Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Eventgrid Performance Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WETopicName
)

Write-WELog " Monitoring Event Grid Topic: $WETopicName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEEventGridTopic = Get-AzEventGridTopic -ResourceGroupName $WEResourceGroupName -Name $WETopicName

Write-WELog " Event Grid Topic Information:" " INFO"
Write-WELog "  Name: $($WEEventGridTopic.TopicName)" " INFO"
Write-WELog "  Location: $($WEEventGridTopic.Location)" " INFO"
Write-WELog "  Provisioning State: $($WEEventGridTopic.ProvisioningState)" " INFO"
Write-WELog "  Endpoint: $($WEEventGridTopic.Endpoint)" " INFO"
Write-WELog "  Input Schema: $($WEEventGridTopic.InputSchema)" " INFO"


try {
    $WETopicKeys = Get-AzEventGridTopicKey -ResourceGroupName $WEResourceGroupName -Name $WETopicName
    Write-WELog "  Access Keys: Available (Key1: $($WETopicKeys.Key1.Substring(0,8))...)" " INFO"
} catch {
    Write-WELog "  Access Keys: Unable to retrieve" " INFO"
}


Write-WELog " `nEvent Subscriptions:" " INFO"
try {
    $WESubscriptions = Get-AzEventGridSubscription -ResourceGroupName $WEResourceGroupName -TopicName $WETopicName
    
    if ($WESubscriptions.Count -eq 0) {
        Write-WELog "  No event subscriptions found" " INFO"
    } else {
        foreach ($WESubscription in $WESubscriptions) {
            Write-WELog "  - Subscription: $($WESubscription.EventSubscriptionName)" " INFO"
            Write-WELog "    Provisioning State: $($WESubscription.ProvisioningState)" " INFO"
            Write-WELog "    Endpoint Type: $($WESubscription.EndpointType)" " INFO"
            
            # Display endpoint information (safely)
            if ($WESubscription.Destination) {
                switch ($WESubscription.EndpointType) {
                    " webhook" {
                       ;  $WEEndpointUrl = $WESubscription.Destination.EndpointUrl
                        if ($WEEndpointUrl) {
                           ;  $WESafeUrl = $WEEndpointUrl.Substring(0, [Math]::Min(50, $WEEndpointUrl.Length))
                            Write-WELog "    Endpoint: $WESafeUrl..." " INFO"
                        }
                    }
                    " eventhub" {
                        Write-WELog "    Event Hub: $($WESubscription.Destination.ResourceId.Split('/')[-1])" " INFO"
                    }
                    " storagequeue" {
                        Write-WELog "    Storage Queue: $($WESubscription.Destination.QueueName)" " INFO"
                    }
                    " servicebusqueue" {
                        Write-WELog "    Service Bus Queue: $($WESubscription.Destination.ResourceId.Split('/')[-1])" " INFO"
                    }
                }
            }
            
            # Event types and filters
            if ($WESubscription.Filter) {
                if ($WESubscription.Filter.IncludedEventTypes) {
                    Write-WELog "    Event Types: $($WESubscription.Filter.IncludedEventTypes -join ', ')" " INFO"
                }
                if ($WESubscription.Filter.SubjectBeginsWith) {
                    Write-WELog "    Subject Filter (begins): $($WESubscription.Filter.SubjectBeginsWith)" " INFO"
                }
                if ($WESubscription.Filter.SubjectEndsWith) {
                    Write-WELog "    Subject Filter (ends): $($WESubscription.Filter.SubjectEndsWith)" " INFO"
                }
                if ($WESubscription.Filter.IsSubjectCaseSensitive) {
                    Write-WELog "    Case Sensitive: $($WESubscription.Filter.IsSubjectCaseSensitive)" " INFO"
                }
            }
            
            # Retry policy
            if ($WESubscription.RetryPolicy) {
                Write-WELog "    Max Delivery Attempts: $($WESubscription.RetryPolicy.MaxDeliveryAttempts)" " INFO"
                Write-WELog "    Event TTL: $($WESubscription.RetryPolicy.EventTimeToLiveInMinutes) minutes" " INFO"
            }
            
            # Dead letter destination
            if ($WESubscription.DeadLetterDestination) {
                Write-WELog "    Dead Letter: Configured" " INFO"
            }
            
            Write-WELog "    ---" " INFO"
        }
    }
} catch {
    Write-WELog "  Unable to retrieve event subscriptions: $($_.Exception.Message)" " INFO"
}


Write-WELog " `nEvent Grid Configuration:" " INFO"
Write-WELog "  Input Schema: $($WEEventGridTopic.InputSchema)" " INFO"
Write-WELog "  Public Network Access: Enabled" " INFO"


Write-WELog " `nSample Event Format ($($WEEventGridTopic.InputSchema)):" " INFO"
if ($WEEventGridTopic.InputSchema -eq " EventGridSchema" ) {
    Write-Host @"
  {
    " id" : " unique-event-id" ,
    " eventType" : " Custom.Event.Type" ,
    " subject" : " /myapp/resource/action" ,
    " eventTime" : " $(Get-Date -Format " yyyy-MM-ddTHH:mm:ssZ" )" ,
    " data" : {
      " property1" : " value1" ,
      " property2" : " value2"
    },
    " dataVersion" : " 1.0"
  }
" @
} elseif ($WEEventGridTopic.InputSchema -eq " CloudEventSchemaV1_0" ) {
    Write-Host @"
  {
    " specversion" : " 1.0" ,
    " type" : " Custom.Event.Type" ,
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

Write-WELog " `nPublishing Events:" " INFO"
Write-WELog "  POST $($WEEventGridTopic.Endpoint)" " INFO"
Write-WELog "  Headers:" " INFO"
Write-WELog "    aeg-sas-key: [access-key]" " INFO"
Write-WELog "    Content-Type: application/json" " INFO"

Write-WELog " `nMonitoring Recommendations:" " INFO"
Write-WELog " 1. Monitor event delivery success rates" " INFO"
Write-WELog " 2. Set up alerts for failed deliveries" " INFO"
Write-WELog " 3. Review dead letter queues regularly" " INFO"
Write-WELog " 4. Monitor event throughput and latency" " INFO"
Write-WELog " 5. Validate event schema compliance" " INFO"

Write-WELog " `nEvent Grid Portal Access:" " INFO"
Write-WELog " URL: https://portal.azure.com/#@/resource$($WEEventGridTopic.Id)" " INFO"

Write-WELog " `nEvent Grid Topic monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
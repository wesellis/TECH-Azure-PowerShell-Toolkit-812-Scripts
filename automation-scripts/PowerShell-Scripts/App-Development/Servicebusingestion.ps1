<#
.SYNOPSIS
    Servicebusingestion

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
    We Enhanced Servicebusingestion

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


$WEConnectionAssetName = " AzureClassicRunAsConnection"


$connection = Get-AutomationConnection -Name $connectionAssetName        


Write-Verbose " Get connection asset: $WEConnectionAssetName" -Verbose
$WEConn = Get-AutomationConnection -Name $WEConnectionAssetName
if ($WEConn -eq $null)
    {
        throw " Could not retrieve connection asset: $WEConnectionAssetName. Assure that this asset exists in the Automation account."
    }

$WECertificateAssetName = $WEConn.CertificateAssetName
Write-Verbose " Getting the certificate: $WECertificateAssetName" -Verbose

$WEAzureCert = Get-AutomationCertificate -Name $WECertificateAssetName
if ($WEAzureCert -eq $null)
    {
        throw " Could not retrieve certificate asset: $WECertificateAssetName. Assure that this asset exists in the Automation account."
    }

Write-Verbose " Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionName $WEConn.SubscriptionName -SubscriptionId $WEConn.SubscriptionID -Certificate $WEAzureCert 
Select-AzureSubscription -SubscriptionId $WEConn.SubscriptionID



$WEStartTime = [dateTime]::Now


$WETimestampfield = " Timestamp" 


$customerID = Get-AutomationVariable -Name 'OMSWorkspaceId'


$sharedKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'

$logType  = " servicebus"



" Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 
 Add-AzureRMAccount -ServicePrincipal -Tenant $WEConn.TenantID `
 -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint

" Selecting Azure subscription..."
$WESelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 



 Function CalculateFreeSpacePercentage{
 [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
[Parameter(Mandatory=$true)]
[int]$WEMaxSizeMB,
[Parameter(Mandatory=$true)]
[int]$WECurrentSizeMB
)

$percentage = (($WEMaxSizeMB - $WECurrentSizeMB)/$WEMaxSizeMB)*100 #calculate percentage

Return ($percentage)
}

Function Get-SbNameSpace
{
    $sbNamespace = Get-AzureRmServiceBusNamespace
    if($sbNamespace -ne $null)
        {
            #" Found $($sbNamespace.Count) service bus namespace(s)."
        }
    else
    {
        throw " No Service Bus name spaces were found!"
        break
    }
return $sbNamespace
}

Function Publish-SbQueueMetrics
{
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param([parameter(mandatory=$true)]
    [object]$sbNamespace)

    $queueTable = @()
	$jsonQueueTable = @()
    $sx = @()

    " ----------------- Start Queue section -----------------"
    " Found $($sbNamespace.Count) service bus namespace(s)."
    " Processing Queues.... `n"
    foreach($sb in $sbNamespace)
        {
        $WESBqueue = $null

        " Going through service bus instance `" $($sb.Name)`" ..."

        #Get Resource Group Name for the service bus instance
        $sbResourceGroup = (Find-AzureRmResource -ResourceNameEquals $sb.Name).ResourceGroupName
                
        " *** Attempting to get queues.... ***"
        try
        {
            $WESBqueue = Get-AzureRmServiceBusQueue -ResourceGroup $sbResourceGroup -NamespaceName $sb.name
            " *** Number of queues found: $($WESBqueue.name.count) *** `n"
        }
        catch
        {Write-Output (" Error in getting queue information for namespace:  " + $sb.name + " `n" )}
        
        if($WESBqueue -ne $null) #We have Queues, so we can continue
        {
            #clear table
            $queueTable = @()
            
            foreach($queue in $WESBqueue)
            {

                    
                    #check if the queue message size (SizeInBytes) exceeds the threshold of MaxSizeInMegabytes
                    if(($queue.SizeInBytes/1MB) -gt $WEQueue.MaxSizeInMegabytes)
                    {
                        $queueThresholdAlert = 1 #Queue exceeds Queue threshold, so raise alert
                    }
                    
                    else
                    {
                        $queueThresholdAlert = 0 #Queue size is below threshold
                    }

                    if($queue.SizeInBytes -ne 0)
                    {
                    #(" QueueSizeInBytes is: " + $queue.SizeInBytes)
                    $queueSizeInMB = $null
                    $queueSizeInMB = ($queue.SizeInBytes/1MB)
                    $queueFreeSpacePercentage = $null
                    $queueFreeSpacePercentage = CalculateFreeSpacePercentage -MaxSizeMB $queue.MaxSizeInMegabytes -CurrentSizeMB $queueSizeInMB
                    
                    #uncomment the next lines for troubleshooting
                    #" Actual Queue Freespace Percentage: $queueFreeSpacePercentage"
                    $queueFreeSpacePercentage = " {0:N2}" -f $queueFreeSpacePercentage
                    #" Recalculation: $queueFreeSpacePercentage"
                    }
                    
                    else
                    {
                        " QueueSizeInBytes is 0, so we are setting the percentage to 100"
                       ;  $queueFreeSpacePercentage = 100
                    }
                    

			       ;  $sx = New-Object PSObject -Property @{
                        TimeStamp = $([DateTime]::Now.ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" ));
			            #SubscriptionName = $subscriptionName;
                        ServiceBusName = $sb.Name;
                        QueueName = $queue.Name;
                        QueueLocation = $queue.Location;
                        MaxSizeInMegabytes = $queue.MaxSizeInMegabytes;
			            RequiresDuplicateDetection = $queue.RequiresDuplicateDetection;
			            RequiresSession = $queue.RequiresSession;
			            DefaultMessageTimeToLive = $queue.DefaultMessageTimeToLive;
			            AutoDeleteOnIdle = $queue.AutoDeleteOnIdle;
			            DeadLetteringOnMessageExpiration = $queue.DeadLetteringOnMessageExpiration;
			            DuplicateDetectionHistoryTimeWindow = $queue.DuplicateDetectionHistoryTimeWindow;
			            MaxDeliveryCount = $queue.MaxDeliveryCount;
			            EnableBatchedOperations = $queue.EnableBatchedOperations;
			            SizeInBytes = $queue.SizeInBytes;
                        MessageCount = $queue.MessageCount;
			
			            #MessageCountDetails = $WEQueue.CountDetails;
			            ActiveMessageCount = $queue.CountDetails.ActiveMessageCount;
			            DeadLetterMessageCount = $queue.CountDetails.DeadLetterMessageCount;
			            ScheduledMessageCount = $queue.CountDetails.ScheduledMessageCount;
			            TransferMessageCount = $queue.CountDetails.TransferMessageCount;
			            TransferDeadLetterMessageCount = $queue.CountDetails.TransferDeadLetterMessageCount;			
			            #Authorization = $WEQueue.Authorization;
			            IsAnonymousAccessible = $queue.IsAnonymousAccessible;
			            SupportOrdering = $queue.SupportOrdering;
			            Status = $queue.Status;
			            #AvailabilityStatus = $WEQueue.AvailabilityStatus;
			            #ForwardTo = $WEQueue.ForwardTo;
			            #ForwardDeadLetteredMessagesTo = $WEQueue.ForwardDeadLetteredMessagesTo;
			            #CreatedAt = $WEQueue.CreatedAt;
			            #UpdatedAt = $WEQueue.UpdatedAt;
			            #AccessedAt = $WEQueue.AccessedAt;
			            EnablePartitioning = $queue.EnablePartitioning;
			            #UserMetadata = $WEQueue.UserMetadata;
			            #EnableExpress = $WEQueue.EnableExpress;
			            #IsReadOnly = $WEQueue.IsReadOnly;
			            #ExtensionData = $WEQueue.ExtensionData;
                        QueueThresholdAlert = $queueThresholdAlert;
                        QueueFreeSpacePercentage = $queueFreeSpacePercentage;

			        }
			
					$sx
					
			        $queueTable = $queueTable = $queueTable + $sx
			        
			        # Convert table to a JSON document for ingestion 
			        $jsonQueueTable = ConvertTo-Json -InputObject $queueTable

				}
                
                try
                {
                    " Initiating ingestion of Queue data....`n"
                    Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonQueueTable -logType $logType -TimeStampField $WETimestampfield
		    	    #Uncomment below to troubleshoot
		    	    #$jsonQueueTable
                }
                catch {Throw " Ingestion of Queue data has failed!" }
        
        }
        else{Write-Output (" No service bus queues found in namespace: " + $sb.name + " `n" )}
    
        }
    " ----------------- End Queue section -----------------`n"
}

Function Publish-SbTopicMetrics{
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param([parameter(mandatory=$true)]
    [object]$sbNamespace)

    $topicTable = @()
	$jsonTopicTable = @()
    $sx = @()

    " ----------------- Start Topic section -----------------"

	if ($sbNamespace -ne $null)
    {
    " Processing Topics... `n"

		foreach ($sb in $sbNamespace)
		{

            " Going through $($sb.Name) for Topics..."
            #" Attempting to get topics...."

            try
            {
                $sbResourceGroup = (Find-AzureRmResource -ResourceNameEquals $sb.Name).ResourceGroupName
                $topicList = Get-AzureRmServiceBusTopic -ResourceGroup $sbResourceGroup -NamespaceName $sb.Name
            }
            catch
            {
                " Could not get any topics"
                $WEErrorMessage = $_.Exception.Message
                Write-Output (" Error Message: " + $WEErrorMessage)
            }
            
            " Found $($topicList.name.Count) topic(s).`n"
            foreach ($topic in $topicList)
		    {
				if ($topicList -ne $null)
				{

                    #check if the topic message size (SizeInBytes) exceeds the threshold of MaxSizeInMegabytes
                    #if so we raise an alert (=1)
                    if(($topic.SizeInBytes/1MB) -gt $topic.MaxSizeInMegabytes)
                    {
                        $topicThresholdAlert = 1 #exceeds Queue threshold
                    }
                    
                    else
                    {
                        $topicThresholdAlert = 0
                    }

                    
                    if($topic.SizeInBytes -ne 0)
                    {
                        (" TopicSizeInBytes is: " + $topic.SizeInBytes)
                        $topicSizeInMB = $null
                        $topicSizeInMB = ($topic.SizeInBytes/1MB)
                        $topicFreeSpacePercentage = $null
                        $topicFreeSpacePercentage = CalculateFreeSpacePercentage -MaxSizeMB $topic.MaxSizeInMegabytes -CurrentSizeMB $topicSizeInMB
                        $topicFreeSpacePercentage = " {0:N2}" -f $topicFreeSpacePercentage
                    }
                    else
                    {
                        " TopicSizeInBytes is 0, so we are setting the percentage to 100"
                       ;  $topicFreeSpacePercentage = 100
                    }

			            
                        
                        #Construct the ingestion table
                       ;  $sx = New-Object PSObject -Property @{
                        TimeStamp = $([DateTime]::Now.ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" ));
                        TopicName = $topic.name;
                        DefaultMessageTimeToLive = $topic.DefaultMessageTimeToLive;
                        MaxSizeInMegabytes = $topic.MaxSizeInMegabytes;
                        SizeInBytes = $topic.SizeInBytes;
                        EnableBatchedOperations = $topic.EnableBatchedOperations;
                        SubscriptionCount = $topic.SubscriptionCount;
                        TopicThresholdAlert = $topicThresholdAlert;
                        TopicFreeSpacePercentage = $topicFreeSpacePercentage;
                        ActiveMessageCount = $topic.CountDetails.ActiveMessageCount;
                        DeadLetterMessageCount = $topic.Countdetails.DeadLetterMessageCount;
                        ScheduledMessageCount = $topic.Countdetails.ScheduledMessageCount;
                        TransferMessageCount = $topic.Countdetails.TransferMessageCount;
                        TransferDeadLetterMessageCount = $topic.Countdetails.TransferDeadLetterMessageCount;                                                           		            
			            }
                    
			
					$sx
			        $topicTable = $topicTable = $topicTable + $sx
			        
			        # Convert table to a JSON document for ingestion 
			        $jsonTopicTable = ConvertTo-Json -InputObject $topicTable
				}
                else{" No topics found." }
		    	
                try
                {
                    " Initiating ingestion of Topic data....`n"
                    Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonTopicTable -logType $logType -TimeStampField $WETimestampfield
		    	    #Uncomment below to troubleshoot
		    	    #$jsonTopicTable
                }
                catch {Throw " Error ingesting Topic data!" }
			}
		}
	} 
    else
	{
		" This subscription contains no service bus namespaces."
	}
    " ----------------- End Topic section -----------------`n"
}

Function Publish-SbTopicSubscriptions{
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param([parameter(mandatory=$true)]
    [object]$sbNamespace)

    $subscriptionTable = @()
	$jsonSubscriptionTable = @()
    $sx = @()

    " ----------------- Start Topic Subscription section -----------------"

    " Processing Topic Subscriptions... `n"

    if($sbNamespace -ne $null)
    {
        #" Processing $($sbNamespace.Count) service bus namespace(s) `n"

        foreach($sb in $sbNamespace)
        {
            " Going through $($sb.Name) for Topic Subscriptions..."
            
            try
            {
                $sbResourceGroup = (Find-AzureRmResource -ResourceNameEquals $sb.Name).ResourceGroupName
                $topicList = Get-AzureRmServiceBusTopic -ResourceGroup $sbResourceGroup -NamespaceName $sb.Name
            }
            
            catch
            {
                " Could not get any topics"
                $WEErrorMessage = $_.Exception.Message
                Write-Output (" Error Message: " + $WEErrorMessage)
            }
            
            " Found $($topicList.name.Count) topic(s) to go through....`n"

            #check if servicebus instance has topics
            if($topicList.name -ne $null)
            {

                #Getting Subscriptions for each topic
                foreach($topic in $topicList)
                {
                   ;  $topicSubscriptions = Get-AzureRmServiceBusSubscription -ResourceGroup $sbResourceGroup -NamespaceName $sb.Name -TopicName $topic.Name
                    " Found $($topicSubscriptions.name.Count) Subscriptions for Topic `" $($topic.Name)`" - service bus instance `" $($sb.Name)`" ....`n"

                    if($topicSubscriptions.Name.count -gt 0) #if we don't have subscriptions, we need to skip this step
                    {
                        foreach($topicSubscription in $topicSubscriptions)
                        {
                            " Processing Subscription: `" $($topicSubscription.Name)`" for Topic: `" $($topic.Name)`" `n"

                             #Construct the ingestion table
                             ;  $sx = New-Object PSObject -Property @{
                                TimeStamp = $([DateTime]::Now.ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" ));
                                ServiceBusName=$sb.Name;
                                TopicName = $topic.Name;
                                SubscriptionName = $topicSubscription.Name
                                Status = $topicSubscription.Status;
                                EntityAvailabilityStatus = $topicSubscription.EntityAvailabilityStatus;
                                MessageCount = $topicSubscription.MessageCount;
			                    SubscriptionActiveMessageCount = $topicSubscription.CountDetails.ActiveMessageCount;
			                    SubscriptionDeadLetterMessageCount = $topicSubscription.CountDetails.DeadLetterMessageCount;
			                    SubscriptionScheduledMessageCount = $topicSubscription.CountDetails.ScheduledMessageCount;
			                    SubscriptionTransferMessageCount = $topicSubscription.CountDetails.TransferMessageCount;
			                    SubscriptionTransferDeadLetterMessageCount = $topicSubscription.CountDetails.TransferDeadLetterMessageCount;                                 		            
			                   }
					    $sx
			            $subscriptionTable = $subscriptionTable = $subscriptionTable + $sx
			        
			            # Convert table to a JSON document for ingestion 
			            $jsonSubscriptionTable = ConvertTo-Json -InputObject $subscriptionTable
                        }
                        
                        try
                        {
                            " Initiating ingestion of Topic Subscription data....`n"
                            Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonSubscriptionTable -logType $logType -TimeStampField $WETimestampfield
		    	            #Uncomment below to troubleshoot
		    	            #$jsonSubscriptionTable
                        }
                        catch {Throw " Error trying to ingest Topic Subscription data!" }
                    }
                }
            }
            else{(" Skipping " + $sb.Name + " - No topics found `n" )}
        }
    
    }
   
   " ----------------- End Topic Subscription section -----------------`n"
}

$sbNameSpace = $null
$topic = $null; 
$sx = $null
; 
$sbNameSpace = Get-SbNameSpace
Publish-SbQueueMetrics -sbNamespace $sbNameSpace
Publish-SbTopicMetrics -sbNamespace $sbNameSpace
Publish-SbTopicSubscriptions -sbNamespace $sbNameSpace
" `n"
" We're done!"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
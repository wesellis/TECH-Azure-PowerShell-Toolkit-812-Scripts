#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Servicebusingestion

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$ConnectionAssetName = "AzureClassicRunAsConnection"
$connection = Get-AutomationConnection -Name $ConnectionAssetName
Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
$Conn = Get-AutomationConnection -Name $ConnectionAssetName
if ($null -eq $Conn)
    {
        throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
    }
    [string]$CertificateAssetName = $Conn.CertificateAssetName
Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
if ($null -eq $AzureCert)
    {
        throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
    }
Write-Verbose "Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert
Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID
    [string]$StartTime = [dateTime]::Now
    [string]$Timestampfield = "Timestamp"
$CustomerID = Get-AutomationVariable -Name 'OMSWorkspaceId'
$SharedKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'
    [string]$LogType  = " servicebus"
"Logging in to Azure..."
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
$params = @{
     ApplicationId = $Conn.ApplicationID
     CertificateThumbprint = $Conn.CertificateThumbprint
     Tenant = $Conn.TenantID
 }
 Add-AzureRMAccount @params
"Selecting Azure subscription..."
    [string]$SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
 Function CalculateFreeSpacePercentage{
 param(
param(
[Parameter(Mandatory)]
[int]$MaxSizeMB,
[Parameter(Mandatory)]
[int]$CurrentSizeMB
)
)
    [string]$percentage = (($MaxSizeMB - $CurrentSizeMB)/$MaxSizeMB)*100
Return ($percentage)
}
Function Get-SbNameSpace -ErrorAction Stop
{
$SbNamespace = Get-AzureRmServiceBusNamespace -ErrorAction Stop
    if($null -ne $SbNamespace)
        {
        }
    else
    {
        throw "No Service Bus name spaces were found!"
        break
    }
return $SbNamespace
}
function Write-Log {
    param([parameter(mandatory=$true)]
    [object]$SbNamespace)
    [string]$QueueTable = @()
    [string]$JsonQueueTable = @()
    [string]$sx = @()
    " ----------------- Start Queue section -----------------"
    "Found $($SbNamespace.Count) service bus namespace(s)."
    "Processing Queues.... `n"
    foreach($sb in $SbNamespace)
        {
    [string]$SBqueue = $null
        "Going through service bus instance `" $($sb.Name)`" ..."
    [string]$SbResourceGroup = (Find-AzureRmResource -ResourceNameEquals $sb.Name).ResourceGroupName
        " *** Attempting to get queues.... ***"
        try
        {
$SBqueue = Get-AzureRmServiceBusQueue -ResourceGroup $SbResourceGroup -NamespaceName $sb.name
            " *** Number of queues found: $($SBqueue.name.count) *** `n"
        }
        catch
        {Write-Output ("Error in getting queue information for namespace:  " + $sb.name + " `n" )}
        if($null -ne $SBqueue)
        {
    [string]$QueueTable = @()
            foreach($queue in $SBqueue)
            {
                    if(($queue.SizeInBytes/1MB) -gt $Queue.MaxSizeInMegabytes)
                    {
    [string]$QueueThresholdAlert = 1
                    }
                    else
                    {
    [string]$QueueThresholdAlert = 0
                    }
                    if($queue.SizeInBytes -ne 0)
                    {
    [string]$QueueSizeInMB = $null
    [string]$QueueSizeInMB = ($queue.SizeInBytes/1MB)
    [string]$QueueFreeSpacePercentage = $null
    [string]$QueueFreeSpacePercentage = CalculateFreeSpacePercentage -MaxSizeMB $queue.MaxSizeInMegabytes -CurrentSizeMB $QueueSizeInMB
    [string]$QueueFreeSpacePercentage = " {0:N2}" -f $QueueFreeSpacePercentage
                    }
                    else
                    {
                        "QueueSizeInBytes is 0, so we are setting the percentage to 100"
    [string]$QueueFreeSpacePercentage = 100
                    }
$sx = New-Object -ErrorAction Stop PSObject -Property @{
                        TimeStamp = $([DateTime]::Now.ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" ));
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
			            ActiveMessageCount = $queue.CountDetails.ActiveMessageCount;
			            DeadLetterMessageCount = $queue.CountDetails.DeadLetterMessageCount;
			            ScheduledMessageCount = $queue.CountDetails.ScheduledMessageCount;
			            TransferMessageCount = $queue.CountDetails.TransferMessageCount;
			            TransferDeadLetterMessageCount = $queue.CountDetails.TransferDeadLetterMessageCount;
			            IsAnonymousAccessible = $queue.IsAnonymousAccessible;
			            SupportOrdering = $queue.SupportOrdering;
			            Status = $queue.Status;
			            EnablePartitioning = $queue.EnablePartitioning;
                        QueueThresholdAlert = $QueueThresholdAlert;
                        QueueFreeSpacePercentage = $QueueFreeSpacePercentage;
			        }
    [string]$sx
    [string]$QueueTable = $QueueTable = $QueueTable + $sx
    [string]$JsonQueueTable = ConvertTo-Json -InputObject $QueueTable
				}
                try
                {
                    "Initiating ingestion of Queue data....`n"
                    Send-OMSAPIIngestionFile -customerId $CustomerId -sharedKey $SharedKey -body $JsonQueueTable -logType $LogType -TimeStampField $Timestampfield
                }
                catch {Throw "Ingestion of Queue data has failed!" }
        }
        else{Write-Output ("No service bus queues found in namespace: " + $sb.name + " `n" )}
        }
    " ----------------- End Queue section -----------------`n"
}
function Publish-SbTopicMetrics{
    param([parameter(mandatory=$true)]
    [object]$SbNamespace)
    [string]$TopicTable = @()
    [string]$JsonTopicTable = @()
    [string]$sx = @()
    " ----------------- Start Topic section -----------------"
	if ($null -ne $SbNamespace)
    {
    "Processing Topics... `n"
		foreach ($sb in $SbNamespace)
		{
            "Going through $($sb.Name) for Topics..."
            try
            {
    [string]$SbResourceGroup = (Find-AzureRmResource -ResourceNameEquals $sb.Name).ResourceGroupName
$TopicList = Get-AzureRmServiceBusTopic -ResourceGroup $SbResourceGroup -NamespaceName $sb.Name
            }
            catch
            {
                "Could not get any topics"
    [string]$ErrorMessage = $_.Exception.Message
                Write-Output ("Error Message: " + $ErrorMessage)
            }
            "Found $($TopicList.name.Count) topic(s).`n"
            foreach ($topic in $TopicList)
		    {
				if ($null -ne $TopicList)
				{
                    if(($topic.SizeInBytes/1MB) -gt $topic.MaxSizeInMegabytes)
                    {
    [string]$TopicThresholdAlert = 1
                    }
                    else
                    {
    [string]$TopicThresholdAlert = 0
                    }
                    if($topic.SizeInBytes -ne 0)
                    {
                        ("TopicSizeInBytes is: " + $topic.SizeInBytes)
    [string]$TopicSizeInMB = $null
    [string]$TopicSizeInMB = ($topic.SizeInBytes/1MB)
    [string]$TopicFreeSpacePercentage = $null
    [string]$TopicFreeSpacePercentage = CalculateFreeSpacePercentage -MaxSizeMB $topic.MaxSizeInMegabytes -CurrentSizeMB $TopicSizeInMB
    [string]$TopicFreeSpacePercentage = " {0:N2}" -f $TopicFreeSpacePercentage
                    }
                    else
                    {
                        "TopicSizeInBytes is 0, so we are setting the percentage to 100"
    [string]$TopicFreeSpacePercentage = 100
                    }
$sx = New-Object -ErrorAction Stop PSObject -Property @{
                        TimeStamp = $([DateTime]::Now.ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" ));
                        TopicName = $topic.name;
                        DefaultMessageTimeToLive = $topic.DefaultMessageTimeToLive;
                        MaxSizeInMegabytes = $topic.MaxSizeInMegabytes;
                        SizeInBytes = $topic.SizeInBytes;
                        EnableBatchedOperations = $topic.EnableBatchedOperations;
                        SubscriptionCount = $topic.SubscriptionCount;
                        TopicThresholdAlert = $TopicThresholdAlert;
                        TopicFreeSpacePercentage = $TopicFreeSpacePercentage;
                        ActiveMessageCount = $topic.CountDetails.ActiveMessageCount;
                        DeadLetterMessageCount = $topic.Countdetails.DeadLetterMessageCount;
                        ScheduledMessageCount = $topic.Countdetails.ScheduledMessageCount;
                        TransferMessageCount = $topic.Countdetails.TransferMessageCount;
                        TransferDeadLetterMessageCount = $topic.Countdetails.TransferDeadLetterMessageCount;
			            }
    [string]$sx
    [string]$TopicTable = $TopicTable = $TopicTable + $sx
    [string]$JsonTopicTable = ConvertTo-Json -InputObject $TopicTable
				}
                else{"No topics found." }
                try
                {
                    "Initiating ingestion of Topic data....`n"
                    Send-OMSAPIIngestionFile -customerId $CustomerId -sharedKey $SharedKey -body $JsonTopicTable -logType $LogType -TimeStampField $Timestampfield
                }
                catch {Throw "Error ingesting Topic data!" }
			}
		}
	}
    else
	{
		"This subscription contains no service bus namespaces."
	}
    " ----------------- End Topic section -----------------`n"
}
function Publish-SbTopicSubscriptions{
    param([parameter(mandatory=$true)]
    [object]$SbNamespace)
    [string]$SubscriptionTable = @()
    [string]$JsonSubscriptionTable = @()
    [string]$sx = @()
    " ----------------- Start Topic Subscription section -----------------"
    "Processing Topic Subscriptions... `n"
    if($null -ne $SbNamespace)
    {
        foreach($sb in $SbNamespace)
        {
            "Going through $($sb.Name) for Topic Subscriptions..."
            try
            {
    [string]$SbResourceGroup = (Find-AzureRmResource -ResourceNameEquals $sb.Name).ResourceGroupName
$TopicList = Get-AzureRmServiceBusTopic -ResourceGroup $SbResourceGroup -NamespaceName $sb.Name
            }
            catch
            {
                "Could not get any topics"
    [string]$ErrorMessage = $_.Exception.Message
                Write-Output ("Error Message: " + $ErrorMessage)
            }
            "Found $($TopicList.name.Count) topic(s) to go through....`n"
            if($TopicList.name -ne $null)
            {
                foreach($topic in $TopicList)
                {
$TopicSubscriptions = Get-AzureRmServiceBusSubscription -ResourceGroup $SbResourceGroup -NamespaceName $sb.Name -TopicName $topic.Name
                    "Found $($TopicSubscriptions.name.Count) Subscriptions for Topic `" $($topic.Name)`" - service bus instance `" $($sb.Name)`" ....`n"
                    if($TopicSubscriptions.Name.count -gt 0)
                    {
                        foreach($TopicSubscription in $TopicSubscriptions)
                        {
                            "Processing Subscription: `" $($TopicSubscription.Name)`" for Topic: `" $($topic.Name)`" `n"
$sx = New-Object -ErrorAction Stop PSObject -Property @{
                                TimeStamp = $([DateTime]::Now.ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" ));
                                ServiceBusName=$sb.Name;
                                TopicName = $topic.Name;
                                SubscriptionName = $TopicSubscription.Name
                                Status = $TopicSubscription.Status;
                                EntityAvailabilityStatus = $TopicSubscription.EntityAvailabilityStatus;
                                MessageCount = $TopicSubscription.MessageCount;
			                    SubscriptionActiveMessageCount = $TopicSubscription.CountDetails.ActiveMessageCount;
			                    SubscriptionDeadLetterMessageCount = $TopicSubscription.CountDetails.DeadLetterMessageCount;
			                    SubscriptionScheduledMessageCount = $TopicSubscription.CountDetails.ScheduledMessageCount;
			                    SubscriptionTransferMessageCount = $TopicSubscription.CountDetails.TransferMessageCount;
			                    SubscriptionTransferDeadLetterMessageCount = $TopicSubscription.CountDetails.TransferDeadLetterMessageCount;
			                   }
    [string]$sx
    [string]$SubscriptionTable = $SubscriptionTable = $SubscriptionTable + $sx
    [string]$JsonSubscriptionTable = ConvertTo-Json -InputObject $SubscriptionTable
                        }
                        try
                        {
                            "Initiating ingestion of Topic Subscription data....`n"
                            Send-OMSAPIIngestionFile -customerId $CustomerId -sharedKey $SharedKey -body $JsonSubscriptionTable -logType $LogType -TimeStampField $Timestampfield
                        }
                        catch {Throw "Error trying to ingest Topic Subscription data!" }
                    }
                }
            }
            else{("Skipping " + $sb.Name + " - No topics found `n" )}
        }
    }
   " ----------------- End Topic Subscription section -----------------`n"
}
    [string]$SbNameSpace = $null
    [string]$topic = $null;
    [string]$sx = $null
$SbNameSpace = Get-SbNameSpace -ErrorAction Stop
Publish-SbQueueMetrics -sbNamespace $SbNameSpace
Publish-SbTopicMetrics -sbNamespace $SbNameSpace
Publish-SbTopicSubscriptions -sbNamespace $SbNameSpace
" `n"
"We're done!"




<#
.SYNOPSIS
    Sqlazureingestion

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$StartTime = [dateTime]::Now.Subtract([TimeSpan]::FromMinutes(5))
$Timestampfield = "Timestamp"
$customerID = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_ID'
$sharedKey = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_KEY'
"Logging in to Azure..."
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
 $params = @{
     ApplicationId = $Conn.ApplicationID
     CertificateThumbprint = $Conn.CertificateThumbprint
     Tenant = $Conn.TenantID
 }
 Add-AzureRMAccount @params
"Selecting Azure subscription..."
$SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
$logType  = " sqlazure"
"Logtype Name for SQL DB(s) is $logType"
$SQLServers = Find-AzureRmResource -ResourceType Microsoft.Sql/servers
$DBCount = 0
$FailedConnections = @()
if($SQLServers -ne $Null)
{
	foreach($SQLServer in $SQLServers)
    	{
		# Get resource usage metrics for a database in an elastic database for the specified time interval.
		# This example will run every 10 minutes on a schedule and gather two data points for 15 metrics leveraging the ARM API
		$DBList = Get-AzureRmSqlDatabase -ServerName $SQLServer.Name -ResourceGroupName $SQLServer.ResourceGroupName
		# If the listing of databases is not $null
		if($dbList -ne $Null)
		{
			foreach ($db in $dbList)
			{
                		if($db.Edition -ne "None" )
                		{
		                    	$DBCount++
		                    	$Metrics = @()
		                    	if($db.ElasticPoolName -ne $Null)
		    			{
						$elasticPool = $db.ElasticPoolName
		    			}
		    			else
		    			{
						$elasticPool = " none"
		    			}
					try
	                    		{
	                        		$Metrics = $Metrics + (Get-AzureRmMetric -ResourceId $db.ResourceId -TimeGrain ([TimeSpan]::FromMinutes(5)) -StartTime $StartTime)
					}
	                    		catch
	            			{
						# Add up failed connections due to offline or access denied
						$FailedConnections = $FailedConnections + "Failed to connect to $($db.DatabaseName) on SQL Server $($db.ServerName)"
					}
					# Format metrics into a table.
$table = @()
                    			foreach($metric in $Metrics)
                    			{
                				foreach($metricValue in $metric.MetricValues)
	                        		{
$sx = New-Object -ErrorAction Stop PSObject -Property @{
                	                		Timestamp = $metricValue.Timestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                        	        		MetricName = $metric.Name;
                                			Average = $metricValue.Average;
                                			SubscriptionID = $Conn.SubscriptionID;
                                			ResourceGroup = $db.ResourceGroupName;
                                			ServerName = $SQLServer.Name;
                                			DatabaseName = $db.DatabaseName;
		                        		ElasticPoolName = $elasticPool;
		                        		AzureSubscription = $SelectedAzureSub.subscription.subscriptionName;
		                        		ResourceLink = "https://portal.azure.com/#resource/subscriptions/$($Conn.SubscriptionID)/resourceGroups/$($db.ResourceGroupName)/providers/Microsoft.Sql/Servers/$($SQLServer.Name)/databases/$($db.DatabaseName)"
                            				}
                            				$table = $table = $table + $sx
                        			}
                	 			# Convert table to a JSON document for ingestion
$jsonTable = ConvertTo-Json -InputObject $table
                    			}
		    			#Post the data to the endpoint - looking for an " accepted" response code
                			Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonTable -logType $logType -TimeStampField $Timestampfield
					# Uncomment below to troubleshoot
					#$jsonTable
        			}
            		}
		}
	}
}
"Total DBs processed $DBCount"
if($FailedConnections -ne $Null)
{
    ""
    "Failed to connect to $($FailedConnections.Count) databases"
    $FailedConnections
}\n
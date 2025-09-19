#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Sqlazureingestion

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Sqlazureingestion

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"


$WEStartTime = [dateTime]::Now.Subtract([TimeSpan]::FromMinutes(5))


$WETimestampfield = " Timestamp" 


$customerID = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_ID'


$sharedKey = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_KEY'



" Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 
 $params = @{
     ApplicationId = $WEConn.ApplicationID
     CertificateThumbprint = $WEConn.CertificateThumbprint
     Tenant = $WEConn.TenantID
 }
 Add-AzureRMAccount @params

" Selecting Azure subscription..."
$WESelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 




$logType  = " sqlazure"
" Logtype Name for SQL DB(s) is $logType"


$WESQLServers = Find-AzureRmResource -ResourceType Microsoft.Sql/servers

$WEDBCount = 0
$WEFailedConnections = @()
if($WESQLServers -ne $WENull)
{
	foreach($WESQLServer in $WESQLServers)
    	{
		# Get resource usage metrics for a database in an elastic database for the specified time interval.
		# This example will run every 10 minutes on a schedule and gather two data points for 15 metrics leveraging the ARM API 
		$WEDBList = Get-AzureRmSqlDatabase -ServerName $WESQLServer.Name -ResourceGroupName $WESQLServer.ResourceGroupName
        
		# If the listing of databases is not $null 
		if($dbList -ne $WENull)
		{
			foreach ($db in $dbList)
			{
                		if($db.Edition -ne " None" )
                		{
		                    	$WEDBCount++
		                    	$WEMetrics = @()
		                    	if($db.ElasticPoolName -ne $WENull)
		    			{
						$elasticPool = $db.ElasticPoolName
		    			}
		    			else
		    			{
						$elasticPool = " none"
		    			}                    
					try
	                    		{
	                        		$WEMetrics = $WEMetrics + (Get-AzureRmMetric -ResourceId $db.ResourceId -TimeGrain ([TimeSpan]::FromMinutes(5)) -StartTime $WEStartTime)
					}
	                    		catch
	            			{
						# Add up failed connections due to offline or access denied
						$WEFailedConnections = $WEFailedConnections + " Failed to connect to $($db.DatabaseName) on SQL Server $($db.ServerName)"
					}		
					# Format metrics into a table.
                    		; 	$table = @()
                    			foreach($metric in $WEMetrics)
                    			{ 
                				foreach($metricValue in $metric.MetricValues)
	                        		{
        	                		; 	$sx = New-Object -ErrorAction Stop PSObject -Property @{
                	                		Timestamp = $metricValue.Timestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                        	        		MetricName = $metric.Name; 
                                			Average = $metricValue.Average;
                                			SubscriptionID = $WEConn.SubscriptionID;
                                			ResourceGroup = $db.ResourceGroupName;
                                			ServerName = $WESQLServer.Name;
                                			DatabaseName = $db.DatabaseName;
		                        		ElasticPoolName = $elasticPool;
		                        		AzureSubscription = $WESelectedAzureSub.subscription.subscriptionName;
		                        		ResourceLink = " https://portal.azure.com/#resource/subscriptions/$($WEConn.SubscriptionID)/resourceGroups/$($db.ResourceGroupName)/providers/Microsoft.Sql/Servers/$($WESQLServer.Name)/databases/$($db.DatabaseName)"
                            				}
                            				$table = $table = $table + $sx
                        			}
                	 			# Convert table to a JSON document for ingestion 
		    			; 	$jsonTable = ConvertTo-Json -InputObject $table
                    			}
		    			#Post the data to the endpoint - looking for an " accepted" response code
                			Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonTable -logType $logType -TimeStampField $WETimestampfield
					# Uncomment below to troubleshoot
					#$jsonTable
        			}	
            		}
		}
	}		
}
" Total DBs processed $WEDBCount"
if($WEFailedConnections -ne $WENull)
{
    ""
    " Failed to connect to $($WEFailedConnections.Count) databases"
    $WEFailedConnections
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

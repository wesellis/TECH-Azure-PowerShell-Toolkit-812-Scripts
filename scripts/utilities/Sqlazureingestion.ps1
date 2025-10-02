#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Sqlazureingestion

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$StartTime = [dateTime]::Now.Subtract([TimeSpan]::FromMinutes(5))
$Timestampfield = "Timestamp"
$CustomerID = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_ID'
$SharedKey = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_KEY'
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
$LogType  = " sqlazure"
"Logtype Name for SQL DB(s) is $LogType"
$SQLServers = Find-AzureRmResource -ResourceType Microsoft.Sql/servers
$DBCount = 0
$FailedConnections = @()
if($SQLServers -ne $Null)
{
	foreach($SQLServer in $SQLServers)
    	{
		$DBList = Get-AzureRmSqlDatabase -ServerName $SQLServer.Name -ResourceGroupName $SQLServer.ResourceGroupName
		if($DbList -ne $Null)
		{
			foreach ($db in $DbList)
			{
                		if($db.Edition -ne "None" )
                		{
		                    	$DBCount++
		                    	$Metrics = @()
		                    	if($db.ElasticPoolName -ne $Null)
		    			{
						$ElasticPool = $db.ElasticPoolName
		    			}
		    			else
		    			{
						$ElasticPool = " none"
		    			}
					try
	                    		{
	                        		$Metrics = $Metrics + (Get-AzureRmMetric -ResourceId $db.ResourceId -TimeGrain ([TimeSpan]::FromMinutes(5)) -StartTime $StartTime)
					}
	                    		catch
	            			{
						$FailedConnections = $FailedConnections + "Failed to connect to $($db.DatabaseName) on SQL Server $($db.ServerName)"
					}
$table = @()
                    			foreach($metric in $Metrics)
                    			{
                				foreach($MetricValue in $metric.MetricValues)
	                        		{
$sx = New-Object -ErrorAction Stop PSObject -Property @{
                	                		Timestamp = $MetricValue.Timestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                        	        		MetricName = $metric.Name;
                                			Average = $MetricValue.Average;
                                			SubscriptionID = $Conn.SubscriptionID;
                                			ResourceGroup = $db.ResourceGroupName;
                                			ServerName = $SQLServer.Name;
                                			DatabaseName = $db.DatabaseName;
		                        		ElasticPoolName = $ElasticPool;
		                        		AzureSubscription = $SelectedAzureSub.subscription.subscriptionName;
		                        		ResourceLink = "https://portal.azure.com/#resource/subscriptions/$($Conn.SubscriptionID)/resourceGroups/$($db.ResourceGroupName)/providers/Microsoft.Sql/Servers/$($SQLServer.Name)/databases/$($db.DatabaseName)"
                            				}
                            				$table = $table = $table + $sx
                        			}
$JsonTable = ConvertTo-Json -InputObject $table
                    			}
                			Send-OMSAPIIngestionFile -customerId $CustomerId -sharedKey $SharedKey -body $JsonTable -logType $LogType -TimeStampField $Timestampfield
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
    $FailedConnections`n}

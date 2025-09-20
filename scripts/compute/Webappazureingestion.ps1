#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Webappazureingestion

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
$logType  = " webappazure"
"Logtype Name is $logType"
$WebApps = Find-AzureRmResource -ResourceType Microsoft.Web/sites #|where -Property Kind -eq Webapp
if($WebApps -ne $Null)
{
	foreach($WebApp in $WebApps)
	{
		# Get resource usage metrics for a webapp for the specified time interval.
		# This example will run every 10 minutes on a schedule and gather data points for 30+ metrics leveraging the ARM API
        $Metrics = @()
        $Metrics = $Metrics + (Get-AzureRmMetric -ResourceId $WebApp.ResourceId -TimeGrain ([TimeSpan]::FromMinutes(1)) -StartTime $StartTime)
		# Format metrics into a table.
$table = @()
        foreach($metric in $Metrics)
        {
			if($metric.MetricValues.Count -ne 0)
			{
				foreach($metricValue in $metric.MetricValues)
				{
$sx = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $metricValue.Timestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
						MetricName = $metric.Name;
						Average = $metricValue.Average;
						SubscriptionID = $Conn.SubscriptionID;
						ResourceGroup = $WebApp.ResourceGroupName;
						ServerName = $WebApp.Name
					}
					$table = $table = $table + $sx
				}
				# Convert table to a JSON document for ingestion
$jsonTable = ConvertTo-Json -InputObject $table
			}
		}
		# Uncomment below to troubleshoot
		# $jsonTable
		if ($jsonTable -ne $Null)
		{
			#Post the data to the endpoint - looking for an " accepted" response code
			Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonTable -logType $logType -TimeStampField $Timestampfield
		}
    }
}



<#
.SYNOPSIS
    Webappazureingestion

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
    We Enhanced Webappazureingestion

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


$WEStartTime = [dateTime]::Now.Subtract([TimeSpan]::FromMinutes(5))


$WETimestampfield = " Timestamp" 


$customerID = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_ID'


$sharedKey = Get-AutomationVariable -Name 'OPSINSIGHTS_WS_KEY'



" Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 
 Add-AzureRMAccount -ServicePrincipal -Tenant $WEConn.TenantID `
 -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint

" Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 



$logType  = " webappazure"
" Logtype Name is $logType"


$WEWebApps = Find-AzureRmResource -ResourceType Microsoft.Web/sites #|where -Property Kind -eq Webapp




if($WEWebApps -ne $WENull)
{
	foreach($WEWebApp in $WEWebApps)
	{
		
		# Get resource usage metrics for a webapp for the specified time interval.
		# This example will run every 10 minutes on a schedule and gather data points for 30+ metrics leveraging the ARM API 
        $WEMetrics = @()
        $WEMetrics = $WEMetrics + (Get-AzureRmMetric -ResourceId $WEWebApp.ResourceId -TimeGrain ([TimeSpan]::FromMinutes(1)) -StartTime $WEStartTime)
		
		# Format metrics into a table.
       ;  $table = @()
        foreach($metric in $WEMetrics)
        { 
			if($metric.MetricValues.Count -ne 0)
			{
				foreach($metricValue in $metric.MetricValues)
				{
				; 	$sx = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $metricValue.Timestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
						MetricName = $metric.Name; 
						Average = $metricValue.Average;
						SubscriptionID = $WEConn.SubscriptionID;
						ResourceGroup = $WEWebApp.ResourceGroupName;
						ServerName = $WEWebApp.Name
					}
					$table = $table = $table + $sx
				}
				# Convert table to a JSON document for ingestion 
			; 	$jsonTable = ConvertTo-Json -InputObject $table
			}
		}
		
		# Uncomment below to troubleshoot
		# $jsonTable

		if ($jsonTable -ne $WENull)			
		{
			#Post the data to the endpoint - looking for an " accepted" response code
			Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey -body $jsonTable -logType $logType -TimeStampField $WETimestampfield
			
		}
    }
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
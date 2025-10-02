#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Webappazureingestion

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
Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
$LogType  = " webappazure"
"Logtype Name is $LogType"
$WebApps = Find-AzureRmResource -ResourceType Microsoft.Web/sites
if($WebApps -ne $Null)
{
	foreach($WebApp in $WebApps)
	{
        $Metrics = @()
        $Metrics = $Metrics + (Get-AzureRmMetric -ResourceId $WebApp.ResourceId -TimeGrain ([TimeSpan]::FromMinutes(1)) -StartTime $StartTime)
$table = @()
        foreach($metric in $Metrics)
        {
			if($metric.MetricValues.Count -ne 0)
			{
				foreach($MetricValue in $metric.MetricValues)
				{
$sx = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $MetricValue.Timestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
						MetricName = $metric.Name;
						Average = $MetricValue.Average;
						SubscriptionID = $Conn.SubscriptionID;
						ResourceGroup = $WebApp.ResourceGroupName;
						ServerName = $WebApp.Name
					}
					$table = $table = $table + $sx
				}
$JsonTable = ConvertTo-Json -InputObject $table
			}
		}
		if ($JsonTable -ne $Null)
		{
			Send-OMSAPIIngestionFile -customerId $CustomerId -sharedKey $SharedKey -body $JsonTable -logType $LogType -TimeStampField $Timestampfield
		}
    }
`n}

<#
.SYNOPSIS
    We Enhanced Azuresacreateschedules Ms Mgmt Sa

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

param ($collectAuditLogs,$collectionFromAllSubscriptions)


"Logging in to Azure..."
$WEArmConn = Get-AutomationConnection -Name AzureRunAsConnection 

if ($WEArmConn  -eq $null)
{
	throw " Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}


$retry = 6
$syncOk = $false
do
{ 
	try
	{  
		Add-AzureRMAccount -ServicePrincipal -Tenant $WEArmConn.TenantID -ApplicationId $WEArmConn.ApplicationID -CertificateThumbprint $WEArmConn.CertificateThumbprint
		$syncOk = $true
	}
	catch
	{
		$WEErrorMessage = $_.Exception.Message
		$WEStackTrace = $_.Exception.StackTrace
		Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. Retry attempts left: $retry"
		$retry = $retry - 1       
		Start-Sleep -s 60        
	}
} while (-not $syncOk -and $retry -ge 0)
" Selecting Azure subscription..."
$WESelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $WEArmConn.SubscriptionId -TenantId $WEArmConn.tenantid 

$subscriptionid=$WEArmConn.SubscriptionId
" Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
$path=(get-module -Name AzureRM.Profile).path
$path=Split-Path $path
$dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
$adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal

}
catch
{
	$WEErrorMessage = $_.Exception.Message
	$WEStackTrace = $_.Exception.StackTrace
	Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. "
}

$certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $WEArmConn.CertificateThumbprint}

[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]

$WECliCert=new-object   Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($WEArmConn.ApplicationId,$mycert)
$WEAuthContext = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($WEArmConn.tenantid)")
$result = $WEAuthContext.AcquireToken(" https://management.core.windows.net/",$WECliCert)
$header = " Bearer " + $result.AccessToken; 
$headers = @{" Authorization"=$header;" Accept"=" application/json"}
$body=$null
$WEHTTPVerb=" GET"
$subscriptionInfoUri = " https://management.azure.com/subscriptions/"+$subscriptionid+" ?api-version=2016-02-01"
$subscriptionInfo = Invoke-RestMethod -Uri $subscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($subscriptionInfo)
{
	" Successfully connected to Azure ARM REST"
}


   
	try
    {
        $WEAsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
       
    }
    Catch
    {
        if ($WEAsmConn -eq $null) {
            Write-Warning " Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
            $getAsmHeader=$false
        }
    }
     if ($WEAsmConn -eq $null) {
        Write-Warning " Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
        $getAsmHeader=$false
    }Else
	{
			$getAsmHeader=$true
    }





$WEAAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
$WEAAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
$WEMetricsRunbookName = " AzureSAIngestionMetrics-MS-Mgmt-SA"
$WEMetricsScheduleName = " AzureStorageMetrics-Schedule"
$WELogsRunbookName=" AzureSAIngestionLogs-MS-Mgmt-SA"
$WELogsScheduleName = " AzureStorageLogs-HourlySchedule"
$WEMetricsEnablerRunbookName = " AzureSAMetricsEnabler-MS-Mgmt-SA"
$WEMetricsEnablerScheduleName = " AzureStorageMetricsEnabler-DailySchedule"
$mainSchedulerName=" AzureSA-Scheduler-Hourly"

$varText= " AAResourceGroup = $WEAAResourceGroup , AAAccount = $WEAAAccount"

Write-output $varText


New-AzureRmAutomationVariable -Name varVMIopsList -Description " Variable to store IOPS limits for Azure VM Sizes." -Value $vmiolimits -Encrypted 0 -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount  -ea 0

IF([string]::IsNullOrEmpty($WEAAAccount) -or [string]::IsNullOrEmpty($WEAAResourceGroup))
{

	Write-Error " Automation Account  or Automation Account Resource Group Variables is empty. Make sure AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA and AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA variables exist in automation account and populated. "
	Write-Output " Script will not continue"
	Exit


}


$min=(get-date).Minute 
if($min -in 0..10) 
{
	$WERBStart1=(get-date -Minute 16 -Second 00).ToUniversalTime()
}Elseif($min -in 11..25) 
{
	$WERBStart1=(get-date -Minute 31 -Second 00).ToUniversalTime()
}elseif($min -in 26..40) 
{
	$WERBStart1=(get-date -Minute 46 -Second 00).ToUniversalTime()
}ElseIf($min -in 46..55) 
{
	$WERBStart1=(get-date -Minute 01 -Second 00).AddHours(1).ToUniversalTime()
}Else
{
	$WERBStart1=(get-date -Minute 16 -Second 00).AddHours(1).ToUniversalTime()
}

$WERBStart2=$WERBStart1.AddMinutes(15)
$WERBStart3=$WERBStart2.AddMinutes(15)
$WERBStart4=$WERBStart3.AddMinutes(15)




$allSchedules=Get-AzureRmAutomationSchedule `
-AutomationAccountName $WEAAAccount `
-ResourceGroupName $WEAAResourceGroup

foreach ($sch in  $allSchedules|where{$_.Name -match $WEMetricsScheduleName -or $_.Name -match $WEMetricsEnablerScheduleName -or $_.Name -match $WELogsScheduleName })
{

	Write-output " Removing Schedule $($sch.Name)    "
	Remove-AzureRmAutomationSchedule `
	-AutomationAccountName $WEAAAccount `
	-Force `
	-Name $sch.Name `
	-ResourceGroupName $WEAAResourceGroup `
	
} 

Write-output  " Creating schedule $WEMetricsScheduleName for runbook $WEMetricsRunbookName"

$i=1
Do {
	New-AzureRmAutomationSchedule `
	-AutomationAccountName $WEAAAccount `
	-HourInterval 1 `
	-Name $($WEMetricsScheduleName+" -$i") `
	-ResourceGroupName $WEAAResourceGroup `
	-StartTime (Get-Variable -Name RBStart" $i").Value

	IF ($collectionFromAllSubscriptions  -match 'Enabled')
	{
	; 	$params = @{" collectionFromAllSubscriptions" = $true ; " getAsmHeader"=$getAsmHeader}

		Register-AzureRmAutomationScheduledRunbook `
		-AutomationAccountName $WEAAAccount `
		-ResourceGroupName  $WEAAResourceGroup `
		-RunbookName $WEMetricsRunbookName `
		-ScheduleName $($WEMetricsScheduleName+" -$i") -Parameters $WEParams
	}Else
	{

		$params = @{" collectionFromAllSubscriptions" = $false ; " getAsmHeader"=$getAsmHeader}
		Register-AzureRmAutomationScheduledRunbook `
		-AutomationAccountName $WEAAAccount `
		-ResourceGroupName  $WEAAResourceGroup `
		-RunbookName $WEMetricsRunbookName `
		-ScheduleName $($WEMetricsScheduleName+" -$i")  -Parameters $WEParams 
	}

	$i++
}
While ($i -le 4)





IF($collectAuditLogs -eq 'Enabled')
{

	#Add the schedule an hour ahead and start the runbook

	$WERunbookStartTime = $WEDate =(get-date -Minute 05 -Second 00).AddHours(1).ToUniversalTime()
	IF (($runbookstarttime-(Get-date).ToUniversalTime()).TotalMinutes -lt 6)
	{
		$WERunbookStartTime=((Get-date).ToUniversalTime()).AddMinutes(7)

	}
	Write-Output " Creating schedule $WELogsScheduleName for $WERunbookStartTime for runbook $WELogsRunbookName"

	New-AzureRmAutomationSchedule `
	-AutomationAccountName $WEAAAccount `
	-HourInterval 1 `
	-Name $WELogsScheduleName `
	-ResourceGroupName $WEAAResourceGroup `
	-StartTime $WERunbookStartTime

	IF ($collectionFromAllSubscriptions  -match 'Enabled')
	{
	; 	$params = @{" collectionFromAllSubscriptions" = $true ; " getAsmHeader"=$getAsmHeader}
		Register-AzureRmAutomationScheduledRunbook `
		-AutomationAccountName $WEAAAccount `
		-ResourceGroupName  $WEAAResourceGroup `
		-RunbookName $WELogsRunbookName `
		-ScheduleName $WELogsScheduleName -Parameters $WEParams

		Start-AzureRmAutomationRunbook -AutomationAccountName $WEAAAccount -Name $WELogsRunbookName -ResourceGroupName $WEAAResourceGroup -Parameters $WEParams | out-null
	}Else
	{
		
		$params = @{" collectionFromAllSubscriptions" = $false ; " getAsmHeader"=$getAsmHeader}
		
		Register-AzureRmAutomationScheduledRunbook `
		-AutomationAccountName $WEAAAccount `
		-ResourceGroupName  $WEAAResourceGroup `
		-RunbookName $WELogsRunbookName `
		-ScheduleName $WELogsScheduleName -Parameters $WEParams

		Start-AzureRmAutomationRunbook -AutomationAccountName $WEAAAccount -Name $WELogsRunbookName -ResourceGroupName $WEAAResourceGroup | out-null
	}



	
}



$WEMetricsRunbookStartTime = $WEDate = [DateTime]::Today.AddHours(2).AddDays(1)

Write-Output " Creating schedule $WEMetricsEnablerScheduleName for $WEMetricsRunbookStartTime for runbook $WEMetricsEnablerRunbookName"

New-AzureRmAutomationSchedule `
-AutomationAccountName $WEAAAccount `
-DayInterval 1 `
-Name " $WEMetricsEnablerScheduleName" `
-ResourceGroupName $WEAAResourceGroup `
-StartTime $WEMetricsRunbookStartTime


Register-AzureRmAutomationScheduledRunbook `
-AutomationAccountName $WEAAAccount `
-ResourceGroupName  $WEAAResourceGroup `
-RunbookName $WEMetricsEnablerRunbookName `
-ScheduleName " $WEMetricsEnablerScheduleName"





Start-AzureRmAutomationRunbook -Name $WEMetricsEnablerRunbookName -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount | out-null


; 
$allSchedules=Get-AzureRmAutomationSchedule `
		-AutomationAccountName $WEAAAccount `
		-ResourceGroupName $WEAAResourceGroup |where{$_.Name -match $WEMetricsScheduleName -or $_.Name -match $WEMetricsEnablerScheduleName -or $_.Name -match $WELogsScheduleName }


If ($allSchedules.count -ge 5)
{
Write-output " Removing hourly schedule for this runbook as its not needed anymore  "
Remove-AzureRmAutomationSchedule `
		-AutomationAccountName $WEAAAccount `
		-Force `
		-Name $mainSchedulerName `
		-ResourceGroupName $WEAAResourceGroup `


}

	



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
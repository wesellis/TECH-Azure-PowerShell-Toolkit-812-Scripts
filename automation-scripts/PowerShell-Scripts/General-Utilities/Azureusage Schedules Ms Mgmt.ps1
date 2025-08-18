<#
.SYNOPSIS
    Azureusage Schedules Ms Mgmt

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
    We Enhanced Azureusage Schedules Ms Mgmt

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
[Parameter(Mandatory=$false)][string]$WECurrency   ,
[Parameter(Mandatory=$false)][string]$WELocale   ,
[Parameter(Mandatory=$false)][string]$WERegionInfo   ,
[Parameter(Mandatory=$false)][string]$WEOfferDurableId ,
[Parameter(Mandatory=$false)][bool]$propagatetags=$true,
[Parameter(Mandatory=$false)][string]$syncInterval ,
[Parameter(Mandatory=$false)] [bool] $clearLocks=$false                
)

Write-Verbose " Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 

$retry = 6
$syncOk = $false
do
{ 
	try
	{  
		Add-AzureRMAccount -ServicePrincipal -Tenant $WEConn.TenantID -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint
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
Write-Verbose " Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 

$WEAAResourceGroup = Get-AutomationVariable -Name 'AzureUsage-AzureAutomationResourceGroup-MS-Mgmt'
$WEAAAccount = Get-AutomationVariable -Name 'AzureUsage-AzureAutomationAccount-MS-Mgmt'
$WERunbookName = " AzureUsage-MS-Mgmt"
$WEScheduleName = " AzureUsage-Scheduler-$syncInterval"
$schedulerrunbookname=" AzureUsage-Schedules-MS-Mgmt"

$WERunbookStartTime = $WEDate = $([DateTime]::Now.AddMinutes(10))
IF($syncInterval -eq 'Hourly')
{
	$WERunbookScheduleTime=(get-date -ErrorAction Stop   -Minute 2 -Second 0).addhours(1)
	if ($WERunbookStartTime -gt $WERunbookScheduleTime)
	{
		$WERunbookScheduleTime=(get-date -ErrorAction Stop   -Minute 2 -Second 0).addhours(2)
	}
	$interval=1
	
}Else
{
	$WERunbookScheduleTime=(get-date -ErrorAction Stop  -Hour 0 -Minute 0 -Second 0).adddays(1).AddHours(2)
	$interval=24
}
$checkschdl=@(get-AzureRmAutomationScheduledRunbook -RunbookName $WERunbookName -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup)
If ([string]::IsNullOrEmpty($checkschdl))
{
	$sch=$null
; 	$WERBsch=Get-AzureRmAutomationSchedule -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup|where{$_.name -match $WEScheduleName}
	IF($WERBsch)
	{
		foreach ($sch in $WERBsch)
		{
			Remove-AzureRmAutomationSchedule -AutomationAccountName $WEAAAccount -Name $sch.Name -ResourceGroupName $WEAAResourceGroup -Force -ea 0
			
		}
	}
}
Write-Verbose " Creating $syncInterval schedule " ; 
$params= @{" Currency" =$WECurrency ;" Locale" =$WELocale;" RegionInfo" = $WERegionInfo;OfferDurableId=$WEOfferDurableId;propagatetags=$propagatetags;syncInterval=$syncInterval}
$WECount = 0
Write-Verbose " Creating schedule $WEScheduleName for $WERunbookScheduleTime for runbook $WERunbookName"; 
$WESchedule = New-AzureRmAutomationSchedule -Name " $WEScheduleName" -StartTime $WERunbookScheduleTime -HourInterval $interval -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup; 
$WESch = Register-AzureRmAutomationScheduledRunbook -RunbookName $WERunbookName -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup -ScheduleName $WEScheduleName -Parameters $params
Start-AzureRmAutomationRunbook -AutomationAccountName $WEAAAccount -Name $WERunbookName -ResourceGroupName $WEAAResourceGroup -Parameters $params


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
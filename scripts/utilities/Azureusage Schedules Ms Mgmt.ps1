#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azureusage Schedules Ms Mgmt

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
[Parameter()]$Currency   ,
[Parameter()]$Locale   ,
[Parameter()]$RegionInfo   ,
[Parameter()]$OfferDurableId ,
[Parameter()][bool]$propagatetags=$true,
[Parameter()]$SyncInterval ,
[Parameter()] [bool] $ClearLocks=$false
)
Write-Verbose "Logging in to Azure..."
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
Write-Verbose "Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureUsage-AzureAutomationResourceGroup-MS-Mgmt'
    $AAAccount = Get-AutomationVariable -Name 'AzureUsage-AzureAutomationAccount-MS-Mgmt'
    $RunbookName = "AzureUsage-MS-Mgmt"
    $ScheduleName = "AzureUsage-Scheduler-$SyncInterval"
    $schedulerrunbookname="AzureUsage-Schedules-MS-Mgmt"
    $RunbookStartTime = $Date = $([DateTime]::Now.AddMinutes(10))
IF($SyncInterval -eq 'Hourly')
{
    $RunbookScheduleTime=(get-date -ErrorAction Stop   -Minute 2 -Second 0).addhours(1)
	if ($RunbookStartTime -gt $RunbookScheduleTime)
	{
    $RunbookScheduleTime=(get-date -ErrorAction Stop   -Minute 2 -Second 0).addhours(2)
	}
    $interval=1
}Else
{
    $RunbookScheduleTime=(get-date -ErrorAction Stop  -Hour 0 -Minute 0 -Second 0).adddays(1).AddHours(2)
    $interval=24
}
    $checkschdl=@(get-AzureRmAutomationScheduledRunbook -RunbookName $RunbookName -AutomationAccountName $AAAccount -ResourceGroupName $AAResourceGroup)
If ([string]::IsNullOrEmpty($checkschdl))
{
    $sch=$null
    $RBsch=Get-AzureRmAutomationSchedule -AutomationAccountName $AAAccount -ResourceGroupName $AAResourceGroup|where{$_.name -match $ScheduleName}
	IF($RBsch)
	{
		foreach ($sch in $RBsch)
		{
			Remove-AzureRmAutomationSchedule -AutomationAccountName $AAAccount -Name $sch.Name -ResourceGroupName $AAResourceGroup -Force -ea 0
		}
	}
}
Write-Verbose "Creating $SyncInterval schedule " ;
    $params= @{"Currency" =$Currency ;"Locale" =$Locale;"RegionInfo" = $RegionInfo;OfferDurableId=$OfferDurableId;propagatetags=$propagatetags;syncInterval=$SyncInterval}
    $Count = 0
Write-Verbose "Creating schedule $ScheduleName for $RunbookScheduleTime for runbook $RunbookName";
    $Schedule = New-AzureRmAutomationSchedule -Name " $ScheduleName" -StartTime $RunbookScheduleTime -HourInterval $interval -AutomationAccountName $AAAccount -ResourceGroupName $AAResourceGroup;
    $Sch = Register-AzureRmAutomationScheduledRunbook -RunbookName $RunbookName -AutomationAccountName $AAAccount -ResourceGroupName $AAResourceGroup -ScheduleName $ScheduleName -Parameters $params
Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $RunbookName -ResourceGroupName $AAResourceGroup -Parameters $params




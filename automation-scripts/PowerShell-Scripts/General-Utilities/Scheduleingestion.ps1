<#
.SYNOPSIS
    We Enhanced Scheduleingestion

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

$WEErrorActionPreference = "Stop"


" Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 
 Add-AzureRmAccount -ServicePrincipal -Tenant $WEConn.TenantID `
 -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint

" Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 


$WEAAResourceGroup = Get-AutomationVariable -name " AzureAutomationResourceGroup"
$WEAAAccount = Get-AutomationVariable -name " AzureAutomationAccount"
$WERunbookName = " servicebusIngestion"
$WEScheduleName = " servicebusIngestionSchedule"

$WERunbookStartTime = $WEDate = $([DateTime]::Now.AddMinutes(10))

[int]$WERunFrequency = 10
$WENumberofSchedules = 60 / $WERunFrequency
" *** $WENumberofSchedules schedules will be created which will invoke the servicebusIngestion runbook to run every 10mins ***"

$WECount = 0
While ($count -lt $WENumberofSchedules)
{
    $count ++

    try
    {
    " Creating schedule $WEScheduleName-$WECount for $WERunbookStartTime for runbook $WERunbookName"
    $WESchedule = New-AzureRmAutomationSchedule -Name " $WEScheduleName-$WECount" -StartTime $WERunbookStartTime -HourInterval 1 -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup
    $WESch = Register-AzureRmAutomationScheduledRunbook -RunbookName $WERunbookName -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup -ScheduleName " $WEScheduleName-$WECount"
   ;  $WERunbookStartTime = $WERunbookStartTime.AddMinutes($WERunFrequency)
    }
    catch
    {throw " Creation of schedules has failed!"}
}

" Done!"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
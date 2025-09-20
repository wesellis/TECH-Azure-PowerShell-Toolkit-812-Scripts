<#
.SYNOPSIS
    Scheduleingestion

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
"Logging in to Azure..."
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
 $params = @{
     ApplicationId = $Conn.ApplicationID
     CertificateThumbprint = $Conn.CertificateThumbprint
     Tenant = $Conn.TenantID
 }
 Add-AzureRmAccount @params
"Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
$AAResourceGroup = Get-AutomationVariable -name "AzureAutomationResourceGroup"
$AAAccount = Get-AutomationVariable -name "AzureAutomationAccount"
$RunbookName = " servicebusIngestion"
$ScheduleName = " servicebusIngestionSchedule"
$RunbookStartTime = $Date = $([DateTime]::Now.AddMinutes(10))
[int]$RunFrequency = 10
$NumberofSchedules = 60 / $RunFrequency
" *** $NumberofSchedules schedules will be created which will invoke the servicebusIngestion runbook to run every 10mins ***"
$Count = 0
While ($count -lt $NumberofSchedules)
{
    $count ++
    try
    {
    "Creating schedule $ScheduleName-$Count for $RunbookStartTime for runbook $RunbookName"
    $Schedule = New-AzureRmAutomationSchedule -Name " $ScheduleName-$Count" -StartTime $RunbookStartTime -HourInterval 1 -AutomationAccountName $AAAccount -ResourceGroupName $AAResourceGroup
$Sch = Register-AzureRmAutomationScheduledRunbook -RunbookName $RunbookName -AutomationAccountName $AAAccount -ResourceGroupName $AAResourceGroup -ScheduleName " $ScheduleName-$Count"
$RunbookStartTime = $RunbookStartTime.AddMinutes($RunFrequency)
    }
    catch
    {throw "Creation of schedules has failed!" }
}
"Done!"


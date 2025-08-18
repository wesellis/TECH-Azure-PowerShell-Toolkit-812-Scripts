<#
.SYNOPSIS
    We Enhanced 12 New Azvmautoshutdown

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

$WESubscriptionId = $WEAzContext.Context.Subscription.Id
New-AzResource -Location eastus -ResourceId $WEScheduledShutdownResourceId  -Properties $WEProperties -Force


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WESubscriptionId = $WEAzContext.Context.Subscription.Id
$WEVM = Get-AzVM -ResourceGroupName $WERGName -Name VMName
$WEVMResourceId = $WEVM.Id
$WEScheduledShutdownResourceId = " /subscriptions/$WESubscriptionId/resourceGroups/wayneVMRG/providers/microsoft.devtestlab/schedules/shutdown-computevm-$WEVMName"
; 
$WEProperties = @{}
$WEProperties.Add('status', 'Enabled')
$WEProperties.Add('taskType', 'ComputeVmShutdownTask')
$WEProperties.Add('dailyRecurrence', @{'time'= 1159})
$WEProperties.Add('timeZoneId', " Eastern Standard Time")
$WEProperties.Add('notificationSettings', @{status='Disabled'; timeInMinutes=15})
$WEProperties.Add('targetResourceId', $WEVMResourceId)


New-AzResource -Location eastus -ResourceId $WEScheduledShutdownResourceId  -Properties $WEProperties -Force


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
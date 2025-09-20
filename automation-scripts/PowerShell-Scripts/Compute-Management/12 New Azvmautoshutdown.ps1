#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Configure VM auto-shutdown

.DESCRIPTION
    Schedule automatic VM shutdown
    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
# Get subscription and VM details
$SubscriptionId = (Get-AzContext).Subscription.Id
$VM = Get-AzVM -ResourceGroupName $RGName -Name $VMName
$VMResourceId = $VM.Id;
$ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RGName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"
$Properties = @{}
$Properties.Add('status', 'Enabled')
$Properties.Add('taskType', 'ComputeVmShutdownTask')
$Properties.Add('dailyRecurrence', @{'time'= 1159})
$Properties.Add('timeZoneId', "Eastern Standard Time" )
$Properties.Add('notificationSettings', @{status='Disabled'; timeInMinutes=15})
$Properties.Add('targetResourceId', $VMResourceId)
New-AzResource -Location eastus -ResourceId $ScheduledShutdownResourceId  -Properties $Properties -Force


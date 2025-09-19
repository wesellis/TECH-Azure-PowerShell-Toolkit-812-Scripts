#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$true)]
    [string]$ShutdownTime,
    
    [Parameter(Mandatory=$true)]
    [string]$TimeZone,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationEmail
)

#region Functions

Write-Information "Configuring auto-shutdown for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

$Properties = @{
    status = "Enabled"
    taskType = "ComputeVmShutdownTask"
    dailyRecurrence = @{
        time = $ShutdownTime
    }
    timeZoneId = $TimeZone
    targetResourceId = $VM.Id
}

if ($NotificationEmail) {
    $Properties.notificationSettings = @{
        status = "Enabled"
        timeInMinutes = 30
        emailRecipient = $NotificationEmail
    }
}

$params = @{
    f = "(Get-AzContext).Subscription.Id, $ResourceGroupName, $VmName)"
    ErrorAction = "Stop"
    Properties = $Properties
    ResourceId = "("/subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}"
}
New-AzResource @params

Write-Information " Auto-shutdown configured successfully:"
Write-Information "  VM: $VmName"
Write-Information "  Shutdown Time: $ShutdownTime"
Write-Information "  Time Zone: $TimeZone"
if ($NotificationEmail) {
    Write-Information "  Notification Email: $NotificationEmail"
}


#endregion

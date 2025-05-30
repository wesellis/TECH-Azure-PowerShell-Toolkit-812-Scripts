# ============================================================================
# Script Name: Azure VM Auto Shutdown Configurator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Configures automatic shutdown for Azure Virtual Machines
# ============================================================================

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

Write-Host "Configuring auto-shutdown for VM: $VmName"

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

New-AzResource `
    -ResourceId ("/subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $ResourceGroupName, $VmName) `
    -Properties $Properties `
    -Force

Write-Host "✅ Auto-shutdown configured successfully:"
Write-Host "  VM: $VmName"
Write-Host "  Shutdown Time: $ShutdownTime"
Write-Host "  Time Zone: $TimeZone"
if ($NotificationEmail) {
    Write-Host "  Notification Email: $NotificationEmail"
}

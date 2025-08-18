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

New-AzResource -ErrorAction Stop `
    -ResourceId ("/subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $ResourceGroupName, $VmName) `
    -Properties $Properties `
    -Force

Write-Information "✅ Auto-shutdown configured successfully:"
Write-Information "  VM: $VmName"
Write-Information "  Shutdown Time: $ShutdownTime"
Write-Information "  Time Zone: $TimeZone"
if ($NotificationEmail) {
    Write-Information "  Notification Email: $NotificationEmail"
}

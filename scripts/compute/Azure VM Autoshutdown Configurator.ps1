#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Autoshutdown Configurator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ShutdownTime,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZone,
    [Parameter()]
    [string]$NotificationEmail
)
Write-Output "Configuring auto-shutdown for VM: $VmName"
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
    [string]$Properties.notificationSettings = @{
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
Write-Output "Auto-shutdown configured successfully:"
Write-Output "VM: $VmName"
Write-Output "Shutdown Time: $ShutdownTime"
Write-Output "Time Zone: $TimeZone"
if ($NotificationEmail) {
    Write-Output "Notification Email: $NotificationEmail"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

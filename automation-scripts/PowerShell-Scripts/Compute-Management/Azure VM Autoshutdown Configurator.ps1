#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Azure Vm Autoshutdown Configurator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
$params = @{
    f = "(Get-AzContext).Subscription.Id, $ResourceGroupName, $VmName)"
    ErrorAction = "Stop"
    Properties = $Properties
    ResourceId = "(" /subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}"
}
New-AzResource @params
Write-Host "Auto-shutdown configured successfully:"
Write-Host "VM: $VmName"
Write-Host "Shutdown Time: $ShutdownTime"
Write-Host "Time Zone: $TimeZone"
if ($NotificationEmail) {
    Write-Host "Notification Email: $NotificationEmail"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n


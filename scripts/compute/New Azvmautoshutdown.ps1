#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Configure VM auto-shutdown

.DESCRIPTION
    Schedule automatic VM shutdown for Azure Virtual Machines
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER ResourceGroupName
    Name of the Azure Resource Group containing the VM

.PARAMETER VMName
    Name of the Virtual Machine to configure auto-shutdown for

.PARAMETER ShutdownTime
    Time to shutdown the VM in 24-hour format (default: 23:59)

.PARAMETER TimeZone
    Time zone for the shutdown schedule (default: Eastern Standard Time)

.PARAMETER Location
    Azure region where the schedule resource will be created (default: eastus)

.PARAMETER EnableNotifications
    Enable shutdown notifications (default: false)

.PARAMETER NotificationTimeMinutes
    Minutes before shutdown to send notification (default: 15)

.EXAMPLE
    .\Configure-VMShutdown.ps1 -ResourceGroupName "myRG" -VMName "myVM"

.EXAMPLE
    .\Configure-VMShutdown.ps1 -ResourceGroupName "myRG" -VMName "myVM" -ShutdownTime "18:00" -TimeZone "Pacific Standard Time"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,

    [Parameter()]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$ShutdownTime = "23:59",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZone = "Eastern Standard Time",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location = "eastus",

    [Parameter()]
    [bool]$EnableNotifications = $false,

    [Parameter()]
    [ValidateRange(1, 120)]
    [int]$NotificationTimeMinutes = 15
)
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    [string]$LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-LogMessage "Starting VM auto-shutdown configuration..." -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Shutdown Time: $ShutdownTime" -Level "INFO"
    Write-LogMessage "Time Zone: $TimeZone" -Level "INFO"
    Write-LogMessage "Location: $Location" -Level "INFO"

    Write-LogMessage "Retrieving Azure context and VM information..." -Level "INFO"
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }
    [string]$SubscriptionId = $context.Subscription.Id
    Write-LogMessage "Using subscription: $SubscriptionId" -Level "INFO"

    Write-LogMessage "Retrieving VM details..." -Level "INFO"
    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop
    if (-not $VM) {
        throw "VM '$VMName' not found in resource group '$ResourceGroupName'"
    }
    [string]$VMResourceId = $VM.Id
    Write-LogMessage "VM Resource ID: $VMResourceId" -Level "INFO"
    [string]$TimeComponents = $ShutdownTime.Split(':')
    [string]$ShutdownTimeFormatted = "{0:D2}{1:D2}" -f [int]$TimeComponents[0], [int]$TimeComponents[1]
    [string]$ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

    Write-LogMessage "Creating shutdown schedule resource..." -Level "INFO"
    Write-LogMessage "Schedule Resource ID: $ScheduledShutdownResourceId" -Level "INFO"
    $Properties = @{
        'status' = 'Enabled'
        'taskType' = 'ComputeVmShutdownTask'
        'dailyRecurrence' = @{
            'time' = $ShutdownTimeFormatted
        }
        'timeZoneId' = $TimeZone
        'notificationSettings' = @{
            'status' = if ($EnableNotifications) { 'Enabled' } else { 'Disabled' }
            'timeInMinutes' = $NotificationTimeMinutes
        }
        'targetResourceId' = $VMResourceId
    }

    Write-LogMessage "Shutdown schedule properties configured:" -Level "INFO"
    Write-LogMessage "  Status: Enabled" -Level "INFO"
    Write-LogMessage "  Daily shutdown time: $ShutdownTime ($ShutdownTimeFormatted)" -Level "INFO"
    Write-LogMessage "  Time zone: $TimeZone" -Level "INFO"
    Write-LogMessage "  Notifications: $(if ($EnableNotifications) { 'Enabled' } else { 'Disabled' })" -Level "INFO"
    if ($EnableNotifications) {
        Write-LogMessage "  Notification time: $NotificationTimeMinutes minutes before shutdown" -Level "INFO"
    }

    Write-LogMessage "Creating the auto-shutdown schedule..." -Level "INFO"
    [string]$result = New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force -ErrorAction Stop

    Write-LogMessage "Auto-shutdown configuration completed successfully!" -Level "SUCCESS"
    Write-LogMessage "VM '$VMName' will automatically shutdown at $ShutdownTime ($TimeZone)" -Level "SUCCESS"

    if ($EnableNotifications) {
        Write-LogMessage "Notifications will be sent $NotificationTimeMinutes minutes before shutdown" -Level "INFO"
    }

    Write-LogMessage "`nNext Steps:" -Level "INFO"
    Write-LogMessage "1. Verify the schedule in Azure Portal under VM > Operations > Auto-shutdown" -Level "INFO"
    Write-LogMessage "2. You can modify or disable the schedule at any time through the portal" -Level "INFO"
    Write-LogMessage "3. The VM will shutdown automatically according to the configured schedule" -Level "INFO"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw`n}

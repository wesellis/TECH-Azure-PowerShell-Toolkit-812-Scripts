#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Configures auto-shutdown for Azure Virtual Machines

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Configures daily auto-shutdown schedules for Azure VMs with optional
    email notifications. Supports different time zones and notification settings.
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VmName
    VM name
.PARAMETER ShutdownTime
    Time to shutdown the VM (24-hour format: HH:mm)
.PARAMETER TimeZone
    Time zone for the shutdown schedule (e.g., "UTC", "Eastern Standard Time")
.PARAMETER NotificationEmail
    Email address for shutdown notifications
.PARAMETER NotificationMinutes
    Minutes before shutdown to send notification (default: 30)
.PARAMETER Force
    Skip confirmation
    .\Azure-VM-AutoShutdown-Configurator.ps1 -ResourceGroupName "RG-Dev" -VmName "VM-DevServer01" -ShutdownTime "19:00" -TimeZone "UTC"
    .\Azure-VM-AutoShutdown-Configurator.ps1 -ResourceGroupName "RG-Dev" -VmName "VM-DevServer01" -ShutdownTime "18:30" -TimeZone "Eastern Standard Time" -NotificationEmail "admin@company.com"
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$ShutdownTime,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZone,
    [Parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$NotificationEmail,
    [Parameter()]
    [int]$NotificationMinutes = 30,
    [Parameter()]
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    Write-Host "Configuring auto-shutdown for VM: $VmName" -ForegroundColor Green
    Write-Host "Validating VM..." -ForegroundColor Green
    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
    if (-not $VM) {
        throw "VM '$VmName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "VM Details:" -ForegroundColor Green
    Write-Output "Name: $($VM.Name)"
    Write-Output "Location: $($VM.Location)"
    Write-Output "Size: $($VM.HardwareProfile.VmSize)"
    try {
        [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone) | Out-Null
        Write-Host "Time zone validated: $TimeZone" -ForegroundColor Green
    }
    catch {
        Write-Warning "Time zone '$TimeZone' may not be valid. Common values: 'UTC', 'Eastern Standard Time', 'Pacific Standard Time'"
    }
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
            timeInMinutes = $NotificationMinutes
            emailRecipient = $NotificationEmail
        }
    }
    $SubscriptionId = $context.Subscription.Id
    $ResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VmName"
    if (-not $Force) {
        Write-Host "`nAuto-shutdown Configuration:" -ForegroundColor Green
        Write-Output "VM: $VmName"
        Write-Output "Shutdown Time: $ShutdownTime"
        Write-Output "Time Zone: $TimeZone"
        if ($NotificationEmail) {
            Write-Output "Notification Email: $NotificationEmail"
            Write-Output "Notification Lead Time: $NotificationMinutes minutes"
        }
        $confirmation = Read-Host "`nConfigure auto-shutdown? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "`nConfiguring auto-shutdown schedule..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($VmName, "Configure auto-shutdown")) {
        $params = @{
            ResourceId = $ResourceId
            Properties = $Properties
            Force = $true
        }
        $schedule = New-AzResource @params
        Write-Host "Auto-shutdown configured successfully!" -ForegroundColor Green
        Write-Host "`nSchedule Details:" -ForegroundColor Green
        Write-Output "VM: $VmName"
        Write-Output "Shutdown Time: $ShutdownTime ($TimeZone)"
        if ($NotificationEmail) {
            Write-Output "Notification: $NotificationEmail ($NotificationMinutes min before)"
        }
        Write-Output "Status: $($Properties.status)"
        Write-Host "`nNext Steps:" -ForegroundColor Green
        Write-Output "1. VM will automatically shutdown daily at $ShutdownTime"
        Write-Output "2. You can modify or disable this schedule in the Azure portal"
        Write-Output "3. Monitor notification emails if configured"
        if (-not $NotificationEmail) {
            Write-Output "4. Consider adding notification email for better awareness"
        }

} catch {
    Write-Error "Failed to configure auto-shutdown: $_"
    throw`n}

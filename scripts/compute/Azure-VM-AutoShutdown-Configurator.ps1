#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Configures auto-shutdown for Azure Virtual Machines

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding()]

    [Parameter(Mandatory = $true)]
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
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    Write-Host "Configuring auto-shutdown for VM: $VmName" -ForegroundColor Yellow
    # Validate VM exists
    Write-Host "Validating VM..." -ForegroundColor Yellow
    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
    if (-not $VM) {
        throw "VM '$VmName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "VM Details:" -ForegroundColor Cyan
    Write-Host "Name: $($VM.Name)"
    Write-Host "Location: $($VM.Location)"
    Write-Host "Size: $($VM.HardwareProfile.VmSize)"
    # Validate time zone
    try {
        [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone) | Out-Null
        Write-Host "Time zone validated: $TimeZone" -ForegroundColor Green
    }
    catch {
        Write-Warning "Time zone '$TimeZone' may not be valid. Common values: 'UTC', 'Eastern Standard Time', 'Pacific Standard Time'"
    }
    # Prepare properties
    $Properties = @{
        status = "Enabled"
        taskType = "ComputeVmShutdownTask"
        dailyRecurrence = @{
            time = $ShutdownTime
        }
        timeZoneId = $TimeZone
        targetResourceId = $VM.Id
    }
    # Add notification settings if email provided
    if ($NotificationEmail) {
        $Properties.notificationSettings = @{
            status = "Enabled"
            timeInMinutes = $NotificationMinutes
            emailRecipient = $NotificationEmail
        }
    }
    # Prepare resource parameters
    $subscriptionId = $context.Subscription.Id
    $resourceId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VmName"
    # Confirmation
    if (-not $Force) {
        Write-Host "`nAuto-shutdown Configuration:" -ForegroundColor Cyan
        Write-Host "VM: $VmName"
        Write-Host "Shutdown Time: $ShutdownTime"
        Write-Host "Time Zone: $TimeZone"
        if ($NotificationEmail) {
            Write-Host "Notification Email: $NotificationEmail"
            Write-Host "Notification Lead Time: $NotificationMinutes minutes"
        }
        $confirmation = Read-Host "`nConfigure auto-shutdown? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    # Create or update auto-shutdown schedule
    Write-Host "`nConfiguring auto-shutdown schedule..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($VmName, "Configure auto-shutdown")) {
        $params = @{
            ResourceId = $resourceId
            Properties = $Properties
            Force = $true
        }
        $schedule = New-AzResource @params
        Write-Host "Auto-shutdown configured successfully!" -ForegroundColor Green
        Write-Host "`nSchedule Details:" -ForegroundColor Cyan
        Write-Host "VM: $VmName"
        Write-Host "Shutdown Time: $ShutdownTime ($TimeZone)"
        if ($NotificationEmail) {
            Write-Host "Notification: $NotificationEmail ($NotificationMinutes min before)"
        }
        Write-Host "Status: $($Properties.status)"
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. VM will automatically shutdown daily at $ShutdownTime"
        Write-Host "2. You can modify or disable this schedule in the Azure portal"
        Write-Host "3. Monitor notification emails if configured"
        if (-not $NotificationEmail) {
            Write-Host "4. Consider adding notification email for better awareness"
        }
    
} catch {
    Write-Error "Failed to configure auto-shutdown: $_"
    throw
}



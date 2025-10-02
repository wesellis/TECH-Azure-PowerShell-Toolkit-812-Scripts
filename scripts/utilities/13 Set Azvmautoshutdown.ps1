#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Sets the auto-shutdown property for a virtual machine hosted in Microsoft Azure.

.DESCRIPTION
    The Set-AzVMAutoShutdown script sets the auto-shutdown property for a virtual machine.

.PARAMETER ResourceGroupName
    Specifies the name of a resource group.

.PARAMETER Name
    Specifies the name of the virtual machine for which auto-shutdown should be enabled or disabled.

.PARAMETER Disable
    Sets the auto-shutdown property to disabled.

.PARAMETER Enable
    Sets the auto-shutdown property to enabled.

.PARAMETER Time
    The time of day the schedule will occur.

.PARAMETER TimeZone
    The timezone

.PARAMETER WebhookUrl
    The webhook URL to which the notification will be sent.

.PARAMETER Email
    The e-mail address to which the notification will be sent.

.EXAMPLE
    Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00
    Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00.

.EXAMPLE
    Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time"
    Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone.

.EXAMPLE
    Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time" -WebhookURL "https://myapp.azurewebsites.net/webhook"
    Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone. Notifications will be enabled and the WebhookURL will be set to "https://myapp.azurewebsites.net/webhook".

.EXAMPLE
    Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time" -Email "alerts@mycompany.com"
    Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone. Notifications will be enabled and sent to alerts@mycompany.com

.EXAMPLE
    Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Disable
    Disables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001.

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(ParameterSetName = "PsDisable", Mandatory = $true)]
    [switch]$Disable,

    [Parameter(ParameterSetName = "PsEnable", Mandatory = $true)]
    [switch]$Enable,

    [Parameter(ParameterSetName = "PsEnable", Mandatory = $true)]
    [DateTime]$Time,

    [Parameter(ParameterSetName = "PsEnable", Mandatory = $false)]
    [string]$TimeZone = (Get-TimeZone -ErrorAction Stop | Select-Object -ExpandProperty Id),

    [Parameter(ParameterSetName = "PsEnable", Mandatory = $false)]
    [AllowEmptyString()]
    [string]$WebhookUrl = "",

    [Parameter(ParameterSetName = "PsEnable", Mandatory = $false)]
    [string]$Email
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

if ((Get-TimeZone -ListAvailable | Select-Object -ExpandProperty Id) -notcontains $TimeZone) {
    Write-Error -Message "TimeZone $TimeZone is not valid"
    return
}

$VmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    ErrorAction = 'SilentlyContinue'
}
$vm = Get-AzVm @VmSplat

if ($null -eq $vm) {
    Write-Error -Message "Virtual machine '$Name' under resource group '$ResourceGroupName' was not found."
    return
}

$properties = @{}
if ($PsCmdlet.ParameterSetName -eq "PsEnable") {
    if ([string]::IsNullOrEmpty($WebhookUrl) -and [string]::IsNullOrEmpty($Email)) {
        $notificationsettings = @{
            "status"        = "Disabled"
            "timeInMinutes" = 30
        }
    }
    else {
        $notificationsettings = @{
            "status"        = "Enabled"
            "timeInMinutes" = 30
        }
        if ([string]::IsNullOrEmpty($WebhookUrl) -ne $true) {
            $notificationsettings.Add("WebhookUrl", $WebhookUrl)
        }
        if ([string]::IsNullOrEmpty($Email) -ne $true) {
            $notificationsettings.Add("emailRecipient", $Email)
            $notificationsettings.Add("notificationLocale", "en")
        }
    }
    $properties = @{
        "status"               = "Enabled"
        "taskType"             = "ComputeVmShutdownTask"
        "dailyRecurrence"      = @{"time" = ("{0:HHmm}" -f $Time) }
        "timeZoneId"           = $TimeZone
        "notificationSettings" = $notificationsettings
        "targetResourceId"     = $vm.Id
    }
}
elseif ($PsCmdlet.ParameterSetName -eq "PsDisable") {
    $properties = @{
        "status"               = "Disabled"
        "taskType"             = "ComputeVmShutdownTask"
        "dailyRecurrence"      = @{"time" = "1900" }
        "timeZoneId"           = (Get-TimeZone).Id
        "notificationSettings" = @{
            "status"        = "Disabled"
            "timeInMinutes" = 30
        }
        "targetResourceId"     = $vm.Id
    }
}
else {
    Write-Error -Message "Unable to determine auto-shutdown action. Use -Enable or -Disable as parameter."
    return
}

try {
    $NewAzResourceSplat = @{
        ResourceId  = ("/subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $ResourceGroupName, $Name)
        Location    = $vm.Location
        Properties  = $properties
        ApiVersion  = "2017-04-26-preview"
        Force       = $true
        ErrorAction = 'SilentlyContinue'
    }
    $output = New-AzResource @NewAzResourceSplat
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}

if ($? -eq $true) {
    return $output
}
else {
    Write-Error -Message $Error[0].Exception.Message
}
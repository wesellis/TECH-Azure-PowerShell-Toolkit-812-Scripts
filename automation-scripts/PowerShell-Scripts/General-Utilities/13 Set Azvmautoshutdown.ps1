#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Set Azvmautoshutdown

.DESCRIPTION
    Set Azvmautoshutdown operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    .SYNOPSIS
        Sets the auto-shutdown property for a virtual machine hosted in Microsoft Azure.
    .DESCRIPTION
        The Set-AzVMAutoShutdown -ErrorAction Stop script set the auto-shutdown property for a virtual machine.
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
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time" -WebhookURL " https://myapp.azurewebsites.net/webhook"
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone. Notifications will be enabled and the WebhookURL will be set to " https://myapp.azurewebsites.net/webhook" .
    .EXAMPLE
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time" -Email " alerts@mycompany.com"
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone. Notifications will be enabled and sent to alerts@mycompany.com
    .EXAMPLE
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Disable
        Disables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001.
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
Name              : shutdown-computevm-Unifi1
ResourceId        : /subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/resourcegroups/inspireav_unifi_rg/providers/microsoft.devtestlab/schedul
                    es/shutdown-computevm-unifi1
ResourceName      : shutdown-computevm-unifi1
ResourceType      : microsoft.devtestlab/schedules
ResourceGroupName : inspireav_unifi_rg
Location          : canadacentral
SubscriptionId    : 408a6c03-bd25-471b-ae84-cf82b3dff420
Properties        : @{status=Enabled; taskType=ComputeVmShutdownTask; dailyRecurrence=; timeZoneId=Central Standard Time;
                    notificationSettings=; createdDate=2020-12-07T03:29:30.3481124+00:00; targetResourceId=/subscriptions/408a6c03-bd25-471b-ae8
                    4-cf82b3dff420/resourceGroups/InspireAV_UniFi_RG/providers/Microsoft.Compute/virtualMachines/Unifi1;
                    provisioningState=Succeeded; uniqueIdentifier=7666f555-4019-4e63-b2af-b17fcdfeedfc}
    General notes
[CmdletBinding()]
[OutputType([bool])]
 -ErrorAction Stop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
        [Parameter(ParameterSetName = "PsDisable" , Mandatory = $true)][switch]$Disable,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $true)][switch]$Enable,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $true)][DateTime]$Time,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $false)][string]$TimeZone = (Get-TimeZone -ErrorAction Stop | Select-Object -ExpandProperty Id),
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $false)][AllowEmptyString()][string]$WebhookUrl = "" ,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $false)][string]$Email
    )
    # Check the loaded modules
    # $modules = @("Az.Compute" , "Az.Resources" , "Az.Profile" )
    # foreach ($module in $modules) {
    #     if ((Get-Module -Name $module) -eq $null) {
    #         Write-Error -Message "PowerShell module '$module' is not loaded" -RecommendedAction "Please download the Azure PowerShell command-line tools from https://azure.microsoft.com/en-us/downloads/"
    #         return
    #     }
    # }
    # # Check if currently logged-on to Azure
    # if ((Get-AzContext).Account -eq $null) {
    #     Write-Error -Message "No account found in the context. Please login using Login-AzAccount."
    #     return
    # }
    # Validate the set timezone
    if ((Get-TimeZone -ListAvailable | Select-Object -ExpandProperty Id) -notcontains $TimeZone) {
        Write-Error -Message "TimeZone $TimeZone is not valid"
        return
    }
    # Retrieve the VM from the defined resource group
    $vmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    ErrorAction = SilentlyContinue
}
Get-AzVm @vmSplat
    if ($null -eq $vm) {
        Write-Error -Message "Virtual machine '$Name' under resource group '$ResourceGroupName' was not found."
        return
    }
    # Check if Auto-Shutdown needs to be enabled or disabled
$properties = @{}
    if ($PsCmdlet.ParameterSetName -eq "PsEnable" ) {
        # Construct the notifications (only enable if webhook is enabled)
        if ([string]::IsNullOrEmpty($WebhookUrl) -and [string]::IsNullOrEmpty($Email)) {
$notificationsettings = @{
                " status"        = "Disabled" ;
                " timeInMinutes" = 30
            }
        }
        else {
            $notificationsettings = @{
                " status"        = "Enabled" ;
                " timeInMinutes" = 30
            }
            # Add the Webhook URL if defined
            if ([string]::IsNullOrEmpty($WebhookUrl) -ne $true) { $notificationsettings.Add("WebhookUrl" , $WebhookUrl) }
            # Add the recipient email address if it is defined
            if ([string]::IsNullOrEmpty($Email) -ne $true) {
                $notificationsettings.Add(" emailRecipient" , $Email)
                $notificationsettings.Add(" notificationLocale" , "en" )
            }
        }
        # Construct the properties object
        $properties = @{
            " status"               = "Enabled" ;
            " taskType"             = "ComputeVmShutdownTask" ;
            " dailyRecurrence"      = @{" time" = (" {0:HHmm}" -f $Time) };
            " timeZoneId"           = $TimeZone;
            " notificationSettings" = $notificationsettings;
            " targetResourceId"     = $vm.Id
        }
    }
    elseif ($PsCmdlet.ParameterSetName -eq "PsDisable" ) {
        # Construct the properties object
        $properties = @{
            " status"               = "Disabled" ;
            " taskType"             = "ComputeVmShutdownTask" ;
            " dailyRecurrence"      = @{" time" = " 1900" };
            " timeZoneId"           = (Get-TimeZone).Id;
            " notificationSettings" = @{
                " status"        = "Disabled" ;
                " timeInMinutes" = 30
            };
            " targetResourceId"     = $vm.Id
        }
    }
    else {
        Write-Error -Message "Unable to determine auto-shutdown action. Use -Enable or -Disable as parameter."
        return
    }
    # Create the auto-shutdown resource
    try {
        $newAzResourceSplat = @{
            ResourceId  = (" /subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $ResourceGroupName, $Name)
            Location    = $vm.Location
            Properties  = $properties
            ApiVersion  = " 2017-04-26-preview"
            Force       = $true
            ErrorAction = 'SilentlyContinue'
        }
$output = New-AzResource -ErrorAction Stop @newAzResourceSplat
    }
    catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
    # Check if resource deployment threw an error
    if ($? -eq $true) {
        # OK, return deployment object
        return $output
    }
    else {
        # Write error
        Write-Error -Message #Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Set Azvmautoshutdown

.DESCRIPTION
    Set Azvmautoshutdown operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    .SYNOPSIS
        Sets the auto-shutdown property for a virtual machine hosted in Microsoft Azure.
    .DESCRIPTION
        The Set-AzVMAutoShutdown -ErrorAction Stop script set the auto-shutdown property for a virtual machine.
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
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time" -WebhookURL " https://myapp.azurewebsites.net/webhook"
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone. Notifications will be enabled and the WebhookURL will be set to " https://myapp.azurewebsites.net/webhook" .
    .EXAMPLE
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone "W. Europe Standard Time" -Email " alerts@mycompany.com"
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in "W. Europe Standard Time" time zone. Notifications will be enabled and sent to alerts@mycompany.com
    .EXAMPLE
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Disable
        Disables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001.
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
Name              : shutdown-computevm-Unifi1
ResourceId        : /subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/resourcegroups/inspireav_unifi_rg/providers/microsoft.devtestlab/schedul
                    es/shutdown-computevm-unifi1
ResourceName      : shutdown-computevm-unifi1
ResourceType      : microsoft.devtestlab/schedules
ResourceGroupName : inspireav_unifi_rg
Location          : canadacentral
SubscriptionId    : 408a6c03-bd25-471b-ae84-cf82b3dff420
Properties        : @{status=Enabled; taskType=ComputeVmShutdownTask; dailyRecurrence=; timeZoneId=Central Standard Time;
                    notificationSettings=; createdDate=2020-12-07T03:29:30.3481124+00:00; targetResourceId=/subscriptions/408a6c03-bd25-471b-ae8
                    4-cf82b3dff420/resourceGroups/InspireAV_UniFi_RG/providers/Microsoft.Compute/virtualMachines/Unifi1;
                    provisioningState=Succeeded; uniqueIdentifier=7666f555-4019-4e63-b2af-b17fcdfeedfc}
    General notes
[CmdletBinding()]
[OutputType([bool])]
 -ErrorAction Stop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
        [Parameter(ParameterSetName = "PsDisable" , Mandatory = $true)][switch]$Disable,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $true)][switch]$Enable,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $true)][DateTime]$Time,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $false)][string]$TimeZone = (Get-TimeZone -ErrorAction Stop | Select-Object -ExpandProperty Id),
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $false)][AllowEmptyString()][string]$WebhookUrl = "" ,
        [Parameter(ParameterSetName = "PsEnable" , Mandatory = $false)][string]$Email
    )
    # Check the loaded modules
    # $modules = @("Az.Compute" , "Az.Resources" , "Az.Profile" )
    # foreach ($module in $modules) {
    #     if ((Get-Module -Name $module) -eq $null) {
    #         Write-Error -Message "PowerShell module '$module' is not loaded" -RecommendedAction "Please download the Azure PowerShell command-line tools from https://azure.microsoft.com/en-us/downloads/"
    #         return
    #     }
    # }
    # # Check if currently logged-on to Azure
    # if ((Get-AzContext).Account -eq $null) {
    #     Write-Error -Message "No account found in the context. Please login using Login-AzAccount."
    #     return
    # }
    # Validate the set timezone
    if ((Get-TimeZone -ListAvailable | Select-Object -ExpandProperty Id) -notcontains $TimeZone) {
        Write-Error -Message "TimeZone $TimeZone is not valid"
        return
    }
    # Retrieve the VM from the defined resource group
    $vmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    ErrorAction = SilentlyContinue
}
Get-AzVm @vmSplat
    if ($null -eq $vm) {
        Write-Error -Message "Virtual machine '$Name' under resource group '$ResourceGroupName' was not found."
        return
    }
    # Check if Auto-Shutdown needs to be enabled or disabled
$properties = @{}
    if ($PsCmdlet.ParameterSetName -eq "PsEnable" ) {
        # Construct the notifications (only enable if webhook is enabled)
        if ([string]::IsNullOrEmpty($WebhookUrl) -and [string]::IsNullOrEmpty($Email)) {
$notificationsettings = @{
                " status"        = "Disabled" ;
                " timeInMinutes" = 30
            }
        }
        else {
            $notificationsettings = @{
                " status"        = "Enabled" ;
                " timeInMinutes" = 30
            }
            # Add the Webhook URL if defined
            if ([string]::IsNullOrEmpty($WebhookUrl) -ne $true) { $notificationsettings.Add("WebhookUrl" , $WebhookUrl) }
            # Add the recipient email address if it is defined
            if ([string]::IsNullOrEmpty($Email) -ne $true) {
                $notificationsettings.Add(" emailRecipient" , $Email)
                $notificationsettings.Add(" notificationLocale" , "en" )
            }
        }
        # Construct the properties object
        $properties = @{
            " status"               = "Enabled" ;
            " taskType"             = "ComputeVmShutdownTask" ;
            " dailyRecurrence"      = @{" time" = (" {0:HHmm}" -f $Time) };
            " timeZoneId"           = $TimeZone;
            " notificationSettings" = $notificationsettings;
            " targetResourceId"     = $vm.Id
        }
    }
    elseif ($PsCmdlet.ParameterSetName -eq "PsDisable" ) {
        # Construct the properties object
        $properties = @{
            " status"               = "Disabled" ;
            " taskType"             = "ComputeVmShutdownTask" ;
            " dailyRecurrence"      = @{" time" = " 1900" };
            " timeZoneId"           = (Get-TimeZone).Id;
            " notificationSettings" = @{
                " status"        = "Disabled" ;
                " timeInMinutes" = 30
            };
            " targetResourceId"     = $vm.Id
        }
    }
    else {
        Write-Error -Message "Unable to determine auto-shutdown action. Use -Enable or -Disable as parameter."
        return
    }
    # Create the auto-shutdown resource
    try {
        $newAzResourceSplat = @{
            ResourceId  = (" /subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $ResourceGroupName, $Name)
            Location    = $vm.Location
            Properties  = $properties
            ApiVersion  = " 2017-04-26-preview"
            Force       = $true
            ErrorAction = 'SilentlyContinue'
        }
$output = New-AzResource -ErrorAction Stop @newAzResourceSplat
    }
    catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
    # Check if resource deployment threw an error
    if ($? -eq $true) {
        # OK, return deployment object
        return $output
    }
    else {
        # Write error
        Write-Error -Message $Error[0].Exception.Message
    }
}

.Exception.Message.Exception.Message
    }
}


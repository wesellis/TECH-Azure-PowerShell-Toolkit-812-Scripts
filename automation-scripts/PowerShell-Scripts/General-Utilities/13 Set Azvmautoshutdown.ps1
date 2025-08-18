<#
.SYNOPSIS
    13 Set Azvmautoshutdown

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 13 Set Azvmautoshutdown

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<# 
    .SYNOPSIS 
        Sets the auto-shutdown property for a virtual machine hosted in Microsoft Azure. 
 
    .DESCRIPTION 
        The Set-AzVMAutoShutdown script set the auto-shutdown property for a virtual machine. 
 
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
 
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in " W. Europe Standard Time" time zone. 
 
    .EXAMPLE 
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone " W. Europe Standard Time" -WebhookURL " https://myapp.azurewebsites.net/webhook" 
 
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in " W. Europe Standard Time" time zone. Notifications will be enabled and the WebhookURL will be set to " https://myapp.azurewebsites.net/webhook" . 
 
    .EXAMPLE 
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Enable -Time 19:00 -TimeZone " W. Europe Standard Time" -Email " alerts@mycompany.com" 
 
        Enables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001 and sets the daily shutdown to take place at 19:00 in " W. Europe Standard Time" time zone. Notifications will be enabled and sent to alerts@mycompany.com 
 
    .EXAMPLE 
        Set-AzVMAutoShutdown -ResourceGroupName RG-WE-001 -Name MYVM001 -Disable 
 
        Disables auto-shutdown on virtual machine MYVM001 in resource group RG-WE-001. 



<#


$WEErrorActionPreference = " Stop" ; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
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

.NOTES
    General notes


function WE-Set-AzVMAutoShutdown {

    [CmdletBinding()]
$ErrorActionPreference = " Stop" 
    param(
        [Parameter(Mandatory = $true)][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName, 
        [Parameter(Mandatory = $true)][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEName, 
        [Parameter(ParameterSetName = " PsDisable" , Mandatory = $true)][switch]$WEDisable, 
        [Parameter(ParameterSetName = " PsEnable" , Mandatory = $true)][switch]$WEEnable, 
        [Parameter(ParameterSetName = " PsEnable" , Mandatory = $true)][DateTime]$WETime, 
        [Parameter(ParameterSetName = " PsEnable" , Mandatory = $false)][string]$WETimeZone = (Get-TimeZone | Select-Object -ExpandProperty Id), 
        [Parameter(ParameterSetName = " PsEnable" , Mandatory = $false)][AllowEmptyString()][string]$WEWebhookUrl = "" , 
        [Parameter(ParameterSetName = " PsEnable" , Mandatory = $false)][string]$WEEmail
    ) 
 
    # Check the loaded modules 
    # $modules = @(" Az.Compute" , " Az.Resources" , " Az.Profile" ) 
    # foreach ($module in $modules) { 
    #     if ((Get-Module -Name $module) -eq $null) { 
    #         Write-Error -Message " PowerShell module '$module' is not loaded" -RecommendedAction " Please download the Azure PowerShell command-line tools from https://azure.microsoft.com/en-us/downloads/" 
    #         return 
    #     } 
    # } 
 
    # # Check if currently logged-on to Azure 
    # if ((Get-AzContext).Account -eq $null) { 
    #     Write-Error -Message " No account found in the context. Please login using Login-AzAccount." 
    #     return 
    # } 
 
    # Validate the set timezone 
    if ((Get-TimeZone -ListAvailable | Select-Object -ExpandProperty Id) -notcontains $WETimeZone) { 
        Write-Error -Message " TimeZone $WETimeZone is not valid" 
        return 
    } 
 
    # Retrieve the VM from the defined resource group 
    $vm = Get-AzVm -ResourceGroupName $WEResourceGroupName -Name $WEName -ErrorAction SilentlyContinue 
    if ($null -eq $vm) { 
        Write-Error -Message " Virtual machine '$WEName' under resource group '$WEResourceGroupName' was not found." 
        return 
    } 
 
    # Check if Auto-Shutdown needs to be enabled or disabled 
   ;  $properties = @{} 
    if ($WEPsCmdlet.ParameterSetName -eq " PsEnable" ) { 
        # Construct the notifications (only enable if webhook is enabled) 
        if ([string]::IsNullOrEmpty($WEWebhookUrl) -and [string]::IsNullOrEmpty($WEEmail)) { 
           ;  $notificationsettings = @{ 
                " status"        = " Disabled" ; 
                " timeInMinutes" = 30 
            } 
        }
        else { 
            $notificationsettings = @{ 
                " status"        = " Enabled" ; 
                " timeInMinutes" = 30 
            } 
 
            # Add the Webhook URL if defined 
            if ([string]::IsNullOrEmpty($WEWebhookUrl) -ne $true) { $notificationsettings.Add(" WebhookUrl" , $WEWebhookUrl) } 
 
            # Add the recipient email address if it is defined 
            if ([string]::IsNullOrEmpty($WEEmail) -ne $true) {  
                $notificationsettings.Add(" emailRecipient" , $WEEmail) 
                $notificationsettings.Add(" notificationLocale" , " en" ) 
            } 
        } 
 
        # Construct the properties object 
        $properties = @{ 
            " status"               = " Enabled" ; 
            " taskType"             = " ComputeVmShutdownTask" ; 
            " dailyRecurrence"      = @{" time" = (" {0:HHmm}" -f $WETime) }; 
            " timeZoneId"           = $WETimeZone; 
            " notificationSettings" = $notificationsettings; 
            " targetResourceId"     = $vm.Id 
        } 
    }
    elseif ($WEPsCmdlet.ParameterSetName -eq " PsDisable" ) { 
        # Construct the properties object 
        $properties = @{ 
            " status"               = " Disabled" ; 
            " taskType"             = " ComputeVmShutdownTask" ; 
            " dailyRecurrence"      = @{" time" = " 1900" }; 
            " timeZoneId"           = (Get-TimeZone).Id; 
            " notificationSettings" = @{ 
                " status"        = " Disabled" ; 
                " timeInMinutes" = 30 
            }; 
            " targetResourceId"     = $vm.Id 
        } 
    }
    else { 
        Write-Error -Message " Unable to determine auto-shutdown action. Use -Enable or -Disable as parameter." 
        return 
    } 
 
    # Create the auto-shutdown resource 
    try { 
        $newAzResourceSplat = @{
            ResourceId  = (" /subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $WEResourceGroupName, $WEName)
            Location    = $vm.Location
            Properties  = $properties
            ApiVersion  = " 2017-04-26-preview"
            Force       = $true
            ErrorAction = 'SilentlyContinue'
        }

       ;  $output = New-AzResource @newAzResourceSplat 
    }
    catch {} 
 
    # Check if resource deployment threw an error 
    if ($? -eq $true) { 
        # OK, return deployment object 
        return $output 
    }
    else { 
        # Write error 
        Write-Error -Message $WEError[0].Exception.Message 
    }

}







# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
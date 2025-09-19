#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Vm Autoshutdown Configurator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Vm Autoshutdown Configurator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVmName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEShutdownTime,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETimeZone,
    
    [Parameter(Mandatory=$false)]
    [string]$WENotificationEmail
)

#region Functions

Write-WELog " Configuring auto-shutdown for VM: $WEVmName" " INFO"
; 
$WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVmName
; 
$WEProperties = @{
    status = " Enabled"
    taskType = " ComputeVmShutdownTask"
    dailyRecurrence = @{
        time = $WEShutdownTime
    }
    timeZoneId = $WETimeZone
    targetResourceId = $WEVM.Id
}

if ($WENotificationEmail) {
    $WEProperties.notificationSettings = @{
        status = " Enabled"
        timeInMinutes = 30
        emailRecipient = $WENotificationEmail
    }
}

$params = @{
    f = "(Get-AzContext).Subscription.Id, $WEResourceGroupName, $WEVmName)"
    ErrorAction = "Stop"
    Properties = $WEProperties
    ResourceId = "(" /subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}"
}
New-AzResource @params

Write-WELog "  Auto-shutdown configured successfully:" " INFO"
Write-WELog "  VM: $WEVmName" " INFO"
Write-WELog "  Shutdown Time: $WEShutdownTime" " INFO"
Write-WELog "  Time Zone: $WETimeZone" " INFO"
if ($WENotificationEmail) {
    Write-WELog "  Notification Email: $WENotificationEmail" " INFO"
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

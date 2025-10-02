#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Health Monitor

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
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$VmName
)
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status
Write-Output "VM Name: $($VM.Name)"
Write-Output "Resource Group: $($VM.ResourceGroupName)"
Write-Output "Location: $($VM.Location)"
Write-Output "Power State: $($VM.PowerState)"
Write-Output "Provisioning State: $($VM.ProvisioningState)"
foreach ($Status in $VM.Statuses) {
    Write-Output "Status: $($Status.Code) - $($Status.DisplayStatus)"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

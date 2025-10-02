#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm List All

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
    [Parameter(ValueFromPipeline)]`n    [string]$SubscriptionId
)
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
    Write-Information -Object "Connected to subscription: $SubscriptionId"
}
Write-Information -Object "Retrieving all VMs across subscription..."
$VMs = Get-AzVM -Status
Write-Information -Object " `nFound $($VMs.Count) Virtual Machines:"
Write-Information -Object (" =" * 60)
foreach ($VM in $VMs) {
    Write-Information -Object "VM: $($VM.Name) | RG: $($VM.ResourceGroupName) | State: $($VM.PowerState) | Size: $($VM.HardwareProfile.VmSize)"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

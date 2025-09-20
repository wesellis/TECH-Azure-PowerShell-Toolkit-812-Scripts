<#
.SYNOPSIS
    Azure Vm List All

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
[CmdletBinding()];
param(
    [Parameter()]
    [string]$SubscriptionId
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
    throw
}\n
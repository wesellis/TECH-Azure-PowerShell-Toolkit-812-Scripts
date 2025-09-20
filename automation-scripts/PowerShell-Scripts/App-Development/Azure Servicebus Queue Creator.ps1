<#
.SYNOPSIS
    Azure Servicebus Queue Creator

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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NamespaceName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$QueueName,
    [Parameter()]
    [int]$MaxSizeInMegabytes = 1024
)
Write-Host "Creating Service Bus queue: $QueueName"
$params = @{
    ErrorAction = "Stop"
    MaxSizeInMegabytes = $MaxSizeInMegabytes
    ResourceGroupName = $ResourceGroupName
    NamespaceName = $NamespaceName
    Name = $QueueName
}
$Queue @params
Write-Host "Queue created successfully:"
Write-Host "Name: $($Queue.Name)"
Write-Host "Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Host "Status: $($Queue.Status)"
Write-Host "Namespace: $NamespaceName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n
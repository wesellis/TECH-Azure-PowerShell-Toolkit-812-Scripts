#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Servicebus Queue Creator

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
Write-Output "Creating Service Bus queue: $QueueName"
$params = @{
    ErrorAction = "Stop"
    MaxSizeInMegabytes = $MaxSizeInMegabytes
    ResourceGroupName = $ResourceGroupName
    NamespaceName = $NamespaceName
    Name = $QueueName
}
    [string]$Queue @params
Write-Output "Queue created successfully:"
Write-Output "Name: $($Queue.Name)"
Write-Output "Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Output "Status: $($Queue.Status)"
Write-Output "Namespace: $NamespaceName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

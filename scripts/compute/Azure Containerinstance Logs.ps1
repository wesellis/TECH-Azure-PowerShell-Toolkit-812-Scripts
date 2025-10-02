#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Containerinstance Logs

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
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerName,
    [Parameter()]
    [int]$Tail = 50
)
Write-Information -Object "Retrieving logs for container group: $ContainerGroupName"
if ($ContainerName) {
    $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -ContainerName $ContainerName -Tail $Tail
} else {
    $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -Tail $Tail
}
Write-Information -Object " `nContainer Logs (Last $Tail lines):"
Write-Information -Object (" =" * 50)
Write-Information -Object $Logs
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

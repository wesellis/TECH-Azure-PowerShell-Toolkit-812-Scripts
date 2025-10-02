#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Aks Node Restart Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AksClusterName,
    [string]$NodeName
)
Write-Output "Restarting AKS Node: $NodeName"
Write-Output "Cluster: $AksClusterName"
Write-Output "Resource Group: $ResourceGroupName"
    $AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
Write-Output "Cluster Status: $($AksCluster.ProvisioningState)"
Write-Output "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Output "Warning: Node restart requires kubectl access to the cluster"
Write-Output "Use: kubectl drain $NodeName --ignore-daemonsets --delete-emptydir-data"
Write-Output "Then: kubectl uncordon $NodeName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

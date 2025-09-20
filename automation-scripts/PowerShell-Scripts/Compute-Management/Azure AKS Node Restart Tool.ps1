<#
.SYNOPSIS
    Azure Aks Node Restart Tool

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
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AksClusterName,
    [string]$NodeName
)
Write-Host "Restarting AKS Node: $NodeName"
Write-Host "Cluster: $AksClusterName"
Write-Host "Resource Group: $ResourceGroupName"
$AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
Write-Host "Cluster Status: $($AksCluster.ProvisioningState)"
Write-Host "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Host "Warning: Node restart requires kubectl access to the cluster"
Write-Host "Use: kubectl drain $NodeName --ignore-daemonsets --delete-emptydir-data"
Write-Host "Then: kubectl uncordon $NodeName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n
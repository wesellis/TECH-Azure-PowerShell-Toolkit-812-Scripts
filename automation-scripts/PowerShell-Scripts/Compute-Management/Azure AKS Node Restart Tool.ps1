<#
.SYNOPSIS
    Azure Aks Node Restart Tool

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
    We Enhanced Azure Aks Node Restart Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAksClusterName,
    [string]$WENodeName
)

Write-WELog " Restarting AKS Node: $WENodeName" " INFO"
Write-WELog " Cluster: $WEAksClusterName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"

; 
$WEAksCluster = Get-AzAksCluster -ResourceGroupName $WEResourceGroupName -Name $WEAksClusterName

Write-WELog " Cluster Status: $($WEAksCluster.ProvisioningState)" " INFO"
Write-WELog " Kubernetes Version: $($WEAksCluster.KubernetesVersion)" " INFO"


Write-WELog " Warning: Node restart requires kubectl access to the cluster" " INFO"
Write-WELog " Use: kubectl drain $WENodeName --ignore-daemonsets --delete-emptydir-data" " INFO"
Write-WELog " Then: kubectl uncordon $WENodeName" " INFO"






} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

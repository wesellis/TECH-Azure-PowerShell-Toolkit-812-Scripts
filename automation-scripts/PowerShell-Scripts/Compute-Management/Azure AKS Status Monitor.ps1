<#
.SYNOPSIS
    Azure Aks Status Monitor

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
    We Enhanced Azure Aks Status Monitor

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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEClusterName
)

Write-WELog " Monitoring AKS Cluster: $WEClusterName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"

; 
$WEAksCluster = Get-AzAksCluster -ResourceGroupName $WEResourceGroupName -Name $WEClusterName

Write-WELog " Cluster Information:" " INFO"
Write-WELog "  Name: $($WEAksCluster.Name)" " INFO"
Write-WELog "  Location: $($WEAksCluster.Location)" " INFO"
Write-WELog "  Kubernetes Version: $($WEAksCluster.KubernetesVersion)" " INFO"
Write-WELog "  Provisioning State: $($WEAksCluster.ProvisioningState)" " INFO"
Write-WELog "  Power State: $($WEAksCluster.PowerState.Code)" " INFO"
Write-WELog "  DNS Prefix: $($WEAksCluster.DnsPrefix)" " INFO"
Write-WELog "  FQDN: $($WEAksCluster.Fqdn)" " INFO"


Write-WELog " `nNode Pool Information:" " INFO"
foreach ($WENodePool in $WEAksCluster.AgentPoolProfiles) {
    Write-WELog "  Pool Name: $($WENodePool.Name)" " INFO"
    Write-WELog "  VM Size: $($WENodePool.VmSize)" " INFO"
    Write-WELog "  Node Count: $($WENodePool.Count)" " INFO"
    Write-WELog "  OS Type: $($WENodePool.OsType)" " INFO"
    Write-WELog "  Provisioning State: $($WENodePool.ProvisioningState)" " INFO"
    Write-WELog "  ---" " INFO"
}

Write-WELog " `nCluster monitoring completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}

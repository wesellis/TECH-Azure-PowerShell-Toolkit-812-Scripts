#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Aks Status Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
    [string]$ClusterName
)
Write-Host "Monitoring AKS Cluster: $ClusterName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host " ============================================"
$AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $ClusterName
Write-Host "Cluster Information:"
Write-Host "Name: $($AksCluster.Name)"
Write-Host "Location: $($AksCluster.Location)"
Write-Host "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Host "Provisioning State: $($AksCluster.ProvisioningState)"
Write-Host "Power State: $($AksCluster.PowerState.Code)"
Write-Host "DNS Prefix: $($AksCluster.DnsPrefix)"
Write-Host "FQDN: $($AksCluster.Fqdn)"
Write-Host " `nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Host "Pool Name: $($NodePool.Name)"
    Write-Host "VM Size: $($NodePool.VmSize)"
    Write-Host "Node Count: $($NodePool.Count)"
    Write-Host "OS Type: $($NodePool.OsType)"
    Write-Host "Provisioning State: $($NodePool.ProvisioningState)"
    Write-Host "  ---"
}
Write-Host " `nCluster monitoring completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}



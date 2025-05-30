# ============================================================================
# Script Name: Azure Kubernetes Service Status Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Kubernetes Service cluster health, node status, and performance metrics
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ClusterName
)

Write-Host "Monitoring AKS Cluster: $ClusterName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get AKS cluster details
$AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $ClusterName

Write-Host "Cluster Information:"
Write-Host "  Name: $($AksCluster.Name)"
Write-Host "  Location: $($AksCluster.Location)"
Write-Host "  Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Host "  Provisioning State: $($AksCluster.ProvisioningState)"
Write-Host "  Power State: $($AksCluster.PowerState.Code)"
Write-Host "  DNS Prefix: $($AksCluster.DnsPrefix)"
Write-Host "  FQDN: $($AksCluster.Fqdn)"

# Get node pool information
Write-Host "`nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Host "  Pool Name: $($NodePool.Name)"
    Write-Host "  VM Size: $($NodePool.VmSize)"
    Write-Host "  Node Count: $($NodePool.Count)"
    Write-Host "  OS Type: $($NodePool.OsType)"
    Write-Host "  Provisioning State: $($NodePool.ProvisioningState)"
    Write-Host "  ---"
}

Write-Host "`nCluster monitoring completed at $(Get-Date)"

# ============================================================================
# Script Name: Azure Kubernetes Service Cluster Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Kubernetes Service clusters with node pools and networking
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AksClusterName,
    [int]$NodeCount = 3,
    [string]$Location,
    [string]$NodeVmSize = "Standard_DS2_v2",
    [string]$KubernetesVersion = "1.28.0",
    [string]$NetworkPlugin = "azure",
    [bool]$EnableRBAC = $true,
    [bool]$EnableManagedIdentity = $true
)

Write-Host "Provisioning AKS Cluster: $AksClusterName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Node Count: $NodeCount"
Write-Host "Node VM Size: $NodeVmSize"
Write-Host "Kubernetes Version: $KubernetesVersion"
Write-Host "Network Plugin: $NetworkPlugin"
Write-Host "RBAC Enabled: $EnableRBAC"

# Create the AKS cluster
Write-Host "`nCreating AKS cluster (this may take 10-15 minutes)..."
$AksCluster = New-AzAksCluster `
    -ResourceGroupName $ResourceGroupName `
    -Name $AksClusterName `
    -NodeCount $NodeCount `
    -Location $Location `
    -NodeVmSize $NodeVmSize `
    -KubernetesVersion $KubernetesVersion `
    -NetworkPlugin $NetworkPlugin `
    -EnableRBAC:$EnableRBAC `
    -EnableManagedIdentity:$EnableManagedIdentity

Write-Host "`nAKS Cluster $AksClusterName provisioned successfully!"
Write-Host "Cluster FQDN: $($AksCluster.Fqdn)"
Write-Host "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Host "Provisioning State: $($AksCluster.ProvisioningState)"
Write-Host "Power State: $($AksCluster.PowerState.Code)"

# Display node pool information
Write-Host "`nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Host "  Pool Name: $($NodePool.Name)"
    Write-Host "  VM Size: $($NodePool.VmSize)"
    Write-Host "  Node Count: $($NodePool.Count)"
    Write-Host "  OS Type: $($NodePool.OsType)"
    Write-Host "  OS Disk Size: $($NodePool.OsDiskSizeGB) GB"
}

Write-Host "`nNext Steps:"
Write-Host "1. Install kubectl: az aks install-cli"
Write-Host "2. Get credentials: az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName"
Write-Host "3. Verify connection: kubectl get nodes"

Write-Host "`nAKS Cluster provisioning completed at $(Get-Date)"

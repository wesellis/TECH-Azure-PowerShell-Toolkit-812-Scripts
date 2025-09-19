#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
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

#region Functions

Write-Information "Provisioning AKS Cluster: $AksClusterName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Node Count: $NodeCount"
Write-Information "Node VM Size: $NodeVmSize"
Write-Information "Kubernetes Version: $KubernetesVersion"
Write-Information "Network Plugin: $NetworkPlugin"
Write-Information "RBAC Enabled: $EnableRBAC"

# Create the AKS cluster
Write-Information "`nCreating AKS cluster (this may take 10-15 minutes)..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    NodeVmSize = $NodeVmSize
    NodeCount = $NodeCount
    Location = $Location
    NetworkPlugin = $NetworkPlugin
    ErrorAction = "Stop"
    KubernetesVersion = $KubernetesVersion
    Name = $AksClusterName
}
$AksCluster @params

Write-Information "`nAKS Cluster $AksClusterName provisioned successfully!"
Write-Information "Cluster FQDN: $($AksCluster.Fqdn)"
Write-Information "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Information "Provisioning State: $($AksCluster.ProvisioningState)"
Write-Information "Power State: $($AksCluster.PowerState.Code)"

# Display node pool information
Write-Information "`nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Information "  Pool Name: $($NodePool.Name)"
    Write-Information "  VM Size: $($NodePool.VmSize)"
    Write-Information "  Node Count: $($NodePool.Count)"
    Write-Information "  OS Type: $($NodePool.OsType)"
    Write-Information "  OS Disk Size: $($NodePool.OsDiskSizeGB) GB"
}

Write-Information "`nNext Steps:"
Write-Information "1. Install kubectl: az aks install-cli"
Write-Information "2. Get credentials: az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName"
Write-Information "3. Verify connection: kubectl get nodes"

Write-Information "`nAKS Cluster provisioning completed at $(Get-Date)"


#endregion

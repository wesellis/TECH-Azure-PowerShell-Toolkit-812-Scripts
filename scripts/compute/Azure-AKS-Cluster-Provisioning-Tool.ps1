#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Aks

<#`n.SYNOPSIS
    Manage AKS clusters

.DESCRIPTION
    Manage AKS clusters


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

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
Write-Output "Provisioning AKS Cluster: $AksClusterName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Node Count: $NodeCount"
Write-Output "Node VM Size: $NodeVmSize"
Write-Output "Kubernetes Version: $KubernetesVersion"
Write-Output "Network Plugin: $NetworkPlugin"
Write-Output "RBAC Enabled: $EnableRBAC"
Write-Output "`nCreating AKS cluster (this may take 10-15 minutes)..."
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
$AksCluster = New-AzAksCluster @params
Write-Output "`nAKS Cluster $AksClusterName provisioned successfully!"
Write-Output "Cluster FQDN: $($AksCluster.Fqdn)"
Write-Output "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Output "Provisioning State: $($AksCluster.ProvisioningState)"
Write-Output "Power State: $($AksCluster.PowerState.Code)"
Write-Output "`nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Output "Pool Name: $($NodePool.Name)"
    Write-Output "VM Size: $($NodePool.VmSize)"
    Write-Output "Node Count: $($NodePool.Count)"
    Write-Output "OS Type: $($NodePool.OsType)"
    Write-Output "OS Disk Size: $($NodePool.OsDiskSizeGB) GB"
}
Write-Output "`nNext Steps:"
Write-Output "1. Install kubectl: az aks install-cli"
Write-Output "2. Get credentials: az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName"
Write-Output "3. Verify connection: kubectl get nodes"
Write-Output "`nAKS Cluster provisioning completed at $(Get-Date)"




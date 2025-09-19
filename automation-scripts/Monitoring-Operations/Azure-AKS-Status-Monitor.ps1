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
    [string]$ClusterName
)

#region Functions

Write-Information "Monitoring AKS Cluster: $ClusterName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get AKS cluster details
$AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $ClusterName

Write-Information "Cluster Information:"
Write-Information "  Name: $($AksCluster.Name)"
Write-Information "  Location: $($AksCluster.Location)"
Write-Information "  Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Information "  Provisioning State: $($AksCluster.ProvisioningState)"
Write-Information "  Power State: $($AksCluster.PowerState.Code)"
Write-Information "  DNS Prefix: $($AksCluster.DnsPrefix)"
Write-Information "  FQDN: $($AksCluster.Fqdn)"

# Get node pool information
Write-Information "`nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Information "  Pool Name: $($NodePool.Name)"
    Write-Information "  VM Size: $($NodePool.VmSize)"
    Write-Information "  Node Count: $($NodePool.Count)"
    Write-Information "  OS Type: $($NodePool.OsType)"
    Write-Information "  Provisioning State: $($NodePool.ProvisioningState)"
    Write-Information "  ---"
}

Write-Information "`nCluster monitoring completed at $(Get-Date)"


#endregion

# ============================================================================
# Script Name: Azure AKS Credentials Configurator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Configures kubectl credentials for Azure Kubernetes Service cluster
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [switch]$Admin
)

Write-Host "Configuring kubectl credentials for AKS cluster: $ClusterName"

if ($Admin) {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Admin -Force
    Write-Host "Admin credentials configured for cluster: $ClusterName"
} else {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Force
    Write-Host "User credentials configured for cluster: $ClusterName"
}

Write-Host "`nTesting connection..."
kubectl get nodes
Write-Host "`nKubectl is now configured for cluster: $ClusterName"

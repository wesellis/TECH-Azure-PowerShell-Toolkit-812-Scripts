#Requires -Version 7.0
#Requires -Modules Az.Aks

<#`n.SYNOPSIS
    Manage AKS clusters

.DESCRIPTION
    Manage AKS clusters


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ClusterName,
    [Parameter()]
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



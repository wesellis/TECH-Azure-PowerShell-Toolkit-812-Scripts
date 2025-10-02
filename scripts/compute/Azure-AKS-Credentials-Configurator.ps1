#Requires -Version 7.4
#Requires -Modules Az.Aks

<#`n.SYNOPSIS
    Manage AKS clusters

.DESCRIPTION
    Manage AKS clusters


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ClusterName,
    [Parameter()]
    [switch]$Admin
)
Write-Output "Configuring kubectl credentials for AKS cluster: $ClusterName"
if ($Admin) {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Admin -Force
    Write-Output "Admin credentials configured for cluster: $ClusterName"
} else {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Force
    Write-Output "User credentials configured for cluster: $ClusterName"
}
Write-Output "`nTesting connection..."
kubectl get nodes
Write-Output "`nKubectl is now configured for cluster: $ClusterName"




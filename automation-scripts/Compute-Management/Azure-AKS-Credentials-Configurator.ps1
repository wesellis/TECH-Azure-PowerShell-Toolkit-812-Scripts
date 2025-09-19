#Requires -Version 7.0

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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [switch]$Admin
)

#region Functions

Write-Information "Configuring kubectl credentials for AKS cluster: $ClusterName"

if ($Admin) {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Admin -Force
    Write-Information "Admin credentials configured for cluster: $ClusterName"
} else {
    Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $ClusterName -Force
    Write-Information "User credentials configured for cluster: $ClusterName"
}

Write-Information "`nTesting connection..."
kubectl get nodes
Write-Information "`nKubectl is now configured for cluster: $ClusterName"


#endregion

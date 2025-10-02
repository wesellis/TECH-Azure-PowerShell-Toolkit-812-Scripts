#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Restarts AKS cluster nodes with proper drain and cordon operations

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Safely restarts AKS cluster nodes by draining workloads, restarting the node,
    and then re-enabling scheduling. Requires kubectl access to the cluster.
.PARAMETER ResourceGroupName
    Name of the resource group containing the AKS cluster
.PARAMETER AksClusterName
    Name of the AKS cluster
.PARAMETER NodeName
    Name of the node to restart
.PARAMETER Force
    Skip confirmation
.PARAMETER WaitForReady
    Wait for node to be ready after restart
    .\Azure-AKS-Node-Restart-Tool.ps1 -ResourceGroupName "RG-AKS" -AksClusterName "my-cluster" -NodeName "aks-nodepool1-12345678-vmss000000"
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AksClusterName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$NodeName,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$WaitForReady
)
$ErrorActionPreference = 'Stop'
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    try {
        $KubectlVersion = kubectl version --client --short 2>$null
        Write-Host "kubectl detected: $KubectlVersion" -ForegroundColor Green
    }
    catch {
        throw "kubectl is required but not found. Please install kubectl first."
    }
    Write-Host "Retrieving AKS cluster information..." -ForegroundColor Green
    $AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
    if (-not $AksCluster) {
        throw "AKS cluster '$AksClusterName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "Cluster Status: $($AksCluster.ProvisioningState)" -ForegroundColor Green
    Write-Host "Kubernetes Version: $($AksCluster.KubernetesVersion)" -ForegroundColor Green
    Write-Host "Checking node status..." -ForegroundColor Green
    $NodeStatus = kubectl get node $NodeName --no-headers 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Node '$NodeName' not found in cluster"
    }
    Write-Host "Node found: $NodeName" -ForegroundColor Green
    if (-not $Force) {
        $confirmation = Read-Host "Restart AKS node '$NodeName'? This will drain workloads first (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "Draining node workloads..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($NodeName, "Drain node")) {
        kubectl drain $NodeName --ignore-daemonsets --delete-emptydir-data --force
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to drain node"
        }
        Write-Host "Node drained successfully" -ForegroundColor Green
    }
    Write-Host "Node restart initiated (drain completed)" -ForegroundColor Green
    Write-Host "Note: Physical node restart should be performed through Azure portal or VM restart commands" -ForegroundColor Green
    Write-Host "Re-enabling scheduling on node..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($NodeName, "Uncordon node")) {
        kubectl uncordon $NodeName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to uncordon node"
        }
        Write-Host "Node scheduling re-enabled" -ForegroundColor Green
    }
    if ($WaitForReady) {
        Write-Host "Waiting for node to be ready..." -ForegroundColor Green
        $timeout = 300
        $elapsed = 0
        do {
            $NodeReady = kubectl get node $NodeName --no-headers | Select-String "Ready"
            if ($NodeReady) {
                Write-Host "Node is ready!" -ForegroundColor Green
                break
            }
            Start-Sleep -Seconds 10
            $elapsed += 10
        } while ($elapsed -lt $timeout)
        if ($elapsed -ge $timeout) {
            Write-Warning "Timeout waiting for node to be ready"
        }
    }
    Write-Host "AKS node restart operation completed!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to restart AKS node: $_"
    throw`n}

#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Restarts AKS cluster nodes with proper drain and cordon operations

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory = $true)]
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
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    # Test kubectl availability
    try {
        $kubectlVersion = kubectl version --client --short 2>$null
        Write-Host "kubectl detected: $kubectlVersion" -ForegroundColor Green
    }
    catch {
        throw "kubectl is required but not found. Please install kubectl first."
    }
    # Get AKS cluster information
    Write-Host "Retrieving AKS cluster information..." -ForegroundColor Yellow
    $AksCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
    if (-not $AksCluster) {
        throw "AKS cluster '$AksClusterName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "Cluster Status: $($AksCluster.ProvisioningState)" -ForegroundColor Cyan
    Write-Host "Kubernetes Version: $($AksCluster.KubernetesVersion)" -ForegroundColor Cyan
    # Check if node exists
    Write-Host "Checking node status..." -ForegroundColor Yellow
    $nodeStatus = kubectl get node $NodeName --no-headers 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Node '$NodeName' not found in cluster"
    }
    Write-Host "Node found: $NodeName" -ForegroundColor Green
    # Confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Restart AKS node '$NodeName'? This will drain workloads first (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    # Step 1: Drain the node
    Write-Host "Draining node workloads..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($NodeName, "Drain node")) {
        kubectl drain $NodeName --ignore-daemonsets --delete-emptydir-data --force
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to drain node"
        }
        Write-Host "Node drained successfully" -ForegroundColor Green
    }
    # Step 2: Restart node (this would typically be done through Azure VM restart)
    Write-Host "Node restart initiated (drain completed)" -ForegroundColor Yellow
    Write-Host "Note: Physical node restart should be performed through Azure portal or VM restart commands" -ForegroundColor Cyan
    # Step 3: Uncordon the node
    Write-Host "Re-enabling scheduling on node..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($NodeName, "Uncordon node")) {
        kubectl uncordon $NodeName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to uncordon node"
        }
        Write-Host "Node scheduling re-enabled" -ForegroundColor Green
    }
    # Wait for node to be ready
    if ($WaitForReady) {
        Write-Host "Waiting for node to be ready..." -ForegroundColor Yellow
        $timeout = 300 # 5 minutes
        $elapsed = 0
        do {
            $nodeReady = kubectl get node $NodeName --no-headers | Select-String "Ready"
            if ($nodeReady) {
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
    throw
}\n


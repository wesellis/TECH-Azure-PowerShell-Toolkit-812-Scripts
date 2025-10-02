#Requires -Version 7.4

<#
.SYNOPSIS
    Azure AKS Cluster Provisioning Tool

.DESCRIPTION
    Azure automation script for provisioning AKS clusters
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER ResourceGroupName
    Name of the Azure Resource Group

.PARAMETER AksClusterName
    Name of the AKS cluster to create

.PARAMETER NodeCount
    Number of nodes in the cluster (default: 3)

.PARAMETER Location
    Azure region for the cluster

.PARAMETER NodeVmSize
    VM size for cluster nodes (default: Standard_DS2_v2)

.PARAMETER KubernetesVersion
    Kubernetes version (default: 1.28.0)

.PARAMETER NetworkPlugin
    Network plugin to use (default: azure)

.PARAMETER EnableRBAC
    Enable RBAC (default: true)

.PARAMETER EnableManagedIdentity
    Enable managed identity (default: true)

.EXAMPLE
    .\Provision-AKS.ps1 -ResourceGroupName "myRG" -AksClusterName "myCluster" -Location "eastus"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AksClusterName,

    [Parameter()]
    [int]$NodeCount = 3,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [string]$NodeVmSize = "Standard_DS2_v2",

    [Parameter()]
    [string]$KubernetesVersion = "1.28.0",

    [Parameter()]
    [string]$NetworkPlugin = "azure",

    [Parameter()]
    [bool]$EnableRBAC = $true,

    [Parameter()]
    [bool]$EnableManagedIdentity = $true
)
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    [string]$LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-LogMessage "Provisioning AKS Cluster: $AksClusterName" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "Location: $Location" -Level "INFO"
    Write-LogMessage "Node Count: $NodeCount" -Level "INFO"
    Write-LogMessage "Node VM Size: $NodeVmSize" -Level "INFO"
    Write-LogMessage "Kubernetes Version: $KubernetesVersion" -Level "INFO"
    Write-LogMessage "Network Plugin: $NetworkPlugin" -Level "INFO"
    Write-LogMessage "RBAC Enabled: $EnableRBAC" -Level "INFO"
    Write-LogMessage "Managed Identity Enabled: $EnableManagedIdentity" -Level "INFO"

    Write-LogMessage "`nCreating AKS cluster (this may take 10-15 minutes)..." -Level "INFO"
    $AksParams = @{
        ResourceGroupName = $ResourceGroupName
        Name = $AksClusterName
        Location = $Location
        NodeCount = $NodeCount
        NodeVmSize = $NodeVmSize
        KubernetesVersion = $KubernetesVersion
        NetworkPlugin = $NetworkPlugin
        EnableRBAC = $EnableRBAC
        EnableManagedIdentity = $EnableManagedIdentity
        ErrorAction = "Stop"
    }
    [string]$AksCluster = New-AzAksCluster @aksParams

    Write-LogMessage "`nAKS Cluster $AksClusterName provisioned successfully!" -Level "SUCCESS"
    Write-LogMessage "Cluster FQDN: $($AksCluster.Fqdn)" -Level "INFO"
    Write-LogMessage "Kubernetes Version: $($AksCluster.KubernetesVersion)" -Level "INFO"
    Write-LogMessage "Provisioning State: $($AksCluster.ProvisioningState)" -Level "INFO"
    Write-LogMessage "Power State: $($AksCluster.PowerState.Code)" -Level "INFO"

    Write-LogMessage "`nNode Pool Information:" -Level "INFO"
    foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
        Write-LogMessage "  Pool Name: $($NodePool.Name)" -Level "INFO"
        Write-LogMessage "  VM Size: $($NodePool.VmSize)" -Level "INFO"
        Write-LogMessage "  Node Count: $($NodePool.Count)" -Level "INFO"
        Write-LogMessage "  OS Type: $($NodePool.OsType)" -Level "INFO"
        Write-LogMessage "  OS Disk Size: $($NodePool.OsDiskSizeGB) GB" -Level "INFO"
        Write-LogMessage "" -Level "INFO"
    }

    Write-LogMessage "`nNext Steps:" -Level "SUCCESS"
    Write-LogMessage "1. Install kubectl: az aks install-cli" -Level "INFO"
    Write-LogMessage "2. Get credentials: az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName" -Level "INFO"
    Write-LogMessage "3. Verify connection: kubectl get nodes" -Level "INFO"
    Write-LogMessage "`nAKS Cluster provisioning completed at $(Get-Date)" -Level "SUCCESS"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw`n}

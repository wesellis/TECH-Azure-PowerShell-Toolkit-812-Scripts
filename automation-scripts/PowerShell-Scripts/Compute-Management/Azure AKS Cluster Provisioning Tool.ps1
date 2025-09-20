<#
.SYNOPSIS
    Azure Aks Cluster Provisioning Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AksClusterName,
    [int]$NodeCount = 3,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$NodeVmSize = "Standard_DS2_v2" ,
    [string]$KubernetesVersion = " 1.28.0" ,
    [string]$NetworkPlugin = " azure" ,
    [bool]$EnableRBAC = $true,
    [bool]$EnableManagedIdentity = $true
)
Write-Host "Provisioning AKS Cluster: $AksClusterName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Node Count: $NodeCount"
Write-Host "Node VM Size: $NodeVmSize"
Write-Host "Kubernetes Version: $KubernetesVersion"
Write-Host "Network Plugin: $NetworkPlugin"
Write-Host "RBAC Enabled: $EnableRBAC"
Write-Host " `nCreating AKS cluster (this may take 10-15 minutes)..." ;
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
Write-Host " `nAKS Cluster $AksClusterName provisioned successfully!"
Write-Host "Cluster FQDN: $($AksCluster.Fqdn)"
Write-Host "Kubernetes Version: $($AksCluster.KubernetesVersion)"
Write-Host "Provisioning State: $($AksCluster.ProvisioningState)"
Write-Host "Power State: $($AksCluster.PowerState.Code)"
Write-Host " `nNode Pool Information:"
foreach ($NodePool in $AksCluster.AgentPoolProfiles) {
    Write-Host "Pool Name: $($NodePool.Name)"
    Write-Host "VM Size: $($NodePool.VmSize)"
    Write-Host "Node Count: $($NodePool.Count)"
    Write-Host "OS Type: $($NodePool.OsType)"
    Write-Host "OS Disk Size: $($NodePool.OsDiskSizeGB) GB"
}
Write-Host " `nNext Steps:"
Write-Host " 1. Install kubectl: az aks install-cli"
Write-Host " 2. Get credentials: az aks get-credentials --resource-group $ResourceGroupName --name $AksClusterName"
Write-Host " 3. Verify connection: kubectl get nodes"
Write-Host " `nAKS Cluster provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n
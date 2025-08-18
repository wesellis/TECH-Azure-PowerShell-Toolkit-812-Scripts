# ============================================================================
# Script Name: Azure Container Instance Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Container Instances for serverless container deployments
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ContainerGroupName,
    [string]$Image,
    [string]$Location,
    [string]$OsType = "Linux",
    [double]$Cpu = 1.0,
    [double]$Memory = 1.5,
    [array]$Ports = @(80),
    [hashtable]$EnvironmentVariables = @{},
    [string]$RestartPolicy = "Always"
)

Write-Information "Provisioning Container Instance: $ContainerGroupName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Container Image: $Image"
Write-Information "OS Type: $OsType"
Write-Information "CPU: $Cpu cores"
Write-Information "Memory: $Memory GB"
Write-Information "Ports: $($Ports -join ', ')"
Write-Information "Restart Policy: $RestartPolicy"

# Create port objects
$PortObjects = @()
foreach ($Port in $Ports) {
    $PortObjects += New-AzContainerInstancePortObject -Port $Port -Protocol TCP
}

# Create environment variable objects
$EnvVarObjects = @()
if ($EnvironmentVariables.Count -gt 0) {
    Write-Information "`nEnvironment Variables:"
    foreach ($EnvVar in $EnvironmentVariables.GetEnumerator()) {
        Write-Information "  $($EnvVar.Key): $($EnvVar.Value)"
        $EnvVarObjects += New-AzContainerInstanceEnvironmentVariableObject -Name $EnvVar.Key -Value $EnvVar.Value
    }
}

# Create container object
$Container = New-AzContainerInstanceObject -ErrorAction Stop `
    -Name $ContainerGroupName `
    -Image $Image `
    -RequestCpu $Cpu `
    -RequestMemoryInGb $Memory `
    -Port $PortObjects

if ($EnvVarObjects.Count -gt 0) {
    $Container.EnvironmentVariable = $EnvVarObjects
}

# Create the Container Instance
Write-Information "`nCreating Container Instance..."
$ContainerGroup = New-AzContainerGroup -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName `
    -Location $Location `
    -Container $Container `
    -OsType $OsType `
    -RestartPolicy $RestartPolicy `
    -IpAddressType Public

Write-Information "`nContainer Instance $ContainerGroupName provisioned successfully"
Write-Information "Public IP Address: $($ContainerGroup.IpAddress)"
Write-Information "FQDN: $($ContainerGroup.Fqdn)"
Write-Information "Provisioning State: $($ContainerGroup.ProvisioningState)"

# Display container status
Write-Information "`nContainer Status:"
foreach ($ContainerStatus in $ContainerGroup.Container) {
    Write-Information "  Container: $($ContainerStatus.Name)"
    Write-Information "  State: $($ContainerStatus.InstanceView.CurrentState.State)"
    Write-Information "  Restart Count: $($ContainerStatus.InstanceView.RestartCount)"
}

if ($ContainerGroup.IpAddress -and $Ports) {
    Write-Information "`nAccess URLs:"
    foreach ($Port in $Ports) {
        Write-Information "  http://$($ContainerGroup.IpAddress):$Port"
    }
}

Write-Information "`nContainer Instance provisioning completed at $(Get-Date)"

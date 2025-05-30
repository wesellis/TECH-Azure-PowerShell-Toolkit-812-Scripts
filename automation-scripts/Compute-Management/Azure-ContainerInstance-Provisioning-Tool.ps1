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

Write-Host "Provisioning Container Instance: $ContainerGroupName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Container Image: $Image"
Write-Host "OS Type: $OsType"
Write-Host "CPU: $Cpu cores"
Write-Host "Memory: $Memory GB"
Write-Host "Ports: $($Ports -join ', ')"
Write-Host "Restart Policy: $RestartPolicy"

# Create port objects
$PortObjects = @()
foreach ($Port in $Ports) {
    $PortObjects += New-AzContainerInstancePortObject -Port $Port -Protocol TCP
}

# Create environment variable objects
$EnvVarObjects = @()
if ($EnvironmentVariables.Count -gt 0) {
    Write-Host "`nEnvironment Variables:"
    foreach ($EnvVar in $EnvironmentVariables.GetEnumerator()) {
        Write-Host "  $($EnvVar.Key): $($EnvVar.Value)"
        $EnvVarObjects += New-AzContainerInstanceEnvironmentVariableObject -Name $EnvVar.Key -Value $EnvVar.Value
    }
}

# Create container object
$Container = New-AzContainerInstanceObject `
    -Name $ContainerGroupName `
    -Image $Image `
    -RequestCpu $Cpu `
    -RequestMemoryInGb $Memory `
    -Port $PortObjects

if ($EnvVarObjects.Count -gt 0) {
    $Container.EnvironmentVariable = $EnvVarObjects
}

# Create the Container Instance
Write-Host "`nCreating Container Instance..."
$ContainerGroup = New-AzContainerGroup `
    -ResourceGroupName $ResourceGroupName `
    -Name $ContainerGroupName `
    -Location $Location `
    -Container $Container `
    -OsType $OsType `
    -RestartPolicy $RestartPolicy `
    -IpAddressType Public

Write-Host "`nContainer Instance $ContainerGroupName provisioned successfully"
Write-Host "Public IP Address: $($ContainerGroup.IpAddress)"
Write-Host "FQDN: $($ContainerGroup.Fqdn)"
Write-Host "Provisioning State: $($ContainerGroup.ProvisioningState)"

# Display container status
Write-Host "`nContainer Status:"
foreach ($ContainerStatus in $ContainerGroup.Container) {
    Write-Host "  Container: $($ContainerStatus.Name)"
    Write-Host "  State: $($ContainerStatus.InstanceView.CurrentState.State)"
    Write-Host "  Restart Count: $($ContainerStatus.InstanceView.RestartCount)"
}

if ($ContainerGroup.IpAddress -and $Ports) {
    Write-Host "`nAccess URLs:"
    foreach ($Port in $Ports) {
        Write-Host "  http://$($ContainerGroup.IpAddress):$Port"
    }
}

Write-Host "`nContainer Instance provisioning completed at $(Get-Date)"

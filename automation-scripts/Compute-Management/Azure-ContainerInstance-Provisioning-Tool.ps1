#Requires -Version 7.0
#Requires -Module Az.Resources

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

#region Functions

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
$params = @{
    RequestMemoryInGb = $Memory
    Name = $ContainerGroupName
    Port = $PortObjects
    RequestCpu = $Cpu
    Image = $Image
    ErrorAction = "Stop"
}
$Container @params

if ($EnvVarObjects.Count -gt 0) {
    $Container.EnvironmentVariable = $EnvVarObjects
}

# Create the Container Instance
Write-Information "`nCreating Container Instance..."
$params = @{
    ResourceGroupName = $ResourceGroupName
    RestartPolicy = $RestartPolicy
    Location = $Location
    Container = $Container
    IpAddressType = "Public"
    OsType = $OsType
    ErrorAction = "Stop"
    Name = $ContainerGroupName
}
$ContainerGroup @params

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


#endregion

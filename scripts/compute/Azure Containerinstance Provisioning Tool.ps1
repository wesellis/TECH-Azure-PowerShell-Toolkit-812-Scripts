#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Containerinstance Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Image,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$OsType = "Linux" ,
    [double]$Cpu = 1.0,
    [double]$Memory = 1.5,
    [array]$Ports = @(80),
    [hashtable]$EnvironmentVariables = @{},
    [string]$RestartPolicy = "Always"
)
Write-Output "Provisioning Container Instance: $ContainerGroupName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Container Image: $Image"
Write-Output "OS Type: $OsType"
Write-Output "CPU: $Cpu cores"
Write-Output "Memory: $Memory GB"
Write-Output "Ports: $($Ports -join ', ')"
Write-Output "Restart Policy: $RestartPolicy"
    [string]$PortObjects = @()
foreach ($Port in $Ports) {
    [string]$PortObjects = $PortObjects + New-AzContainerInstancePortObject -Port $Port -Protocol TCP
}
    [string]$EnvVarObjects = @()
if ($EnvironmentVariables.Count -gt 0) {
    Write-Output " `nEnvironment Variables:"
    foreach ($EnvVar in $EnvironmentVariables.GetEnumerator()) {
        Write-Output "  $($EnvVar.Key): $($EnvVar.Value)"
    [string]$EnvVarObjects = $EnvVarObjects + New-AzContainerInstanceEnvironmentVariableObject -Name $EnvVar.Key -Value $EnvVar.Value
    }
}
    $params = @{
    RequestMemoryInGb = $Memory
    Name = $ContainerGroupName
    Port = $PortObjects
    RequestCpu = $Cpu
    Image = $Image
    ErrorAction = "Stop"
}
    [string]$Container @params
if ($EnvVarObjects.Count -gt 0) {
    [string]$Container.EnvironmentVariable = $EnvVarObjects
}
Write-Output " `nCreating Container Instance..." ;
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
    [string]$ContainerGroup @params
Write-Output " `nContainer Instance $ContainerGroupName provisioned successfully"
Write-Output "Public IP Address: $($ContainerGroup.IpAddress)"
Write-Output "FQDN: $($ContainerGroup.Fqdn)"
Write-Output "Provisioning State: $($ContainerGroup.ProvisioningState)"
Write-Output " `nContainer Status:"
foreach ($ContainerStatus in $ContainerGroup.Container) {
    Write-Output "Container: $($ContainerStatus.Name)"
    Write-Output "State: $($ContainerStatus.InstanceView.CurrentState.State)"
    Write-Output "Restart Count: $($ContainerStatus.InstanceView.RestartCount)"
}
if ($ContainerGroup.IpAddress -and $Ports) {
    Write-Output " `nAccess URLs:"
    foreach ($Port in $Ports) {
        Write-Output "  http://$($ContainerGroup.IpAddress):$Port"
    }
}
Write-Output " `nContainer Instance provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

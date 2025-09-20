#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Containerinstance Provisioning Tool

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
Write-Host "Provisioning Container Instance: $ContainerGroupName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Container Image: $Image"
Write-Host "OS Type: $OsType"
Write-Host "CPU: $Cpu cores"
Write-Host "Memory: $Memory GB"
Write-Host "Ports: $($Ports -join ', ')"
Write-Host "Restart Policy: $RestartPolicy"
$PortObjects = @()
foreach ($Port in $Ports) {
    $PortObjects = $PortObjects + New-AzContainerInstancePortObject -Port $Port -Protocol TCP
}
$EnvVarObjects = @()
if ($EnvironmentVariables.Count -gt 0) {
    Write-Host " `nEnvironment Variables:"
    foreach ($EnvVar in $EnvironmentVariables.GetEnumerator()) {
        Write-Host "  $($EnvVar.Key): $($EnvVar.Value)"
        $EnvVarObjects = $EnvVarObjects + New-AzContainerInstanceEnvironmentVariableObject -Name $EnvVar.Key -Value $EnvVar.Value
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
$Container @params
if ($EnvVarObjects.Count -gt 0) {
    $Container.EnvironmentVariable = $EnvVarObjects
}
Write-Host " `nCreating Container Instance..." ;
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
Write-Host " `nContainer Instance $ContainerGroupName provisioned successfully"
Write-Host "Public IP Address: $($ContainerGroup.IpAddress)"
Write-Host "FQDN: $($ContainerGroup.Fqdn)"
Write-Host "Provisioning State: $($ContainerGroup.ProvisioningState)"
Write-Host " `nContainer Status:"
foreach ($ContainerStatus in $ContainerGroup.Container) {
    Write-Host "Container: $($ContainerStatus.Name)"
    Write-Host "State: $($ContainerStatus.InstanceView.CurrentState.State)"
    Write-Host "Restart Count: $($ContainerStatus.InstanceView.RestartCount)"
}
if ($ContainerGroup.IpAddress -and $Ports) {
    Write-Host " `nAccess URLs:"
    foreach ($Port in $Ports) {
        Write-Host "  http://$($ContainerGroup.IpAddress):$Port"
    }
}
Write-Host " `nContainer Instance provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n


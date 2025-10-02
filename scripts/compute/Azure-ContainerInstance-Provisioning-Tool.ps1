#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Provisions Azure Container Instances with  configuration

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Creates Azure Container Instances with support for multiple containers,
    environment variables, port configuration, and public IP access.
.PARAMETER ResourceGroupName
    Name of the resource group for the container instance
.PARAMETER ContainerGroupName
    Name of the container group
.PARAMETER Image
    Container image to deploy (e.g., nginx:latest)
.PARAMETER Location
    Azure region for the container instance
.PARAMETER OsType
    Operating system type: Linux or Windows
.PARAMETER Cpu
    CPU cores to allocate (0.1 to 4.0)
.PARAMETER Memory
    Memory in GB to allocate (0.1 to 14.0)
.PARAMETER Ports
    Array of ports to expose
.PARAMETER EnvironmentVariables
    Hashtable of environment variables
.PARAMETER RestartPolicy
    Restart policy: Always, Never, OnFailure
.PARAMETER Force
    Skip confirmation
    .\Azure-ContainerInstance-Provisioning-Tool.ps1 -ResourceGroupName "RG-Containers" -ContainerGroupName "web-app" -Image "nginx:latest" -Location "East US"
    .\Azure-ContainerInstance-Provisioning-Tool.ps1 -ResourceGroupName "RG-Containers" -ContainerGroupName "api-app" -Image "myapp:v1" -Ports @(80,443) -EnvironmentVariables @{ENV="prod"}
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Image,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateSet("Linux", "Windows")]
    [string]$OsType = "Linux",
    [Parameter()]
    [double]$Cpu = 1.0,
    [Parameter()]
    [double]$Memory = 1.5,
    [Parameter()]
    [int[]]$Ports = @(80),
    [Parameter()]
    [hashtable]$EnvironmentVariables = @{},
    [Parameter()]
    [ValidateSet("Always", "Never", "OnFailure")]
    [string]$RestartPolicy = "Always",
    [Parameter()]
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    Write-Host "Provisioning Container Instance: $ContainerGroupName" -ForegroundColor Green
    Write-Host "Validating resource group..." -ForegroundColor Green
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' not found"
    }
    Write-Host "`nContainer Configuration:" -ForegroundColor Green
    Write-Output "Resource Group: $ResourceGroupName"
    Write-Output "Container Group: $ContainerGroupName"
    Write-Output "Location: $Location"
    Write-Output "Image: $Image"
    Write-Output "OS Type: $OsType"
    Write-Output "CPU: $Cpu cores"
    Write-Output "Memory: $Memory GB"
    Write-Output "Ports: $($Ports -join ', ')"
    Write-Output "Restart Policy: $RestartPolicy"
    if ($EnvironmentVariables.Count -gt 0) {
        Write-Host "`nEnvironment Variables:" -ForegroundColor Green
        foreach ($EnvVar in $EnvironmentVariables.GetEnumerator()) {
            Write-Output "  $($EnvVar.Key): $($EnvVar.Value)"
        }
    }
    Write-Host "`nPreparing container configuration..." -ForegroundColor Green
    $PortObjects = @()
    foreach ($port in $Ports) {
        $PortObjects += New-AzContainerInstancePortObject -Port $port -Protocol TCP
    }
    $EnvVarObjects = @()
    if ($EnvironmentVariables.Count -gt 0) {
        foreach ($EnvVar in $EnvironmentVariables.GetEnumerator()) {
            $EnvVarObjects += New-AzContainerInstanceEnvironmentVariableObject -Name $EnvVar.Key -Value $EnvVar.Value
        }
    }
    $ContainerParams = @{
        Name = $ContainerGroupName
        Image = $Image
        RequestCpu = $Cpu
        RequestMemoryInGb = $Memory
        Port = $PortObjects
    }
    if ($EnvVarObjects.Count -gt 0) {
        $ContainerParams.EnvironmentVariable = $EnvVarObjects
    }
    $container = New-AzContainerInstanceObject @containerParams
    if (-not $Force) {
        $confirmation = Read-Host "`nCreate container instance? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "`nCreating Container Instance..." -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($ContainerGroupName, "Create container instance")) {
        $ContainerGroupParams = @{
            ResourceGroupName = $ResourceGroupName
            Name = $ContainerGroupName
            Location = $Location
            Container = $container
            OsType = $OsType
            RestartPolicy = $RestartPolicy
            IpAddressType = "Public"
            IpAddressPort = $Ports
        }
        $ContainerGroup = New-AzContainerGroup @containerGroupParams
        Write-Host "Container Instance provisioned successfully!" -ForegroundColor Green
        Write-Host "`nContainer Group Details:" -ForegroundColor Green
        Write-Output "Name: $($ContainerGroup.Name)"
        Write-Output "Public IP: $($ContainerGroup.IpAddress)"
        Write-Output "FQDN: $($ContainerGroup.Fqdn)"
        Write-Output "Provisioning State: $($ContainerGroup.ProvisioningState)"
        Write-Output "OS Type: $($ContainerGroup.OsType)"
        Write-Output "Restart Policy: $($ContainerGroup.RestartPolicy)"
        if ($ContainerGroup.Container) {
            Write-Host "`nContainer Status:" -ForegroundColor Green
            foreach ($ContainerStatus in $ContainerGroup.Container) {
                Write-Output "Container: $($ContainerStatus.Name)"
                if ($ContainerStatus.InstanceView) {
                    Write-Output "    State: $($ContainerStatus.InstanceView.CurrentState.State)"
                    Write-Output "    Restart Count: $($ContainerStatus.InstanceView.RestartCount)"
                }
            }
        }
        if ($ContainerGroup.IpAddress) {
            Write-Host "`nAccess URLs:" -ForegroundColor Green
            foreach ($port in $Ports) {
                Write-Output "  http://$($ContainerGroup.IpAddress):$port"
            }
        }
        Write-Host "`nNext Steps:" -ForegroundColor Green
        Write-Output "1. Monitor container logs: Get-AzContainerInstanceLog"
        Write-Output "2. Check container status: Get-AzContainerGroup"
        Write-Output "3. Access application via the public IP and ports listed above"
        if ($ContainerGroup.Fqdn) {
            Write-Output "4. Use FQDN for stable access: $($ContainerGroup.Fqdn)"
        }

} catch {
    Write-Error "Failed to provision container instance: $_"
    throw`n}

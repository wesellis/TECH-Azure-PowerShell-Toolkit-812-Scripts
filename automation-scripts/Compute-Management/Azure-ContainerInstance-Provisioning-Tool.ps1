<#
.SYNOPSIS
    Provisions Azure Container Instances with  configuration

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
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
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    Write-Host "Provisioning Container Instance: $ContainerGroupName" -ForegroundColor Yellow
    # Check if resource group exists
    Write-Host "Validating resource group..." -ForegroundColor Yellow
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' not found"
    }
    # Display configuration
    Write-Host "`nContainer Configuration:" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "Container Group: $ContainerGroupName"
    Write-Host "Location: $Location"
    Write-Host "Image: $Image"
    Write-Host "OS Type: $OsType"
    Write-Host "CPU: $Cpu cores"
    Write-Host "Memory: $Memory GB"
    Write-Host "Ports: $($Ports -join ', ')"
    Write-Host "Restart Policy: $RestartPolicy"
    if ($EnvironmentVariables.Count -gt 0) {
        Write-Host "`nEnvironment Variables:" -ForegroundColor Cyan
        foreach ($envVar in $EnvironmentVariables.GetEnumerator()) {
            Write-Host "  $($envVar.Key): $($envVar.Value)"
        }
    }
    # Create port objects
    Write-Host "`nPreparing container configuration..." -ForegroundColor Yellow
    $portObjects = @()
    foreach ($port in $Ports) {
        $portObjects += New-AzContainerInstancePortObject -Port $port -Protocol TCP
    }
    # Create environment variable objects
    $envVarObjects = @()
    if ($EnvironmentVariables.Count -gt 0) {
        foreach ($envVar in $EnvironmentVariables.GetEnumerator()) {
            $envVarObjects += New-AzContainerInstanceEnvironmentVariableObject -Name $envVar.Key -Value $envVar.Value
        }
    }
    # Create container object
    $containerParams = @{
        Name = $ContainerGroupName
        Image = $Image
        RequestCpu = $Cpu
        RequestMemoryInGb = $Memory
        Port = $portObjects
    }
    if ($envVarObjects.Count -gt 0) {
        $containerParams.EnvironmentVariable = $envVarObjects
    }
    $container = New-AzContainerInstanceObject @containerParams
    # Confirmation
    if (-not $Force) {
        $confirmation = Read-Host "`nCreate container instance? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    # Create the Container Instance
    Write-Host "`nCreating Container Instance..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($ContainerGroupName, "Create container instance")) {
        $containerGroupParams = @{
            ResourceGroupName = $ResourceGroupName
            Name = $ContainerGroupName
            Location = $Location
            Container = $container
            OsType = $OsType
            RestartPolicy = $RestartPolicy
            IpAddressType = "Public"
            IpAddressPort = $Ports
        }
        $containerGroup = New-AzContainerGroup @containerGroupParams
        Write-Host "Container Instance provisioned successfully!" -ForegroundColor Green
        Write-Host "`nContainer Group Details:" -ForegroundColor Cyan
        Write-Host "Name: $($containerGroup.Name)"
        Write-Host "Public IP: $($containerGroup.IpAddress)"
        Write-Host "FQDN: $($containerGroup.Fqdn)"
        Write-Host "Provisioning State: $($containerGroup.ProvisioningState)"
        Write-Host "OS Type: $($containerGroup.OsType)"
        Write-Host "Restart Policy: $($containerGroup.RestartPolicy)"
        # Display container status
        if ($containerGroup.Container) {
            Write-Host "`nContainer Status:" -ForegroundColor Cyan
            foreach ($containerStatus in $containerGroup.Container) {
                Write-Host "Container: $($containerStatus.Name)"
                if ($containerStatus.InstanceView) {
                    Write-Host "    State: $($containerStatus.InstanceView.CurrentState.State)"
                    Write-Host "    Restart Count: $($containerStatus.InstanceView.RestartCount)"
                }
            }
        }
        # Display access URLs
        if ($containerGroup.IpAddress) {
            Write-Host "`nAccess URLs:" -ForegroundColor Cyan
            foreach ($port in $Ports) {
                Write-Host "  http://$($containerGroup.IpAddress):$port"
            }
        }
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Monitor container logs: Get-AzContainerInstanceLog"
        Write-Host "2. Check container status: Get-AzContainerGroup"
        Write-Host "3. Access application via the public IP and ports listed above"
        if ($containerGroup.Fqdn) {
            Write-Host "4. Use FQDN for stable access: $($containerGroup.Fqdn)"
        }
    
} catch {
    Write-Error "Failed to provision container instance: $_"
    throw
}\n
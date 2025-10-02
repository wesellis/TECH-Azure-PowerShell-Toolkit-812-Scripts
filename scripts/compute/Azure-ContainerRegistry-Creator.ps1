#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Creates Azure Container Registry with configuration options

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Creates an Azure Container Registry with specified SKU and configuration.
    Optionally enables admin user and retrieves credentials.
.PARAMETER ResourceGroupName
    Name of the resource group for the container registry
.PARAMETER RegistryName
    Name of the container registry (must be globally unique)
.PARAMETER Location
    Azure region for the container registry
.PARAMETER Sku
    SKU for the container registry (Basic, Standard, Premium)
.PARAMETER EnableAdminUser
    Enable admin user for the registry
.PARAMETER ShowCredentials
    Display admin credentials after creation
    .\Azure-ContainerRegistry-Creator.ps1 -ResourceGroupName "RG-Containers" -RegistryName "myregistry123" -Location "East US"
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9]{5,50}$')]
    [string]$RegistryName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateSet("Basic", "Standard", "Premium")]
    [string]$Sku = "Basic",
    [Parameter()]
    [switch]$EnableAdminUser,
    [Parameter()]
    [switch]$ShowCredentials
)
$ErrorActionPreference = 'Stop'
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    Write-Host "Checking registry name availability..." -ForegroundColor Green
    try {
        $AvailabilityResult = Test-AzContainerRegistryNameAvailability -Name $RegistryName
        if (-not $AvailabilityResult.NameAvailable) {
            throw "Registry name '$RegistryName' is not available: $($AvailabilityResult.Reason)"
        }
        Write-Host "Registry name is available" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not check name availability: $_"
    }
    Write-Host "Validating resource group..." -ForegroundColor Green
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' not found"
    }
    Write-Host "Creating Container Registry: $RegistryName" -ForegroundColor Green
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $RegistryName
        Location = $Location
        Sku = $Sku
    }
    if ($EnableAdminUser) {
        $params.EnableAdminUser = $true
    }
    if ($PSCmdlet.ShouldProcess($RegistryName, "Create Container Registry")) {
        $Registry = New-AzContainerRegistry @params
        Write-Host "Container Registry created successfully!" -ForegroundColor Green
        Write-Host "Registry Details:" -ForegroundColor Green
        Write-Output "Name: $($Registry.Name)"
        Write-Output "Login Server: $($Registry.LoginServer)"
        Write-Output "Location: $($Registry.Location)"
        Write-Output "SKU: $($Registry.Sku.Name)"
        Write-Output "Admin Enabled: $($Registry.AdminUserEnabled)"
        if ($Registry.AdminUserEnabled -and $ShowCredentials) {
            Write-Host "`nRetrieving admin credentials..." -ForegroundColor Green
            try {
                $Creds = Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $RegistryName
                Write-Host "Admin Credentials:" -ForegroundColor Green
                Write-Output "Username: $($Creds.Username)"
                Write-Host "Password: $($Creds.Password)" -ForegroundColor Green
                Write-Host "Password2: $($Creds.Password2)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not retrieve admin credentials: $_"
            }
        }
        elseif (-not $Registry.AdminUserEnabled -and $ShowCredentials) {
            Write-Host "Note: Admin user is not enabled. Use -EnableAdminUser to enable admin credentials." -ForegroundColor Green
        }
        Write-Host "`nNext Steps:" -ForegroundColor Green
        Write-Output "1. Docker login: docker login $($Registry.LoginServer)"
        Write-Output "2. Tag images: docker tag myimage:latest $($Registry.LoginServer)/myimage:latest"
        Write-Output "3. Push images: docker push $($Registry.LoginServer)/myimage:latest"

} catch {
    Write-Error "Failed to create container registry: $_"
    throw`n}

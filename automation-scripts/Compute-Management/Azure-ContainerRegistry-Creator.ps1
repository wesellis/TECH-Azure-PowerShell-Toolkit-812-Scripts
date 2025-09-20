<#
.SYNOPSIS
    Creates Azure Container Registry with configuration options

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
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
    # Test Azure connection
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    # Check if registry name is available
    Write-Host "Checking registry name availability..." -ForegroundColor Yellow
    try {
        $availabilityResult = Test-AzContainerRegistryNameAvailability -Name $RegistryName
        if (-not $availabilityResult.NameAvailable) {
            throw "Registry name '$RegistryName' is not available: $($availabilityResult.Reason)"
        }
        Write-Host "Registry name is available" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not check name availability: $_"
    }
    # Check if resource group exists
    Write-Host "Validating resource group..." -ForegroundColor Yellow
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' not found"
    }
    Write-Host "Creating Container Registry: $RegistryName" -ForegroundColor Yellow
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
        Write-Host "Registry Details:" -ForegroundColor Cyan
        Write-Host "Name: $($Registry.Name)"
        Write-Host "Login Server: $($Registry.LoginServer)"
        Write-Host "Location: $($Registry.Location)"
        Write-Host "SKU: $($Registry.Sku.Name)"
        Write-Host "Admin Enabled: $($Registry.AdminUserEnabled)"
        # Get admin credentials if enabled and requested
        if ($Registry.AdminUserEnabled -and $ShowCredentials) {
            Write-Host "`nRetrieving admin credentials..." -ForegroundColor Yellow
            try {
                $Creds = Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $RegistryName
                Write-Host "Admin Credentials:" -ForegroundColor Cyan
                Write-Host "Username: $($Creds.Username)"
                Write-Host "Password: $($Creds.Password)" -ForegroundColor Yellow
                Write-Host "Password2: $($Creds.Password2)" -ForegroundColor Yellow
            }
            catch {
                Write-Warning "Could not retrieve admin credentials: $_"
            }
        }
        elseif (-not $Registry.AdminUserEnabled -and $ShowCredentials) {
            Write-Host "Note: Admin user is not enabled. Use -EnableAdminUser to enable admin credentials." -ForegroundColor Yellow
        }
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Docker login: docker login $($Registry.LoginServer)"
        Write-Host "2. Tag images: docker tag myimage:latest $($Registry.LoginServer)/myimage:latest"
        Write-Host "3. Push images: docker push $($Registry.LoginServer)/myimage:latest"
    
} catch {
    Write-Error "Failed to create container registry: $_"
    throw
}


#Requires -Version 7.0

<#
.SYNOPSIS
    Sets up Terraform backend storage in Azure

.DESCRIPTION
    Creates Azure storage account and container for Terraform state management.
    Configures proper security and access controls for state files.

.PARAMETER ResourceGroupName
    Resource group name for the storage account

.PARAMETER StorageAccountName
    Storage account name (must be globally unique)

.PARAMETER Location
    Azure region for the storage account

.PARAMETER ContainerName
    Container name for state files

.PARAMETER Environment
    Environment tag for the resources

.EXAMPLE
    .\setup-backend.ps1 -ResourceGroupName "tfstate-rg" -StorageAccountName "tfstatestorage" -Location "East US"

.NOTES
    Run this script once per environment to set up Terraform backend
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$StorageAccountName,

    [Parameter()]
    [string]$Location = 'East US',

    [Parameter()]
    [string]$ContainerName = 'tfstate',

    [Parameter()]
    [string]$Environment = 'shared'
)

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.Storage -Force -ErrorAction Stop
} catch {
    Write-Error "Required Azure PowerShell modules not found. Install with: Install-Module -Name Az -Force"
    exit 1
}

Write-Host "Setting up Terraform backend storage..." -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host ""

# Check Azure connection
if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

$context = Get-AzContext
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host ""

# Create resource group if it doesn't exist
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create Resource Group")) {
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag @{
            Purpose = "Terraform-Backend"
            Environment = $Environment
            ManagedBy = "PowerShell-Script"
        }
        Write-Host "Resource group created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing resource group: $ResourceGroupName" -ForegroundColor Green
}

# Check if storage account exists
$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue

if (-not $storageAccount) {
    Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Yellow

    if ($PSCmdlet.ShouldProcess($StorageAccountName, "Create Storage Account")) {
        $storageAccount = New-AzStorageAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -Location $Location `
            -SkuName "Standard_LRS" `
            -Kind "StorageV2" `
            -AccessTier "Hot" `
            -EnableHttpsTrafficOnly $true `
            -MinimumTlsVersion "TLS1_2" `
            -AllowBlobPublicAccess $false `
            -Tag @{
                Purpose = "Terraform-Backend"
                Environment = $Environment
                ManagedBy = "PowerShell-Script"
            }

        Write-Host "Storage account created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing storage account: $StorageAccountName" -ForegroundColor Green
}

# Get storage context
$storageContext = $storageAccount.Context

# Create container if it doesn't exist
$container = Get-AzStorageContainer -Name $ContainerName -Context $storageContext -ErrorAction SilentlyContinue

if (-not $container) {
    Write-Host "Creating container: $ContainerName" -ForegroundColor Yellow

    if ($PSCmdlet.ShouldProcess($ContainerName, "Create Storage Container")) {
        $container = New-AzStorageContainer -Name $ContainerName -Context $storageContext -Permission Off
        Write-Host "Container created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing container: $ContainerName" -ForegroundColor Green
}

# Configure storage account security
Write-Host "Configuring storage account security..." -ForegroundColor Yellow

if ($PSCmdlet.ShouldProcess($StorageAccountName, "Configure Security Settings")) {
    # Enable blob versioning
    try {
        $blobServiceProperties = @{
            EnableVersioning = $true
            IsVersioningEnabled = $true
        }
        # Note: This would require specific Azure PowerShell cmdlets for blob service properties
        Write-Host "  Blob versioning configuration noted (requires manual setup)" -ForegroundColor Yellow
    } catch {
        Write-Warning "Could not configure blob versioning: $($_.Exception.Message)"
    }

    # Configure network access (if needed)
    try {
        Update-AzStorageAccountNetworkRuleSet `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -DefaultAction Allow `
            -Bypass AzureServices

        Write-Host "  Network access rules configured" -ForegroundColor Green
    } catch {
        Write-Warning "Could not configure network rules: $($_.Exception.Message)"
    }
}

# Get storage account key
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value

# Generate backend configuration
Write-Host ""
Write-Host "Backend configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Use the following configuration for Terraform initialization:" -ForegroundColor Cyan
Write-Host ""
Write-Host "terraform init \\" -ForegroundColor White
Write-Host "  -backend-config='resource_group_name=$ResourceGroupName' \\" -ForegroundColor White
Write-Host "  -backend-config='storage_account_name=$StorageAccountName' \\" -ForegroundColor White
Write-Host "  -backend-config='container_name=$ContainerName' \\" -ForegroundColor White
Write-Host "  -backend-config='key=terraform.tfstate'" -ForegroundColor White
Write-Host ""

Write-Host "Or set environment variables:" -ForegroundColor Cyan
Write-Host ""
Write-Host "`$env:ARM_ACCESS_KEY = '$storageKey'" -ForegroundColor Yellow
Write-Host ""

# Create backend configuration file
$backendConfig = @"
resource_group_name  = "$ResourceGroupName"
storage_account_name = "$StorageAccountName"
container_name      = "$ContainerName"
key                 = "terraform.tfstate"
"@

$backendConfigPath = Join-Path $PSScriptRoot "backend.hcl"
Set-Content -Path $backendConfigPath -Value $backendConfig -Encoding UTF8

Write-Host "Backend configuration saved to: $backendConfigPath" -ForegroundColor Green
Write-Host ""
Write-Host "Initialize Terraform with:" -ForegroundColor Cyan
Write-Host "terraform init -backend-config='backend.hcl'" -ForegroundColor White
Write-Host ""

# Security recommendations
Write-Host "Security Recommendations:" -ForegroundColor Yellow
Write-Host "1. Restrict storage account access to specific IP ranges or VNets" -ForegroundColor White
Write-Host "2. Use managed identities instead of access keys where possible" -ForegroundColor White
Write-Host "3. Enable storage account logging and monitoring" -ForegroundColor White
Write-Host "4. Regularly rotate access keys" -ForegroundColor White
Write-Host "5. Consider using Azure Key Vault for access key storage" -ForegroundColor White

Write-Host ""
Write-Host "Terraform backend setup completed successfully!" -ForegroundColor Green
#Requires -Version 7.0

<#
.SYNOPSIS
    Sets up Terraform backend storage in Azure

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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

try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.Storage -Force -ErrorAction Stop
} catch {
    Write-Error "Required Azure PowerShell modules not found. Install with: Install-Module -Name Az -Force"
    exit 1
}

Write-Host "Setting up Terraform backend storage..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Output ""

if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    Connect-AzAccount
}
    $context = Get-AzContext
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Output ""
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $ResourceGroup) {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create Resource Group")) {
        $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag @{
            Purpose = "Terraform-Backend"
            Environment = $Environment
            ManagedBy = "PowerShell-Script"
        }
        Write-Host "Resource group created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing resource group: $ResourceGroupName" -ForegroundColor Green
}
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue

if (-not $StorageAccount) {
    Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Green

    if ($PSCmdlet.ShouldProcess($StorageAccountName, "Create Storage Account")) {
        $StorageAccount = New-AzStorageAccount `
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
$StorageContext = $StorageAccount.Context
    $container = Get-AzStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction SilentlyContinue

if (-not $container) {
    Write-Host "Creating container: $ContainerName" -ForegroundColor Green

    if ($PSCmdlet.ShouldProcess($ContainerName, "Create Storage Container")) {
        $container = New-AzStorageContainer -Name $ContainerName -Context $StorageContext -Permission Off
        Write-Host "Container created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing container: $ContainerName" -ForegroundColor Green
}

Write-Host "Configuring storage account security..." -ForegroundColor Green

if ($PSCmdlet.ShouldProcess($StorageAccountName, "Configure Security Settings")) {
    try {
        $BlobServiceProperties = @{
            EnableVersioning = $true
            IsVersioningEnabled = $true
        }
        Write-Host "  Blob versioning configuration noted (requires manual setup)" -ForegroundColor Green
    } catch {
        Write-Warning "Could not configure blob versioning: $($_.Exception.Message)"
    }

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
$StorageKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value

Write-Output ""
Write-Host "Backend configuration complete!" -ForegroundColor Green
Write-Output ""
Write-Host "Use the following configuration for Terraform initialization:" -ForegroundColor Green
Write-Output ""
Write-Host "terraform init \\" -ForegroundColor Green
Write-Host "  -backend-config='resource_group_name=$ResourceGroupName' \\" -ForegroundColor Green
Write-Host "  -backend-config='storage_account_name=$StorageAccountName' \\" -ForegroundColor Green
Write-Host "  -backend-config='container_name=$ContainerName' \\" -ForegroundColor Green
Write-Host "  -backend-config='key=terraform.tfstate'" -ForegroundColor Green
Write-Output ""

Write-Host "Or set environment variables:" -ForegroundColor Green
Write-Output ""
Write-Host "`$env:ARM_ACCESS_KEY = '$StorageKey'" -ForegroundColor Green
Write-Output ""
$BackendConfig = @"
resource_group_name  = "$ResourceGroupName"
storage_account_name = "$StorageAccountName"
container_name      = "$ContainerName"
key                 = "terraform.tfstate"
"@
$BackendConfigPath = Join-Path $PSScriptRoot "backend.hcl"
Set-Content -Path $BackendConfigPath -Value $BackendConfig -Encoding UTF8

Write-Host "Backend configuration saved to: $BackendConfigPath" -ForegroundColor Green
Write-Output ""
Write-Host "Initialize Terraform with:" -ForegroundColor Green
Write-Host "terraform init -backend-config='backend.hcl'" -ForegroundColor Green
Write-Output ""

Write-Host "Security Recommendations:" -ForegroundColor Green
Write-Host "1. Restrict storage account access to specific IP ranges or VNets" -ForegroundColor Green
Write-Host "2. Use managed identities instead of access keys where possible" -ForegroundColor Green
Write-Host "3. Enable storage account logging and monitoring" -ForegroundColor Green
Write-Host "4. Regularly rotate access keys" -ForegroundColor Green
Write-Host "5. Consider using Azure Key Vault for access key storage" -ForegroundColor Green

Write-Output ""
Write-Host "Terraform backend setup completed successfully!" -ForegroundColor Green

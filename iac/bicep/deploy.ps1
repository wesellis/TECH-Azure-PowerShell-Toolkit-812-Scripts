#Requires -Version 7.0

<#
.SYNOPSIS
    Azure PowerShell Toolkit Bicep deployment script

.DESCRIPTION
    Deploys Azure infrastructure using Bicep templates for the Azure PowerShell Toolkit.
    Supports multiple environments and deployment scenarios.

.PARAMETER Environment
    Target environment (dev, staging, prod)

.PARAMETER Location
    Azure region for deployment

.PARAMETER ResourceGroupName
    Name of the resource group to deploy to

.PARAMETER AdminPassword
    Administrator password for VMs (if not provided, will be prompted)

.PARAMETER DeployAdvanced
    Deploy advanced resources (AKS, App Service, SQL)

.PARAMETER WhatIf
    Preview deployment without making changes

.EXAMPLE
    .\deploy.ps1 -Environment dev -Location "East US" -ResourceGroupName "toolkit-dev-rg"

.EXAMPLE
    .\deploy.ps1 -Environment prod -Location "East US" -ResourceGroupName "toolkit-prod-rg" -DeployAdvanced -WhatIf

.NOTES
    Author: Azure PowerShell Toolkit Team
    Requires: Azure PowerShell, Bicep CLI
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter()]
    [string]$Location = 'East US',

    [Parameter()]
    [string]$ResourceGroupName = "toolkit-$Environment-rg",

    [Parameter()]
    [SecureString]$AdminPassword,

    [Parameter()]
    [switch]$DeployAdvanced,

    [Parameter()]
    [switch]$ValidateOnly
)

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
} catch {
    Write-Error "Required Azure PowerShell modules not found. Install with: Install-Module -Name Az -Force"
    exit 1
}

Write-Host "Azure PowerShell Toolkit - Bicep Deployment" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host ""

# Check Azure connection
if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

$context = Get-AzContext
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host ""

# Validate Bicep CLI availability
try {
    $bicepVersion = bicep --version
    Write-Host "Bicep CLI version: $bicepVersion" -ForegroundColor Green
} catch {
    Write-Error "Bicep CLI not found. Install from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install"
    exit 1
}

# Get admin password if not provided
if (-not $AdminPassword) {
    $AdminPassword = Read-Host "Enter administrator password for VMs" -AsSecureString
}

# Convert SecureString to plain text for ARM template
$adminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
)

# Create resource group if it doesn't exist
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create Resource Group")) {
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "Resource group created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing resource group: $ResourceGroupName" -ForegroundColor Green
}

# Set deployment parameters
$templateFile = Join-Path $PSScriptRoot "main.bicep"
$deploymentName = "toolkit-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$templateParameters = @{
    environment = $Environment
    location = $Location
    adminPassword = $adminPasswordPlain
    deployAdvanced = $DeployAdvanced.IsPresent
}

Write-Host ""
Write-Host "Deployment Parameters:" -ForegroundColor Cyan
$templateParameters.GetEnumerator() | Where-Object { $_.Key -ne 'adminPassword' } | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
}
Write-Host ""

# Validate template
Write-Host "Validating Bicep template..." -ForegroundColor Yellow
try {
    $validationResult = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterObject $templateParameters `
        -ErrorAction Stop

    if ($validationResult) {
        Write-Host "Template validation failed:" -ForegroundColor Red
        $validationResult | ForEach-Object {
            Write-Host "  Error: $($_.Message)" -ForegroundColor Red
        }
        exit 1
    } else {
        Write-Host "Template validation passed" -ForegroundColor Green
    }
} catch {
    Write-Host "Template validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($ValidateOnly) {
    Write-Host "Validation-only mode - deployment skipped" -ForegroundColor Yellow
    exit 0
}

# Deploy template
Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Cyan
Write-Host "Deployment name: $deploymentName" -ForegroundColor White

try {
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Deploy Bicep Template")) {
        $deployment = New-AzResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -Name $deploymentName `
            -TemplateFile $templateFile `
            -TemplateParameterObject $templateParameters `
            -Verbose

        if ($deployment.ProvisioningState -eq 'Succeeded') {
            Write-Host ""
            Write-Host "Deployment completed successfully!" -ForegroundColor Green

            # Display outputs
            if ($deployment.Outputs.Count -gt 0) {
                Write-Host ""
                Write-Host "Deployment Outputs:" -ForegroundColor Cyan
                $deployment.Outputs.GetEnumerator() | ForEach-Object {
                    Write-Host "  $($_.Key): $($_.Value.Value)" -ForegroundColor White
                }
            }

            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Yellow
            Write-Host "1. Verify resources in the Azure portal" -ForegroundColor White
            Write-Host "2. Run PowerShell scripts against the deployed infrastructure" -ForegroundColor White
            Write-Host "3. Configure monitoring and alerting as needed" -ForegroundColor White

        } else {
            Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clean up sensitive data
$adminPasswordPlain = $null
$AdminPassword = $null

Write-Host ""
Write-Host "Deployment process completed" -ForegroundColor Green
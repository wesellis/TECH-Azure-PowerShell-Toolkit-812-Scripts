#Requires -Version 7.0

<#
.SYNOPSIS
    Azure PowerShell Toolkit Bicep deployment script

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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

try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
} catch {
    Write-Error "Required Azure PowerShell modules not found. Install with: Install-Module -Name Az -Force"
    exit 1
}

Write-Host "Azure PowerShell Toolkit - Bicep Deployment" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Output ""

if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    Connect-AzAccount
}
    $context = Get-AzContext
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Output ""

try {
    [string]$BicepVersion = bicep --version
    Write-Host "Bicep CLI version: $BicepVersion" -ForegroundColor Green
} catch {
    Write-Error "Bicep CLI not found. Install from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install"
    exit 1
}

if (-not $AdminPassword) {
    [string]$AdminPassword = Read-Host "Enter administrator password for VMs" -AsSecureString
}
    [string]$AdminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
)
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $ResourceGroup) {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create Resource Group")) {
    [string]$ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "Resource group created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "Using existing resource group: $ResourceGroupName" -ForegroundColor Green
}
    [string]$TemplateFile = Join-Path $PSScriptRoot "main.bicep"
    [string]$DeploymentName = "toolkit-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $TemplateParameters = @{
    environment = $Environment
    location = $Location
    adminPassword = $AdminPasswordPlain
    deployAdvanced = $DeployAdvanced.IsPresent
}

Write-Output ""
Write-Host "Deployment Parameters:" -ForegroundColor Green
    [string]$TemplateParameters.GetEnumerator() | Where-Object { $_.Key -ne 'adminPassword' } | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Green
}
Write-Output ""

Write-Host "Validating Bicep template..." -ForegroundColor Green
try {
    [string]$ValidationResult = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $TemplateParameters `
        -ErrorAction Stop

    if ($ValidationResult) {
        Write-Host "Template validation failed:" -ForegroundColor Green
    [string]$ValidationResult | ForEach-Object {
            Write-Host "  Error: $($_.Message)" -ForegroundColor Green
        }
        exit 1
    } else {
        Write-Host "Template validation passed" -ForegroundColor Green
    }
} catch {
    Write-Host "Template validation failed: $($_.Exception.Message)" -ForegroundColor Green
    exit 1
}

if ($ValidateOnly) {
    Write-Host "Validation-only mode - deployment skipped" -ForegroundColor Green
    exit 0
}

Write-Output ""
Write-Host "Starting deployment..." -ForegroundColor Green
Write-Host "Deployment name: $DeploymentName" -ForegroundColor Green

try {
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Deploy Bicep Template")) {
    [string]$deployment = New-AzResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -Name $DeploymentName `
            -TemplateFile $TemplateFile `
            -TemplateParameterObject $TemplateParameters `
            -Verbose

        if ($deployment.ProvisioningState -eq 'Succeeded') {
            Write-Output ""
            Write-Host "Deployment completed successfully!" -ForegroundColor Green

            if ($deployment.Outputs.Count -gt 0) {
                Write-Output ""
                Write-Host "Deployment Outputs:" -ForegroundColor Green
    [string]$deployment.Outputs.GetEnumerator() | ForEach-Object {
                    Write-Host "  $($_.Key): $($_.Value.Value)" -ForegroundColor Green
                }
            }

            Write-Output ""
            Write-Host "Next steps:" -ForegroundColor Green
            Write-Host "1. Verify resources in the Azure portal" -ForegroundColor Green
            Write-Host "2. Run PowerShell scripts against the deployed infrastructure" -ForegroundColor Green
            Write-Host "3. Configure monitoring and alerting as needed" -ForegroundColor Green

        } else {
            Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Green
            exit 1
        }
    }
} catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Green
    exit 1
}
    [string]$AdminPasswordPlain = $null
    [string]$AdminPassword = $null

Write-Output ""
Write-Host "Deployment process completed" -ForegroundColor Green

#Requires -Version 7.0

<#
.SYNOPSIS
    Terraform deployment script for Azure PowerShell Toolkit

.DESCRIPTION
    Deploys Azure infrastructure using Terraform for the Azure PowerShell Toolkit.
    Handles Terraform initialization, planning, and deployment with proper state management.

.PARAMETER Environment
    Target environment (dev, staging, prod)

.PARAMETER Location
    Azure region for deployment

.PARAMETER AdminPassword
    Administrator password for VMs

.PARAMETER DeployAdvanced
    Deploy advanced resources (AKS, App Service, SQL)

.PARAMETER Plan
    Generate and display Terraform plan without applying

.PARAMETER Destroy
    Destroy the Terraform-managed infrastructure

.EXAMPLE
    .\deploy.ps1 -Environment dev -Location "East US" -AdminPassword "ComplexPassword123!"

.EXAMPLE
    .\deploy.ps1 -Environment prod -DeployAdvanced -Plan

.NOTES
    Author: Azure PowerShell Toolkit Team
    Requires: Terraform CLI, Azure CLI or PowerShell
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter()]
    [string]$Location = 'East US',

    [Parameter()]
    [SecureString]$AdminPassword,

    [Parameter()]
    [switch]$DeployAdvanced,

    [Parameter()]
    [switch]$Plan,

    [Parameter()]
    [switch]$Destroy
)

Write-Host "Azure PowerShell Toolkit - Terraform Deployment" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host ""

# Check Terraform availability
try {
    $terraformVersion = terraform version
    Write-Host "Terraform version: $($terraformVersion | Select-Object -First 1)" -ForegroundColor Green
} catch {
    Write-Error "Terraform CLI not found. Install from: https://www.terraform.io/downloads"
    exit 1
}

# Check Azure authentication
try {
    az account show | Out-Null
    $account = az account show | ConvertFrom-Json
    Write-Host "Azure subscription: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI authentication required. Running 'az login'..." -ForegroundColor Yellow
    az login
}

# Get admin password if not provided
if (-not $AdminPassword -and -not $Destroy) {
    $AdminPassword = Read-Host "Enter administrator password for VMs" -AsSecureString
}

# Convert SecureString to plain text
$adminPasswordPlain = if ($AdminPassword) {
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    )
} else { "" }

# Set working directory to Terraform configuration
$originalLocation = Get-Location
$terraformDir = $PSScriptRoot
Set-Location $terraformDir

try {
    # Initialize Terraform
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform initialization failed"
    }

    # Create terraform.tfvars file
    $tfVarsContent = @"
environment      = "$Environment"
location        = "$Location"
admin_password  = "$adminPasswordPlain"
deploy_advanced = $($DeployAdvanced.IsPresent.ToString().ToLower())
"@

    $tfVarsPath = Join-Path $terraformDir "terraform.tfvars"
    Set-Content -Path $tfVarsPath -Value $tfVarsContent -Encoding UTF8

    if ($Destroy) {
        # Destroy infrastructure
        Write-Host ""
        Write-Host "Planning infrastructure destruction..." -ForegroundColor Red
        terraform plan -destroy -var-file="terraform.tfvars"

        if ($PSCmdlet.ShouldProcess("Terraform infrastructure", "Destroy")) {
            Write-Host ""
            Write-Host "Destroying infrastructure..." -ForegroundColor Red
            terraform destroy -var-file="terraform.tfvars" -auto-approve

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Infrastructure destroyed successfully" -ForegroundColor Green
            } else {
                throw "Terraform destroy failed"
            }
        }
    } else {
        # Plan deployment
        Write-Host "Planning Terraform deployment..." -ForegroundColor Yellow
        terraform plan -var-file="terraform.tfvars" -out="tfplan"

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform planning failed"
        }

        if ($Plan) {
            Write-Host ""
            Write-Host "Plan generated successfully. Review the plan above." -ForegroundColor Green
            Write-Host "To apply this plan, run the script again without -Plan parameter." -ForegroundColor Yellow
        } else {
            # Apply deployment
            if ($PSCmdlet.ShouldProcess("Terraform infrastructure", "Deploy")) {
                Write-Host ""
                Write-Host "Applying Terraform deployment..." -ForegroundColor Cyan
                terraform apply "tfplan"

                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Host "Deployment completed successfully!" -ForegroundColor Green

                    # Display outputs
                    Write-Host ""
                    Write-Host "Deployment Outputs:" -ForegroundColor Cyan
                    terraform output

                    Write-Host ""
                    Write-Host "Next steps:" -ForegroundColor Yellow
                    Write-Host "1. Verify resources in the Azure portal" -ForegroundColor White
                    Write-Host "2. Run PowerShell scripts against the deployed infrastructure" -ForegroundColor White
                    Write-Host "3. Configure monitoring and alerting as needed" -ForegroundColor White
                } else {
                    throw "Terraform apply failed"
                }
            }
        }
    }

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
} finally {
    # Clean up sensitive files
    $tfVarsPath = Join-Path $terraformDir "terraform.tfvars"
    if (Test-Path $tfVarsPath) {
        Remove-Item $tfVarsPath -Force
    }

    # Clean up variables
    $adminPasswordPlain = $null
    $AdminPassword = $null

    # Return to original location
    Set-Location $originalLocation
}

Write-Host ""
Write-Host "Terraform deployment process completed" -ForegroundColor Green
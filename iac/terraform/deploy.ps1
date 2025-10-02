#Requires -Version 7.0

<#
.SYNOPSIS
    Terraform deployment script for Azure PowerShell Toolkit

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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

Write-Host "Azure PowerShell Toolkit - Terraform Deployment" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Output ""

try {
    $TerraformVersion = terraform version
    Write-Host "Terraform version: $($TerraformVersion | Select-Object -First 1)" -ForegroundColor Green
} catch {
    Write-Error "Terraform CLI not found. Install from: https://www.terraform.io/downloads"
    exit 1
}

try {
    az account show | Out-Null
    $account = az account show | ConvertFrom-Json
    Write-Host "Azure subscription: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI authentication required. Running 'az login'..." -ForegroundColor Green
    az login
}

if (-not $AdminPassword -and -not $Destroy) {
    $AdminPassword = Read-Host "Enter administrator password for VMs" -AsSecureString
}
$AdminPasswordPlain = if ($AdminPassword) {
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    )
} else { "" }
    $OriginalLocation = Get-Location
    $TerraformDir = $PSScriptRoot
Set-Location $TerraformDir

try {
    Write-Host "Initializing Terraform..." -ForegroundColor Green
    terraform init

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform initialization failed"
    }
    $TfVarsContent = @"
environment      = "$Environment"
location        = "$Location"
admin_password = $env:CREDENTIAL_password
deploy_advanced = $($DeployAdvanced.IsPresent.ToString().ToLower())
"@
    $TfVarsPath = Join-Path $TerraformDir "terraform.tfvars"
    Set-Content -Path $TfVarsPath -Value $TfVarsContent -Encoding UTF8

    if ($Destroy) {
        Write-Output ""
        Write-Host "Planning infrastructure destruction..." -ForegroundColor Green
        terraform plan -destroy -var-file="terraform.tfvars"

        if ($PSCmdlet.ShouldProcess("Terraform infrastructure", "Destroy")) {
            Write-Output ""
            Write-Host "Destroying infrastructure..." -ForegroundColor Green
            terraform destroy -var-file="terraform.tfvars" -auto-approve

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Infrastructure destroyed successfully" -ForegroundColor Green
            } else {
                throw "Terraform destroy failed"
            }
        }
    } else {
        Write-Host "Planning Terraform deployment..." -ForegroundColor Green
        terraform plan -var-file="terraform.tfvars" -out="tfplan"

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform planning failed"
        }

        if ($Plan) {
            Write-Output ""
            Write-Host "Plan generated successfully. Review the plan above." -ForegroundColor Green
            Write-Host "To apply this plan, run the script again without -Plan parameter." -ForegroundColor Green
        } else {
            if ($PSCmdlet.ShouldProcess("Terraform infrastructure", "Deploy")) {
                Write-Output ""
                Write-Host "Applying Terraform deployment..." -ForegroundColor Green
                terraform apply "tfplan"

                if ($LASTEXITCODE -eq 0) {
                    Write-Output ""
                    Write-Host "Deployment completed successfully!" -ForegroundColor Green

                    Write-Output ""
                    Write-Host "Deployment Outputs:" -ForegroundColor Green
                    terraform output

                    Write-Output ""
                    Write-Host "Next steps:" -ForegroundColor Green
                    Write-Host "1. Verify resources in the Azure portal" -ForegroundColor Green
                    Write-Host "2. Run PowerShell scripts against the deployed infrastructure" -ForegroundColor Green
                    Write-Host "3. Configure monitoring and alerting as needed" -ForegroundColor Green
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
    $TfVarsPath = Join-Path $TerraformDir "terraform.tfvars"
    if (Test-Path $TfVarsPath) {
        Remove-Item $TfVarsPath -Force
    }
    $AdminPasswordPlain = $null
    $AdminPassword = $null

    Set-Location $OriginalLocation
}

Write-Output ""
Write-Host "Terraform deployment process completed" -ForegroundColor Green

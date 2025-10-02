#Requires -Version 7.4

<#
.SYNOPSIS
    Integrated Infrastructure as Code deployment script

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Combines PowerShell automation with IaC (Bicep/Terraform) for comprehensive
    Azure environment deployment and configuration.

.PARAMETER IaCTool
    Infrastructure as Code tool to use (Bicep or Terraform)

.PARAMETER Environment
    Target environment (dev, staging, prod)

.PARAMETER Location
    Azure region for deployment

.PARAMETER ResourceGroupName
    Name of the resource group (auto-generated if not provided)

.PARAMETER ConfigurePostDeployment
    Run post-deployment configuration scripts

.PARAMETER ValidateDeployment
    Validate deployment after completion

.EXAMPLE
    .\Deploy-WithIaC.ps1 -IaCTool Bicep -Environment dev -Location "East US"

.EXAMPLE
    .\Deploy-WithIaC.ps1 -IaCTool Terraform -Environment prod -ConfigurePostDeployment -ValidateDeployment

.NOTES
    Author: Azure PowerShell Toolkit Team
    Integrates: Bicep/Terraform + PowerShell automation
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Bicep', 'Terraform')]
    [string]$IaCTool,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter()]
    [string]$Location = 'East US',

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [switch]$ConfigurePostDeployment,

    [Parameter()]
    [switch]$ValidateDeployment
)
$ErrorActionPreference = 'Stop'
$RequiredModules = @('Az.Accounts', 'Az.Resources')
foreach ($module in $RequiredModules) {
    try {
        Import-Module $module -Force -ErrorAction Stop
    } catch {
        Write-Error "Required module $module not found. Install with: Install-Module -Name Az -Force"
        exit 1
    }
}

Write-Host "Azure PowerShell Toolkit - Integrated IaC Deployment" -ForegroundColor Green
Write-Host "IaC Tool: $IaCTool" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host ""
$ToolkitRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$IacPath = Join-Path $ToolkitRoot "iac"
$ScriptsPath = Join-Path $ToolkitRoot "scripts"

if (-not $ResourceGroupName) {
    $ResourceGroupName = "toolkit-$Environment-$(Get-Date -Format 'yyyyMMdd')-rg"
}

if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Green
    Connect-AzAccount
}
$context = Get-AzContext
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host ""

function Invoke-ToolkitScript {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{},
        [string]$Description
    )

    if ($Description) {
        Write-Host "Running: $Description" -ForegroundColor Green
    }

    if (-not (Test-Path $ScriptPath)) {
        Write-Warning "Script not found: $ScriptPath"
        return $false
    }

    try {
        & $ScriptPath @Parameters
        Write-Host "  Success: $Description" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Failed: $Description" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "Pre-deployment validation..." -ForegroundColor Green
$ValidationResults = @{
    AzureConnection = $null -ne (Get-AzContext)
    IaCToolAvailable = $false
    ScriptsAvailable = Test-Path $ScriptsPath
}

switch ($IaCTool) {
    'Bicep' {
        try {
            bicep --version | Out-Null
            $ValidationResults.IaCToolAvailable = $true
            Write-Host "  Bicep CLI: Available" -ForegroundColor Green
        } catch {
            Write-Host "  Bicep CLI: Not found" -ForegroundColor Yellow
            Write-Host "  Install from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install" -ForegroundColor Yellow
        }
    }
    'Terraform' {
        try {
            terraform version | Out-Null
            $ValidationResults.IaCToolAvailable = $true
            Write-Host "  Terraform CLI: Available" -ForegroundColor Green
        } catch {
            Write-Host "  Terraform CLI: Not found" -ForegroundColor Yellow
            Write-Host "  Install from: https://www.terraform.io/downloads" -ForegroundColor Yellow
        }
    }
}

if (-not $ValidationResults.IaCToolAvailable) {
    Write-Error "Required IaC tool not available. Cannot proceed."
    exit 1
}

Write-Host "  PowerShell scripts: $(if ($ValidationResults.ScriptsAvailable) { 'Available' } else { 'Not found' })" -ForegroundColor $(if ($ValidationResults.ScriptsAvailable) { 'Green' } else { 'Red' })
Write-Host ""

Write-Host "Deploying infrastructure with $IaCTool..." -ForegroundColor Green
$DeploymentSuccess = $false

switch ($IaCTool) {
    'Bicep' {
        $BicepScript = Join-Path $IacPath "bicep" "deploy.ps1"
        if (Test-Path $BicepScript) {
            $BicepParams = @{
                Environment = $Environment
                Location = $Location
                ResourceGroupName = $ResourceGroupName
            }

            if ($PSCmdlet.ShouldProcess("Bicep infrastructure", "Deploy")) {
                try {
                    & $BicepScript @bicepParams
                    $DeploymentSuccess = $LASTEXITCODE -eq 0
                } catch {
                    Write-Output "Bicep deployment failed: $($_.Exception.Message)" # Color: $2
                }
            }
        } else {
            Write-Warning "Bicep deployment script not found: $BicepScript"
        }
    }
    'Terraform' {
    [string]$TerraformScript = Join-Path $IacPath "terraform" "deploy.ps1"
        if (Test-Path $TerraformScript) {
    $TerraformParams = @{
                Environment = $Environment
                Location = $Location
            }

            if ($PSCmdlet.ShouldProcess("Terraform infrastructure", "Deploy")) {
                try {
                    & $TerraformScript @terraformParams
                    $DeploymentSuccess = $LASTEXITCODE -eq 0
                } catch {
                    Write-Output "Terraform deployment failed: $($_.Exception.Message)" # Color: $2
                }
            }
        } else {
            Write-Warning "Terraform deployment script not found: $TerraformScript"
        }
    }
}

if (-not $DeploymentSuccess) {
    Write-Error "Infrastructure deployment failed. Stopping execution."
    exit 1
}

Write-Output "Infrastructure deployment completed successfully" # Color: $2
Write-Output ""

if ($ConfigurePostDeployment) {
    Write-Output "Running post-deployment configuration..." # Color: $2
    [string]$ConfigurationTasks = @(
        @{
            Script = Join-Path $ScriptsPath "monitoring" "Azure-Resource-Health-Checker.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "Resource health validation"
        }
        @{
            Script = Join-Path $ScriptsPath "network" "Azure-KeyVault-Security-Monitor.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "Key Vault security configuration"
        }
        @{
            Script = Join-Path $ScriptsPath "compute" "Azure-VM-List-All.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "VM inventory and status check"
        }
        @{
            Script = Join-Path $ScriptsPath "storage" "Azure-Storage-Security-Audit.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "Storage security audit"
        }
    )
    [string]$ConfigSuccessCount = 0
    foreach ($task in $ConfigurationTasks) {
    [string]$success = Invoke-ToolkitScript -ScriptPath $task.Script -Parameters $task.Params -Description $task.Description
        if ($success) { $ConfigSuccessCount++ }
    }

    Write-Output "Post-deployment configuration: $ConfigSuccessCount/$($ConfigurationTasks.Count) tasks completed" -ForegroundColor $(if ($ConfigSuccessCount -eq $ConfigurationTasks.Count) { 'Green' } else { 'Yellow' })
    Write-Output ""
}

if ($ValidateDeployment) {
    Write-Output "Validating deployment..." # Color: $2

    try {
    [string]$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
        Write-Output "  Resource group: Found ($($ResourceGroup.Location))" # Color: $2
    [string]$resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        Write-Output "  Resources deployed: $($resources.Count)" # Color: $2
    [string]$ResourceTypes = $resources | Group-Object ResourceType | Sort-Object Count -Descending
        Write-Output "  Resource types:" # Color: $2
        foreach ($type in $ResourceTypes) {
            Write-Output "    $($type.Name): $($type.Count)" # Color: $2
        }
    [string]$ValidationScript = Join-Path $ScriptsPath "monitoring" "Azure-Resource-Health-Checker.ps1"
        if (Test-Path $ValidationScript) {
            Invoke-ToolkitScript -ScriptPath $ValidationScript -Parameters @{ ResourceGroupName = $ResourceGroupName } -Description "Comprehensive resource validation"
        }

        Write-Output "  Deployment validation: Passed" # Color: $2

    } catch {
        Write-Output "  Deployment validation: Failed" # Color: $2
        Write-Output "    Error: $($_.Exception.Message)" # Color: $2
    }

    Write-Output ""
}

Write-Output "Deployment Summary" # Color: $2
Write-Output "  IaC Tool: $IaCTool" # Color: $2
Write-Output "  Environment: $Environment" # Color: $2
Write-Output "  Location: $Location" # Color: $2
Write-Output "  Resource Group: $ResourceGroupName" # Color: $2
Write-Output "  Post-deployment config: $(if ($ConfigurePostDeployment) { 'Enabled' } else { 'Skipped' })" # Color: $2
Write-Output "  Validation: $(if ($ValidateDeployment) { 'Enabled' } else { 'Skipped' })" # Color: $2
Write-Output "  Deployment time: $(Get-Date)" # Color: $2

Write-Output ""
Write-Output "Next steps:" # Color: $2
Write-Output "1. Review deployed resources in Azure portal" # Color: $2
Write-Output "2. Configure monitoring and alerting" # Color: $2
Write-Output "3. Run additional PowerShell automation scripts as needed" # Color: $2
Write-Output "4. Set up CI/CD pipelines for ongoing management" # Color: $2

Write-Output ""
Write-Output "Integrated deployment completed successfully" # Color: $2



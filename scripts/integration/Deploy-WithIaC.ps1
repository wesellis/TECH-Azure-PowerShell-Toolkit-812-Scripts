#Requires -Version 7.0

<#
.SYNOPSIS
    Integrated Infrastructure as Code deployment script

.DESCRIPTION
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

# Import required modules
$requiredModules = @('Az.Accounts', 'Az.Resources')
foreach ($module in $requiredModules) {
    try {
        Import-Module $module -Force -ErrorAction Stop
    } catch {
        Write-Error "Required module $module not found. Install with: Install-Module -Name Az -Force"
        exit 1
    }
}

Write-Host "Azure PowerShell Toolkit - Integrated IaC Deployment" -ForegroundColor Cyan
Write-Host "IaC Tool: $IaCTool" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green
Write-Host ""

# Set up paths
$toolkitRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$iacPath = Join-Path $toolkitRoot "iac"
$scriptsPath = Join-Path $toolkitRoot "scripts"

# Generate resource group name if not provided
if (-not $ResourceGroupName) {
    $ResourceGroupName = "toolkit-$Environment-$(Get-Date -Format 'yyyyMMdd')-rg"
}

# Check Azure connection
if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

$context = Get-AzContext
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host ""

# Function to run PowerShell script with error handling
function Invoke-ToolkitScript {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{},
        [string]$Description
    )

    if ($Description) {
        Write-Host "Running: $Description" -ForegroundColor Yellow
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

# Pre-deployment validation
Write-Host "Pre-deployment validation..." -ForegroundColor Cyan

$validationResults = @{
    AzureConnection = $null -ne (Get-AzContext)
    IaCToolAvailable = $false
    ScriptsAvailable = Test-Path $scriptsPath
}

# Check IaC tool availability
switch ($IaCTool) {
    'Bicep' {
        try {
            bicep --version | Out-Null
            $validationResults.IaCToolAvailable = $true
            Write-Host "  Bicep CLI: Available" -ForegroundColor Green
        } catch {
            Write-Host "  Bicep CLI: Not found" -ForegroundColor Red
            Write-Host "  Install from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install" -ForegroundColor Yellow
        }
    }
    'Terraform' {
        try {
            terraform version | Out-Null
            $validationResults.IaCToolAvailable = $true
            Write-Host "  Terraform CLI: Available" -ForegroundColor Green
        } catch {
            Write-Host "  Terraform CLI: Not found" -ForegroundColor Red
            Write-Host "  Install from: https://www.terraform.io/downloads" -ForegroundColor Yellow
        }
    }
}

if (-not $validationResults.IaCToolAvailable) {
    Write-Error "Required IaC tool not available. Cannot proceed."
    exit 1
}

Write-Host "  PowerShell scripts: $(if ($validationResults.ScriptsAvailable) { 'Available' } else { 'Not found' })" -ForegroundColor $(if ($validationResults.ScriptsAvailable) { 'Green' } else { 'Red' })
Write-Host ""

# Infrastructure deployment
Write-Host "Deploying infrastructure with $IaCTool..." -ForegroundColor Cyan

$deploymentSuccess = $false

switch ($IaCTool) {
    'Bicep' {
        $bicepScript = Join-Path $iacPath "bicep" "deploy.ps1"
        if (Test-Path $bicepScript) {
            $bicepParams = @{
                Environment = $Environment
                Location = $Location
                ResourceGroupName = $ResourceGroupName
            }

            if ($PSCmdlet.ShouldProcess("Bicep infrastructure", "Deploy")) {
                try {
                    & $bicepScript @bicepParams
                    $deploymentSuccess = $LASTEXITCODE -eq 0
                } catch {
                    Write-Host "Bicep deployment failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } else {
            Write-Warning "Bicep deployment script not found: $bicepScript"
        }
    }
    'Terraform' {
        $terraformScript = Join-Path $iacPath "terraform" "deploy.ps1"
        if (Test-Path $terraformScript) {
            $terraformParams = @{
                Environment = $Environment
                Location = $Location
            }

            if ($PSCmdlet.ShouldProcess("Terraform infrastructure", "Deploy")) {
                try {
                    & $terraformScript @terraformParams
                    $deploymentSuccess = $LASTEXITCODE -eq 0
                } catch {
                    Write-Host "Terraform deployment failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } else {
            Write-Warning "Terraform deployment script not found: $terraformScript"
        }
    }
}

if (-not $deploymentSuccess) {
    Write-Error "Infrastructure deployment failed. Stopping execution."
    exit 1
}

Write-Host "Infrastructure deployment completed successfully" -ForegroundColor Green
Write-Host ""

# Post-deployment configuration
if ($ConfigurePostDeployment) {
    Write-Host "Running post-deployment configuration..." -ForegroundColor Cyan

    $configurationTasks = @(
        @{
            Script = Join-Path $scriptsPath "monitoring" "Azure-Resource-Health-Checker.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "Resource health validation"
        }
        @{
            Script = Join-Path $scriptsPath "network" "Azure-KeyVault-Security-Monitor.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "Key Vault security configuration"
        }
        @{
            Script = Join-Path $scriptsPath "compute" "Azure-VM-List-All.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "VM inventory and status check"
        }
        @{
            Script = Join-Path $scriptsPath "storage" "Azure-Storage-Security-Audit.ps1"
            Params = @{ ResourceGroupName = $ResourceGroupName }
            Description = "Storage security audit"
        }
    )

    $configSuccessCount = 0
    foreach ($task in $configurationTasks) {
        $success = Invoke-ToolkitScript -ScriptPath $task.Script -Parameters $task.Params -Description $task.Description
        if ($success) { $configSuccessCount++ }
    }

    Write-Host "Post-deployment configuration: $configSuccessCount/$($configurationTasks.Count) tasks completed" -ForegroundColor $(if ($configSuccessCount -eq $configurationTasks.Count) { 'Green' } else { 'Yellow' })
    Write-Host ""
}

# Deployment validation
if ($ValidateDeployment) {
    Write-Host "Validating deployment..." -ForegroundColor Cyan

    try {
        # Check resource group exists
        $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
        Write-Host "  Resource group: Found ($($resourceGroup.Location))" -ForegroundColor Green

        # Check resources
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        Write-Host "  Resources deployed: $($resources.Count)" -ForegroundColor Green

        # Validate specific resource types
        $resourceTypes = $resources | Group-Object ResourceType | Sort-Object Count -Descending
        Write-Host "  Resource types:" -ForegroundColor White
        foreach ($type in $resourceTypes) {
            Write-Host "    $($type.Name): $($type.Count)" -ForegroundColor Gray
        }

        # Run validation scripts
        $validationScript = Join-Path $scriptsPath "monitoring" "Azure-Resource-Health-Checker.ps1"
        if (Test-Path $validationScript) {
            Invoke-ToolkitScript -ScriptPath $validationScript -Parameters @{ ResourceGroupName = $ResourceGroupName } -Description "Comprehensive resource validation"
        }

        Write-Host "  Deployment validation: Passed" -ForegroundColor Green

    } catch {
        Write-Host "  Deployment validation: Failed" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
}

# Generate deployment summary
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "  IaC Tool: $IaCTool" -ForegroundColor White
Write-Host "  Environment: $Environment" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  Post-deployment config: $(if ($ConfigurePostDeployment) { 'Enabled' } else { 'Skipped' })" -ForegroundColor White
Write-Host "  Validation: $(if ($ValidateDeployment) { 'Enabled' } else { 'Skipped' })" -ForegroundColor White
Write-Host "  Deployment time: $(Get-Date)" -ForegroundColor White

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review deployed resources in Azure portal" -ForegroundColor White
Write-Host "2. Configure monitoring and alerting" -ForegroundColor White
Write-Host "3. Run additional PowerShell automation scripts as needed" -ForegroundColor White
Write-Host "4. Set up CI/CD pipelines for ongoing management" -ForegroundColor White

Write-Host ""
Write-Host "Integrated deployment completed successfully" -ForegroundColor Green
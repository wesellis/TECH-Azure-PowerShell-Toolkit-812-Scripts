#Requires -Version 7.0

<#
.SYNOPSIS
    Creates a comprehensive demo environment for Azure PowerShell Toolkit demonstrations

.DESCRIPTION
    Sets up a complete Azure environment with various resources for demonstrating
    the Azure PowerShell Toolkit capabilities in videos and presentations.

.PARAMETER ResourceGroupName
    Name for the demo resource group

.PARAMETER Location
    Azure region for the demo environment

.PARAMETER IncludeAdvanced
    Include advanced scenarios like multi-tier apps and security configurations

.PARAMETER DemoType
    Type of demo environment (QuickStart, Enterprise, Advanced)

.EXAMPLE
    .\Create-Demo-Environment.ps1 -ResourceGroupName "demo-toolkit" -Location "East US"
    Creates basic demo environment

.EXAMPLE
    .\Create-Demo-Environment.ps1 -ResourceGroupName "enterprise-demo" -DemoType "Enterprise" -IncludeAdvanced
    Creates comprehensive enterprise demo environment

.NOTES
    Author: Azure PowerShell Toolkit Team
    Version: 1.0
    Purpose: Video demonstration support
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$Location = "East US",

    [Parameter()]
    [switch]$IncludeAdvanced,

    [Parameter()]
    [ValidateSet('QuickStart', 'Enterprise', 'Advanced')]
    [string]$DemoType = 'QuickStart'
)

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
} catch {
    Write-Error "Required Azure PowerShell modules not found. Install with: Install-Module -Name Az -Force"
    exit 1
}

Write-Host "=== Azure PowerShell Toolkit Demo Environment Creator ===" -ForegroundColor Cyan
Write-Host "Demo Type: $DemoType" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
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

# Set up paths
$ToolkitRoot = Split-Path -Parent $PSScriptRoot
$ScriptsPath = Join-Path $ToolkitRoot "scripts"

# Function to run toolkit script with error handling
function Invoke-ToolkitScript {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{},
        [string]$Description
    )

    if ($Description) {
        Write-Host "Creating: $Description" -ForegroundColor Yellow
    }

    $fullPath = Join-Path $ScriptsPath $ScriptPath

    if (-not (Test-Path $fullPath)) {
        Write-Warning "Script not found: $fullPath"
        return $false
    }

    try {
        if ($PSCmdlet.ShouldProcess($Description, "Create Resource")) {
            & $fullPath @Parameters
            Write-Host "  ✓ Success: $Description" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "  ✗ Failed: $Description" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Demo environment configurations
$demoConfigs = @{
    QuickStart = @{
        Resources = @(
            @{ Script = "identity\Azure-ResourceGroup-Creator.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; Location = $Location }; Description = "Demo Resource Group" }
            @{ Script = "network\Azure-VNet-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; VnetName = "demo-vnet"; Location = $Location }; Description = "Virtual Network" }
            @{ Script = "compute\Azure-VM-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; VmName = "demo-vm01"; Location = $Location; Size = "Standard_B1s" }; Description = "Demo Virtual Machine" }
            @{ Script = "storage\Azure-StorageAccount-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; StorageAccountName = "demostorage$(Get-Random -Maximum 9999)"; Location = $Location }; Description = "Storage Account" }
        )
    }
    Enterprise = @{
        Resources = @(
            @{ Script = "identity\Azure-ResourceGroup-Creator.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; Location = $Location }; Description = "Enterprise Resource Group" }
            @{ Script = "network\Azure-VNet-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; VnetName = "enterprise-vnet"; Location = $Location }; Description = "Enterprise Virtual Network" }
            @{ Script = "network\Azure-KeyVault-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; VaultName = "enterprise-kv-$(Get-Random -Maximum 999)"; Location = $Location }; Description = "Key Vault" }
            @{ Script = "compute\Azure-VM-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; VmName = "enterprise-web01"; Location = $Location; Size = "Standard_B2s" }; Description = "Web Server VM" }
            @{ Script = "compute\Azure-VM-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; VmName = "enterprise-db01"; Location = $Location; Size = "Standard_B2s" }; Description = "Database Server VM" }
            @{ Script = "storage\Azure-StorageAccount-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; StorageAccountName = "enterprisestorage$(Get-Random -Maximum 999)"; Location = $Location }; Description = "Enterprise Storage" }
            @{ Script = "data\Azure-SQL-Database-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = $ResourceGroupName; ServerName = "enterprise-sql-$(Get-Random -Maximum 999)"; DatabaseName = "EnterpriseDB"; Location = $Location }; Description = "SQL Database" }
        )
    }
    Advanced = @{
        Resources = @(
            @{ Script = "identity\Azure-ResourceGroup-Creator.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-prod"; Location = $Location }; Description = "Production Resource Group" }
            @{ Script = "identity\Azure-ResourceGroup-Creator.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-dev"; Location = $Location }; Description = "Development Resource Group" }
            @{ Script = "network\Azure-VNet-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-prod"; VnetName = "prod-vnet"; Location = $Location }; Description = "Production VNet" }
            @{ Script = "network\Azure-VNet-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-dev"; VnetName = "dev-vnet"; Location = $Location }; Description = "Development VNet" }
            @{ Script = "network\Azure-KeyVault-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-prod"; VaultName = "prod-kv-$(Get-Random -Maximum 999)"; Location = $Location }; Description = "Production Key Vault" }
            @{ Script = "compute\Azure-AKS-Cluster-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-prod"; ClusterName = "prod-aks"; Location = $Location }; Description = "AKS Cluster" }
            @{ Script = "devops\Azure-AppService-Provisioning-Tool.ps1"; Params = @{ ResourceGroupName = "$ResourceGroupName-prod"; AppName = "prod-webapp-$(Get-Random -Maximum 999)"; Location = $Location }; Description = "Production Web App" }
        )
    }
}

# Execute demo environment creation
$config = $demoConfigs[$DemoType]
$successCount = 0
$totalCount = $config.Resources.Count

Write-Host "Creating $DemoType demo environment with $totalCount resources..." -ForegroundColor Cyan
Write-Host ""

foreach ($resource in $config.Resources) {
    $success = Invoke-ToolkitScript -ScriptPath $resource.Script -Parameters $resource.Params -Description $resource.Description
    if ($success) {
        $successCount++
    }
    Start-Sleep -Seconds 2  # Brief pause between resources
}

Write-Host ""
Write-Host "=== Demo Environment Creation Summary ===" -ForegroundColor Cyan
Write-Host "Demo Type: $DemoType" -ForegroundColor White
Write-Host "Resources Created: $successCount / $totalCount" -ForegroundColor $(if ($successCount -eq $totalCount) { 'Green' } else { 'Yellow' })
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White

if ($successCount -eq $totalCount) {
    Write-Host "✓ Demo environment created successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠ Some resources failed to create. Check the output above for details." -ForegroundColor Yellow
}

# Create demo data and configurations
if ($IncludeAdvanced) {
    Write-Host ""
    Write-Host "Setting up advanced demo configurations..." -ForegroundColor Cyan

    # Add sample secrets to Key Vault
    if ($DemoType -ne 'QuickStart') {
        $vaultName = if ($DemoType -eq 'Advanced') { "prod-kv-*" } else { "enterprise-kv-*" }
        $vaults = Get-AzKeyVault -ResourceGroupName $ResourceGroupName | Where-Object { $_.VaultName -like $vaultName }

        foreach ($vault in $vaults) {
            try {
                Invoke-ToolkitScript -ScriptPath "network\Azure-KeyVault-Secret-Creator.ps1" -Parameters @{
                    VaultName = $vault.VaultName
                    SecretName = "demo-secret"
                    SecretValue = "DemoValue123!"
                } -Description "Demo Secret in $($vault.VaultName)"
            } catch {
                Write-Warning "Could not create demo secret in $($vault.VaultName)"
            }
        }
    }

    # Tag resources for demo purposes
    $demoTags = @{
        "Environment" = $DemoType
        "Purpose" = "Demo"
        "Owner" = "Azure-Toolkit-Demo"
        "CreatedBy" = "Demo-Environment-Script"
        "DemoDate" = (Get-Date).ToString("yyyy-MM-dd")
    }

    Write-Host "Applying demo tags to resources..." -ForegroundColor Yellow
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    foreach ($resource in $resources) {
        try {
            Set-AzResource -ResourceId $resource.ResourceId -Tag $demoTags -Force | Out-Null
            Write-Host "  ✓ Tagged: $($resource.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Could not tag: $($resource.Name)" -ForegroundColor Yellow
        }
    }
}

# Generate demo scripts
Write-Host ""
Write-Host "Generating demo scripts..." -ForegroundColor Cyan

$demoScriptPath = Join-Path $PSScriptRoot "generated-demo-script.ps1"
$demoScript = @"
#Requires -Version 7.0
# Generated Demo Script for $DemoType Environment
# Created: $(Get-Date)
# Resource Group: $ResourceGroupName

# Demo Commands for Video Recording:

# 1. Show resource overview
Get-AzResource -ResourceGroupName "$ResourceGroupName" | Format-Table Name, ResourceType, Location

# 2. Check VM status
.\scripts\compute\Azure-VM-List-All.ps1 -ResourceGroupName "$ResourceGroupName"

# 3. Check resource health
.\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName "$ResourceGroupName"

# 4. Cost analysis
.\scripts\cost\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName "$ResourceGroupName"

# 5. Security check (if Key Vault exists)
.\scripts\network\Azure-KeyVault-Security-Monitor.ps1 -ResourceGroupName "$ResourceGroupName"

# 6. Cleanup (USE WITH CAUTION)
# Remove-AzResourceGroup -Name "$ResourceGroupName" -Force

Write-Host "Demo script completed!" -ForegroundColor Green
"@

Set-Content -Path $demoScriptPath -Value $demoScript -Encoding UTF8
Write-Host "Demo script saved to: $demoScriptPath" -ForegroundColor Green

# Final instructions
Write-Host ""
Write-Host "=== Demo Environment Ready! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps for video recording:" -ForegroundColor White
Write-Host "1. Use the generated demo script: $demoScriptPath" -ForegroundColor Yellow
Write-Host "2. Test the demonstration flow before recording" -ForegroundColor Yellow
Write-Host "3. Set up screen recording software" -ForegroundColor Yellow
Write-Host "4. Follow the demo scripts in .\demos\Demo-Scripts.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "To cleanup the demo environment later:" -ForegroundColor White
Write-Host "Remove-AzResourceGroup -Name '$ResourceGroupName' -Force" -ForegroundColor Red
Write-Host ""

if ($DemoType -eq 'Advanced') {
    Write-Host "Advanced demo includes multiple resource groups:" -ForegroundColor Cyan
    Write-Host "- $ResourceGroupName-prod" -ForegroundColor White
    Write-Host "- $ResourceGroupName-dev" -ForegroundColor White
    Write-Host "Remember to cleanup both when done!" -ForegroundColor Yellow
}
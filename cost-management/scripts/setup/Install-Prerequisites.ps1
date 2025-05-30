<#
.SYNOPSIS
    Installs all prerequisites for the Azure Cost Management Dashboard.

.DESCRIPTION
    This script automatically installs all required PowerShell modules and dependencies
    needed to run the Azure Cost Management Dashboard.

.PARAMETER IncludeDevTools
    Include development tools like VS Code extensions and Node.js packages.

.PARAMETER Force
    Force reinstall of modules even if they already exist.

.EXAMPLE
    .\Install-Prerequisites.ps1

.EXAMPLE
    .\Install-Prerequisites.ps1 -IncludeDevTools -Force

.NOTES
    Author: Wesley Ellis
    Email: wes@wesellis.com
    Created: May 23, 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [switch]$IncludeDevTools,
    [switch]$Force
)

Write-Host "Azure Cost Management Dashboard - Prerequisites Installer" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "For best results, run this script as Administrator to install modules for all users."
}

# Required modules
$requiredModules = @(
    @{ Name = "Az"; Description = "Azure PowerShell module" },
    @{ Name = "Az.Accounts"; Description = "Azure authentication" },
    @{ Name = "Az.CostManagement"; Description = "Azure Cost Management APIs" },
    @{ Name = "Az.Resources"; Description = "Azure resource management" },
    @{ Name = "ImportExcel"; Description = "Excel file generation" },
    @{ Name = "PSWriteHTML"; Description = "HTML report generation" }
)

# Optional development modules
$devModules = @(
    @{ Name = "Pester"; Description = "PowerShell testing framework" },
    @{ Name = "PSScriptAnalyzer"; Description = "PowerShell code analysis" },
    @{ Name = "platyPS"; Description = "Documentation generation" }
)

function Install-ModuleIfMissing {
    param(
        [string]$ModuleName,
        [string]$Description,
        [switch]$ForceInstall
    )
    
    Write-Host "Checking module: $ModuleName ($Description)" -ForegroundColor Yellow
    
    $existingModule = Get-Module -Name $ModuleName -ListAvailable
    
    if ($existingModule -and -not $ForceInstall) {
        Write-Host "  ✓ $ModuleName already installed (version $($existingModule[0].Version))" -ForegroundColor Green
        return
    }
    
    try {
        Write-Host "  → Installing $ModuleName..." -ForegroundColor Blue
        
        $installParams = @{
            Name = $ModuleName
            Repository = "PSGallery"
            Force = $true
            AllowClobber = $true
            ErrorAction = "Stop"
        }
        
        if ($isAdmin) {
            $installParams.Scope = "AllUsers"
        } else {
            $installParams.Scope = "CurrentUser"
        }
        
        Install-Module @installParams
        Write-Host "  ✓ $ModuleName installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "  ✗ Failed to install $ModuleName`: $($_.Exception.Message)"
    }
}

# Update PowerShellGet first
Write-Host "`nUpdating PowerShellGet..." -ForegroundColor Cyan
try {
    Install-Module PowerShellGet -Force -AllowClobber -ErrorAction Stop
    Write-Host "✓ PowerShellGet updated" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to update PowerShellGet: $($_.Exception.Message)"
}

# Install required modules
Write-Host "`nInstalling required modules..." -ForegroundColor Cyan
foreach ($module in $requiredModules) {
    Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
}

# Install development modules if requested
if ($IncludeDevTools) {
    Write-Host "`nInstalling development modules..." -ForegroundColor Cyan
    foreach ($module in $devModules) {
        Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
    }
}

# Verify installations
Write-Host "`nVerifying installations..." -ForegroundColor Cyan
$allModules = $requiredModules
if ($IncludeDevTools) {
    $allModules += $devModules
}

$installationResults = @()
foreach ($module in $allModules) {
    $installed = Get-Module -Name $module.Name -ListAvailable
    if ($installed) {
        Write-Host "✓ $($module.Name) - Version $($installed[0].Version)" -ForegroundColor Green
        $installationResults += @{ Module = $module.Name; Status = "Installed"; Version = $installed[0].Version }
    } else {
        Write-Host "✗ $($module.Name) - Not found" -ForegroundColor Red
        $installationResults += @{ Module = $module.Name; Status = "Failed"; Version = "N/A" }
    }
}

# Create directories if they don't exist
Write-Host "`nCreating directory structure..." -ForegroundColor Cyan
$directories = @(
    "config",
    "logs",
    "data\exports",
    "data\templates",
    "reports"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✓ Created directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "✓ Directory exists: $dir" -ForegroundColor Green
    }
}

# Create sample configuration
Write-Host "`nCreating sample configuration..." -ForegroundColor Cyan
$sampleConfig = @{
    azure = @{
        subscriptionId = "your-subscription-id"
        tenantId = "your-tenant-id"
        resourceGroups = @("Production-RG", "Development-RG")
        excludedServices = @("Microsoft.Insights")
    }
    dashboard = @{
        refreshSchedule = "Daily"
        dataRetentionDays = 90
        currencyCode = "USD"
    }
    notifications = @{
        enabled = $true
        emailRecipients = @("finance@company.com")
        budgetThresholds = @(50, 80, 95)
    }
    exports = @{
        autoExport = $true
        formats = @("Excel", "CSV")
        exportPath = "data\exports"
    }
}

$configPath = "config\sample-config.json"
if (-not (Test-Path $configPath)) {
    $sampleConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "✓ Created sample configuration: $configPath" -ForegroundColor Green
} else {
    Write-Host "✓ Sample configuration exists: $configPath" -ForegroundColor Green
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$successCount = ($installationResults | Where-Object { $_.Status -eq "Installed" }).Count
$totalCount = $installationResults.Count

Write-Host "Modules installed: $successCount/$totalCount" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

foreach ($result in $installationResults) {
    $color = if ($result.Status -eq "Installed") { "Green" } else { "Red" }
    Write-Host "  $($result.Module): $($result.Status) $($result.Version)" -ForegroundColor $color
}

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 Installation completed successfully!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Copy config\sample-config.json to config\config.json and update with your details"
    Write-Host "2. Run Connect-AzAccount to authenticate to Azure"
    Write-Host "3. Test the installation with: .\scripts\data-collection\Get-AzureCostData.ps1 -Days 7"
    Write-Host "4. Check the Installation Guide in docs\Installation-Guide.md for detailed setup"
} else {
    Write-Host "`n⚠️  Installation completed with warnings. Please review failed modules above." -ForegroundColor Yellow
    Write-Host "You may need to install failed modules manually or run this script as Administrator."
}

Write-Host "`n📧 Support: wes@wesellis.com" -ForegroundColor Blue
Write-Host "🌐 Documentation: https://github.com/wesellis/Azure-Cost-Management-Dashboard" -ForegroundColor Blue

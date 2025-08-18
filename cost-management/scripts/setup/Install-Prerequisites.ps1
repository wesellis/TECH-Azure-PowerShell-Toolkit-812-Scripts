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

Write-Information "Azure Cost Management Dashboard - Prerequisites Installer"
Write-Information "============================================================"

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

[CmdletBinding()]
function Install-ModuleIfMissing {
    param(
        [string]$ModuleName,
        [string]$Description,
        [switch]$ForceInstall
    )
    
    Write-Information "Checking module: $ModuleName ($Description)"
    
    $existingModule = Get-Module -Name $ModuleName -ListAvailable
    
    if ($existingModule -and -not $ForceInstall) {
        Write-Information "  ✓ $ModuleName already installed (version $($existingModule[0].Version))"
        return
    }
    
    try {
        Write-Information "  → Installing $ModuleName..."
        
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
        Write-Information "  ✓ $ModuleName installed successfully"
    }
    catch {
        Write-Error "  ✗ Failed to install $ModuleName`: $($_.Exception.Message)"
    }
}

# Update PowerShellGet first
Write-Information "`nUpdating PowerShellGet..."
try {
    Install-Module PowerShellGet -Force -AllowClobber -ErrorAction Stop
    Write-Information "✓ PowerShellGet updated"
}
catch {
    Write-Warning "Failed to update PowerShellGet: $($_.Exception.Message)"
}

# Install required modules
Write-Information "`nInstalling required modules..."
foreach ($module in $requiredModules) {
    Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
}

# Install development modules if requested
if ($IncludeDevTools) {
    Write-Information "`nInstalling development modules..."
    foreach ($module in $devModules) {
        Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
    }
}

# Verify installations
Write-Information "`nVerifying installations..."
$allModules = $requiredModules
if ($IncludeDevTools) {
    $allModules += $devModules
}

$installationResults = @()
foreach ($module in $allModules) {
    $installed = Get-Module -Name $module.Name -ListAvailable
    if ($installed) {
        Write-Information "✓ $($module.Name) - Version $($installed[0].Version)"
        $installationResults += @{ Module = $module.Name; Status = "Installed"; Version = $installed[0].Version }
    } else {
        Write-Information "✗ $($module.Name) - Not found"
        $installationResults += @{ Module = $module.Name; Status = "Failed"; Version = "N/A" }
    }
}

# Create directories if they don't exist
Write-Information "`nCreating directory structure..."
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
        Write-Information "✓ Created directory: $dir"
    } else {
        Write-Information "✓ Directory exists: $dir"
    }
}

# Create sample configuration
Write-Information "`nCreating sample configuration..."
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
    Write-Information "✓ Created sample configuration: $configPath"
} else {
    Write-Information "✓ Sample configuration exists: $configPath"
}

# Summary
Write-Information "`n" + "="*60 -ForegroundColor Cyan
Write-Information "INSTALLATION SUMMARY"
Write-Information "="*60 -ForegroundColor Cyan

$successCount = ($installationResults | Where-Object { $_.Status -eq "Installed" }).Count
$totalCount = $installationResults.Count

Write-Information "Modules installed: $successCount/$totalCount" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

foreach ($result in $installationResults) {
    $color = if ($result.Status -eq "Installed") { "Green" } else { "Red" }
    Write-Information "  $($result.Module): $($result.Status) $($result.Version)" -ForegroundColor $color
}

if ($successCount -eq $totalCount) {
    Write-Information "`n🎉 Installation completed successfully!"
    Write-Information "`nNext steps:"
    Write-Information "1. Copy config\sample-config.json to config\config.json and update with your details"
    Write-Information "2. Run Connect-AzAccount to authenticate to Azure"
    Write-Information "3. Test the installation with: .\scripts\data-collection\Get-AzureCostData.ps1 -Days 7"
    Write-Information "4. Check the Installation Guide in docs\Installation-Guide.md for detailed setup"
} else {
    Write-Information "`n⚠️  Installation completed with warnings. Please review failed modules above."
    Write-Information "You may need to install failed modules manually or run this script as Administrator."
}

Write-Information "`n📧 Support: wes@wesellis.com"
Write-Information "🌐 Documentation: https://github.com/wesellis/Azure-Cost-Management-Dashboard"

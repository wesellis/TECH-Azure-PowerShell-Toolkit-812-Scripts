#Requires -Version 5.1
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Installs all prerequisites for the Azure Cost Management Dashboard

.DESCRIPTION
    This script automatically installs all required PowerShell modules and dependencies
    needed to run the Azure Cost Management Dashboard. Handles both user and admin-level
    installations with proper error handling and verification.

.PARAMETER IncludeDevTools
    Include development tools like Pester, PSScriptAnalyzer, and platyPS

.PARAMETER Force
    Force reinstall of modules even if they already exist

.EXAMPLE
    .\Install-Prerequisites.ps1

    Installs basic required modules for current user

.EXAMPLE
    .\Install-Prerequisites.ps1 -IncludeDevTools -Force

    Force reinstalls all modules including development tools

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0.0
    Created: 2024-11-15
    LastModified: 2025-09-19
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$IncludeDevTools,

    [Parameter()]
    [switch]$Force
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Check if running as administrator
$script:isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Required modules
$script:requiredModules = @(
    @{ Name = "Az"; Description = "Azure PowerShell module" },
    @{ Name = "Az.Accounts"; Description = "Azure authentication" },
    @{ Name = "Az.CostManagement"; Description = "Azure Cost Management APIs" },
    @{ Name = "Az.Resources"; Description = "Azure resource management" },
    @{ Name = "ImportExcel"; Description = "Excel file generation" },
    @{ Name = "PSWriteHTML"; Description = "HTML report generation" }
)

# Optional development modules
$script:devModules = @(
    @{ Name = "Pester"; Description = "PowerShell testing framework" },
    @{ Name = "PSScriptAnalyzer"; Description = "PowerShell code analysis" },
    @{ Name = "platyPS"; Description = "Documentation generation" }
)
#endregion

#region Functions

function Install-ModuleIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter()]
        [switch]$ForceInstall
    )
    
    Write-Host "Checking module: $ModuleName ($Description)"
    
    $existingModule = Get-Module -Name $ModuleName -ListAvailable
    
    if ($existingModule -and -not $ForceInstall) {
        Write-Host "  [OK] $ModuleName already installed (version $($existingModule[0].Version))"
        return
    }
    
    try {
        Write-Host "  -> Installing $ModuleName..."
        
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
        Write-Host "  [OK] $ModuleName installed successfully"
    }
    catch {
        Write-Error "  [FAIL] Failed to install $ModuleName`: $($_.Exception.Message)"
    }
}
#endregion

#region Main-Execution
try {
    Write-Host "Azure Cost Management Dashboard - Prerequisites Installer" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor White

    if (-not $script:isAdmin) {
        Write-Warning "For best results, run this script as Administrator to install modules for all users."
    }

    # Update PowerShellGet first
Write-Host "`nUpdating PowerShellGet..."
try {
    Install-Module PowerShellGet -Force -AllowClobber -ErrorAction Stop
    Write-Host "[OK] PowerShellGet updated"
}
catch {
    Write-Warning "Failed to update PowerShellGet: $($_.Exception.Message)"
}

# Install required modules
Write-Host "`nInstalling required modules..."
foreach ($module in $requiredModules) {
    Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
}

# Install development modules if requested
if ($IncludeDevTools) {
    Write-Host "`nInstalling development modules..."
    foreach ($module in $devModules) {
        Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
    }
}

# Verify installations
Write-Host "`nVerifying installations..."
$allModules = $requiredModules
if ($IncludeDevTools) {
    $allModules += $devModules
}

$installationResults = @()
foreach ($module in $allModules) {
    $installed = Get-Module -Name $module.Name -ListAvailable
    if ($installed) {
        Write-Host "[OK] $($module.Name) - Version $($installed[0].Version)"
        $installationResults += @{ Module = $module.Name; Status = "Installed"; Version = $installed[0].Version }
    } else {
        Write-Host "[FAIL] $($module.Name) - Not found"
        $installationResults += @{ Module = $module.Name; Status = "Failed"; Version = "N/A" }
    }
}

# Create directories if they don't exist
Write-Host "`nCreating directory structure..."
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
        Write-Host "[OK] Created directory: $dir"
    } else {
        Write-Host "[OK] Directory exists: $dir"
    }
}

# Create sample configuration
Write-Host "`nCreating sample configuration..."
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
    Write-Host "[OK] Created sample configuration: $configPath"
} else {
    Write-Host "[OK] Sample configuration exists: $configPath"
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "INSTALLATION SUMMARY"
Write-Host "="*60 -ForegroundColor Cyan

$successCount = ($installationResults | Where-Object { $_.Status -eq "Installed" }).Count
$totalCount = $installationResults.Count

Write-Host "Modules installed: $successCount/$totalCount" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

foreach ($result in $installationResults) {
    $color = if ($result.Status -eq "Installed") { "Green" } else { "Red" }
    Write-Host "  $($result.Module): $($result.Status) $($result.Version)" -ForegroundColor $color
}

if ($successCount -eq $totalCount) {
    Write-Host "`n Installation completed successfully!"
    Write-Host "`nNext steps:"
    Write-Host "1. Copy config\sample-config.json to config\config.json and update with your details"
    Write-Host "2. Run Connect-AzAccount to authenticate to Azure"
    Write-Host "3. Test the installation with: .\scripts\data-collection\Get-AzureCostData.ps1 -Days 7"
    Write-Host "4. Check the Installation Guide in docs\Installation-Guide.md for detailed setup"
} else {
    Write-Host "`n[WARN]  Installation completed with warnings. Please review failed modules above."
    Write-Host "You may need to install failed modules manually or run this script as Administrator."
}

Write-Host "`n� Support: wes@wesellis.com"
Write-Host "� Documentation: https://github.com/wesellis/Azure-Cost-Management-Dashboard"


#endregion

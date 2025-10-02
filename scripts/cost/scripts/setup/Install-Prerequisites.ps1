#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Install Prerequisites
.DESCRIPTION
    Install Prerequisites operation


    Author: Wes Ellis (wes@wesellis.com)

    Installs all prerequisites for the Azure Cost Management Dashboard

    This script automatically installs all required PowerShell modules and dependencies
    needed to run the Azure Cost Management Dashboard. Handles both user and admin-level
    installations with proper error handling and verification.
.PARAMETER IncludeDevTools
    Include development tools like Pester, PSScriptAnalyzer, and platyPS
.PARAMETER Force
    Force reinstall of modules even if they already exist

    .\Install-Prerequisites.ps1

    Installs basic required modules for current user

    .\Install-Prerequisites.ps1 -IncludeDevTools -Force

    Force reinstalls all modules including development tools

    Author: Wes Ellis (wes@wesellis.com)

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$IncludeDevTools,

    [Parameter()]
    [switch]$Force
)
    [string]$ErrorActionPreference = 'Stop'
    [string]$ProgressPreference = 'SilentlyContinue'
    [string]$script:isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    [string]$script:requiredModules = @(
    @{ Name = "Az"; Description = "Azure PowerShell module" },
    @{ Name = "Az.Accounts"; Description = "Azure authentication" },
    @{ Name = "Az.CostManagement"; Description = "Azure Cost Management APIs" },
    @{ Name = "Az.Resources"; Description = "Azure resource management" },
    @{ Name = "ImportExcel"; Description = "Excel file generation" },
    @{ Name = "PSWriteHTML"; Description = "HTML report generation" }
)
    [string]$script:devModules = @(
    @{ Name = "Pester"; Description = "PowerShell testing framework" },
    @{ Name = "PSScriptAnalyzer"; Description = "PowerShell code analysis" },
    @{ Name = "platyPS"; Description = "Documentation generation" }
)


function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter()]
        [switch]$ForceInstall
    )

    Write-Output "Checking module: $ModuleName ($Description)"
$ExistingModule = Get-Module -Name $ModuleName -ListAvailable

    if ($ExistingModule -and -not $ForceInstall) {
        Write-Output "  [OK] $ModuleName already installed (version $($ExistingModule[0].Version))"
        return
    }

    try {
        Write-Output "  -> Installing $ModuleName..."
$InstallParams = @{
            Name = $ModuleName
            Repository = "PSGallery"
            Force = $true
            AllowClobber = $true
            ErrorAction = "Stop"
        }

        if ($script:isAdmin) {
    [string]$InstallParams.Scope = "AllUsers"
        } else {
    [string]$InstallParams.Scope = "CurrentUser"
        }

        Install-Module @installParams
        Write-Output "  [OK] $ModuleName installed successfully"
    }
    catch {
        Write-Error "  [FAIL] Failed to install $ModuleName`: $($_.Exception.Message)"
    }
}


try {
    Write-Host "Azure Cost Management Dashboard - Prerequisites Installer" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green

    if (-not $script:isAdmin) {
        Write-Warning "For best results, run this script as Administrator to install modules for all users."
    }

    Write-Host "`nUpdating PowerShellGet..." -ForegroundColor Green
    try {
        Install-Module PowerShellGet -Force -AllowClobber -ErrorAction Stop
        Write-Host "    [OK] PowerShellGet updated" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to update PowerShellGet: $($_.Exception.Message)"
    }

    Write-Host "`nInstalling required modules..." -ForegroundColor Green
    foreach ($module in $script:requiredModules) {
    Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
}

    if ($IncludeDevTools) {
        Write-Host "`nInstalling development modules..." -ForegroundColor Green
        foreach ($module in $script:devModules) {
        Install-ModuleIfMissing -ModuleName $module.Name -Description $module.Description -ForceInstall:$Force
    }
}

    Write-Host "`nVerifying installations..." -ForegroundColor Green
    [string]$AllModules = $script:requiredModules
    if ($IncludeDevTools) {
    [string]$AllModules += $script:devModules
    }
    [string]$InstallationResults = @()
    foreach ($module in $AllModules) {
$installed = Get-Module -Name $module.Name -ListAvailable
        if ($installed) {
            Write-Host "    [OK] $($module.Name) - Version $($installed[0].Version)" -ForegroundColor Green
    [string]$InstallationResults += @{ Module = $module.Name; Status = "Installed"; Version = $installed[0].Version }
        }
        else {
            Write-Host "    [FAIL] $($module.Name) - Not found" -ForegroundColor Green
    [string]$InstallationResults += @{ Module = $module.Name; Status = "Failed"; Version = "N/A" }
        }
    }

    Write-Host "`nCreating directory structure..." -ForegroundColor Green
    [string]$directories = @(
        "config",
        "logs",
        "data\exports",
        "data\templates",
        "reports"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "    [OK] Created directory: $dir" -ForegroundColor Green
        }
        else {
            Write-Host "    [OK] Directory exists: $dir" -ForegroundColor Green
        }
    }

    Write-Host "`nCreating sample configuration..." -ForegroundColor Green
$SampleConfig = @{
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
    [string]$ConfigPath = "config\sample-config.json"
    if (-not (Test-Path $ConfigPath)) {
    [string]$SampleConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Host "    [OK] Created sample configuration: $ConfigPath" -ForegroundColor Green
    }
    else {
        Write-Host "    [OK] Sample configuration exists: $ConfigPath" -ForegroundColor Green
    }

    Write-Host "`n$('=' * 60)" -ForegroundColor Green
    Write-Host "INSTALLATION SUMMARY" -ForegroundColor Green
    Write-Host "$('=' * 60)" -ForegroundColor Green
    [string]$SuccessCount = ($InstallationResults | Where-Object { $_.Status -eq "Installed" }).Count
    [string]$TotalCount = $InstallationResults.Count

    Write-Output "Modules installed: $SuccessCount/$TotalCount" -ForegroundColor $(if ($SuccessCount -eq $TotalCount) { "Green" } else { "Yellow" })

    foreach ($result in $InstallationResults) {
    [string]$color = if ($result.Status -eq "Installed") { "Green" } else { "Red" }
        Write-Output "  $($result.Module): $($result.Status) $($result.Version)" -ForegroundColor $color
    }

    if ($SuccessCount -eq $TotalCount) {
        Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Green
        Write-Host "1. Copy config\sample-config.json to config\config.json and update with your details" -ForegroundColor Green
        Write-Host "2. Run Connect-AzAccount to authenticate to Azure" -ForegroundColor Green
        Write-Host "3. Test the installation with: .\scripts\data-collection\Get-AzureCostData.ps1 -Days 7" -ForegroundColor Green
        Write-Host "4. Check the Installation Guide in docs\Installation-Guide.md for detailed setup" -ForegroundColor Green
    }
    else {
        Write-Host "`n[WARN] Installation completed with warnings. Please review failed modules above." -ForegroundColor Green
        Write-Host "You may need to install failed modules manually or run this script as Administrator." -ForegroundColor Green
    }

    Write-Host "`n[SUPPORT] wes@wesellis.com" -ForegroundColor Green
    Write-Host "[DOCS] https://github.com/wesellis/Azure-Cost-Management-Dashboard" -ForegroundColor Green
}
catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    throw
}
finally {
    Write-Verbose "Installation script completed"`n}

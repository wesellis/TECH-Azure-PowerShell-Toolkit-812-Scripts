#Requires -Version 7.0

<#
.SYNOPSIS
    Automated PowerShell Gallery publishing for Azure PowerShell Toolkit modules

.DESCRIPTION
    Publishes Azure PowerShell Toolkit modules to PowerShell Gallery with automated
    version management, dependency checking, and publishing validation.

.PARAMETER ModuleName
    Name of specific module to publish (optional - publishes all if not specified)

.PARAMETER ApiKey
    PowerShell Gallery API key for publishing

.PARAMETER WhatIf
    Preview what would be published without actually publishing

.PARAMETER Force
    Force publish even if validation warnings exist

.EXAMPLE
    .\Publish-ToGallery.ps1 -ApiKey "your-api-key"
    Publish all modules to PowerShell Gallery

.EXAMPLE
    .\Publish-ToGallery.ps1 -ModuleName "Az.Toolkit.Core" -ApiKey "your-api-key" -WhatIf
    Preview publishing specific module

.NOTES
    Author: Azure PowerShell Toolkit Team
    Version: 1.0
    Requires: PowerShellGet 2.0+
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ModuleName,

    [Parameter(Mandatory)]
    [string]$ApiKey,

    [Parameter()]
    [switch]$Force
)

# Import required modules
try {
    Import-Module PowerShellGet -MinimumVersion 2.0.0 -Force -ErrorAction Stop
} catch {
    Write-Error "PowerShellGet 2.0+ is required. Update with: Install-Module -Name PowerShellGet -Force"
    exit 1
}

# Set up paths
$ToolkitRoot = Split-Path -Parent $PSScriptRoot
$ModulesPath = Join-Path $ToolkitRoot "modules"
$PublishLogPath = Join-Path $ToolkitRoot "tools" "publish-log.json"

Write-Host "=== Azure PowerShell Toolkit - Gallery Publisher ===" -ForegroundColor Cyan
Write-Host "Modules Path: $ModulesPath" -ForegroundColor Green
Write-Host ""

# Function to create module manifest
function New-ToolkitModuleManifest {
    param(
        [string]$ModulePath,
        [string]$Name,
        [string]$Version = "1.0.0"
    )

    $manifestPath = Join-Path $ModulePath "$Name.psd1"

    $manifestData = @{
        ModuleVersion = $Version
        GUID = [System.Guid]::NewGuid().ToString()
        Author = 'Wesley Ellis'
        CompanyName = 'WesEllis'
        Copyright = "(c) 2025 Wesley Ellis. All rights reserved."
        Description = "Azure PowerShell Toolkit - $Name module for enterprise Azure automation"
        PowerShellVersion = '7.0'
        RequiredModules = @('Az.Accounts', 'Az.Profile')
        FunctionsToExport = @('*')
        CmdletsToExport = @()
        VariablesToExport = @()
        AliasesToExport = @()
        ProjectUri = 'https://github.com/wesellis/TECH-Azure-PowerShell-Toolkit-812-Scripts'
        LicenseUri = 'https://github.com/wesellis/TECH-Azure-PowerShell-Toolkit-812-Scripts/blob/main/LICENSE'
        IconUri = 'https://raw.githubusercontent.com/wesellis/TECH-Azure-PowerShell-Toolkit-812-Scripts/main/assets/icon.png'
        Tags = @('Azure', 'PowerShell', 'Automation', 'Enterprise', 'Cloud', 'DevOps')
        ReleaseNotes = "Azure PowerShell Toolkit $Name module - Professional Azure automation tools"
    }

    New-ModuleManifest -Path $manifestPath @manifestData
    return $manifestPath
}

# Function to create module from scripts
function New-ToolkitModule {
    param(
        [string]$CategoryPath,
        [string]$CategoryName
    )

    Write-Host "Creating module for category: $CategoryName" -ForegroundColor Yellow

    $moduleDir = Join-Path $ModulesPath "Az.Toolkit.$CategoryName"
    if (-not (Test-Path $moduleDir)) {
        New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
    }

    # Create module script file
    $moduleFile = Join-Path $moduleDir "Az.Toolkit.$CategoryName.psm1"
    $moduleContent = @"
#Requires -Version 7.0
#Requires -Modules Az.Accounts

<#
.SYNOPSIS
    Azure PowerShell Toolkit - $CategoryName Module

.DESCRIPTION
    Professional Azure automation tools for $CategoryName operations.
    Part of the Azure PowerShell Toolkit enterprise solution.

.NOTES
    Author: Wesley Ellis
    Website: wesellis.com
    Module: Az.Toolkit.$CategoryName
#>

# Import all script functions from the category
`$ScriptPath = Join-Path (Split-Path `$PSScriptRoot -Parent) "scripts" "$CategoryName"
if (Test-Path `$ScriptPath) {
    Get-ChildItem -Path `$ScriptPath -Filter "*.ps1" | ForEach-Object {
        Write-Verbose "Loading `$(`$_.Name)"
        . `$_.FullName
    }
}

# Export all functions
Export-ModuleMember -Function *
"@

    Set-Content -Path $moduleFile -Value $moduleContent -Encoding UTF8

    # Create manifest
    $manifestPath = New-ToolkitModuleManifest -ModulePath $moduleDir -Name "Az.Toolkit.$CategoryName"

    return @{
        ModuleDir = $moduleDir
        ModuleFile = $moduleFile
        ManifestPath = $manifestPath
        Name = "Az.Toolkit.$CategoryName"
    }
}

# Function to validate module before publishing
function Test-ModuleForPublishing {
    param(
        [string]$ModulePath
    )

    Write-Host "Validating module: $ModulePath" -ForegroundColor Yellow

    $issues = @()

    try {
        # Test module manifest
        $manifest = Test-ModuleManifest -Path $ModulePath -ErrorAction Stop
        Write-Host "  ✓ Module manifest is valid" -ForegroundColor Green

        # Check required fields
        if (-not $manifest.Author) { $issues += "Missing Author" }
        if (-not $manifest.Description) { $issues += "Missing Description" }
        if (-not $manifest.ProjectUri) { $issues += "Missing ProjectUri" }

        # Check version
        if ($manifest.Version -eq '0.0.1') {
            $issues += "Version is still default (0.0.1)"
        }

        # Check for existing version on gallery
        try {
            $galleryModule = Find-Module -Name $manifest.Name -ErrorAction SilentlyContinue
            if ($galleryModule -and $galleryModule.Version -ge $manifest.Version) {
                $issues += "Version $($manifest.Version) already exists or is lower than gallery version $($galleryModule.Version)"
            }
        } catch {
            # Module doesn't exist on gallery yet - this is fine
        }

    } catch {
        $issues += "Module manifest test failed: $($_.Exception.Message)"
    }

    return $issues
}

# Function to publish module
function Publish-ToolkitModule {
    param(
        [string]$ModulePath,
        [string]$ApiKey,
        [switch]$WhatIf
    )

    $moduleName = (Get-Item $ModulePath).BaseName -replace '\.psd1$', ''

    Write-Host "Publishing module: $moduleName" -ForegroundColor Cyan

    if ($WhatIf) {
        Write-Host "  [WHAT-IF] Would publish $moduleName to PowerShell Gallery" -ForegroundColor Yellow
        return @{ Success = $true; Message = "WhatIf - Would publish" }
    }

    try {
        Publish-Module -Path (Split-Path $ModulePath) -NuGetApiKey $ApiKey -Verbose
        Write-Host "  ✓ Successfully published $moduleName" -ForegroundColor Green
        return @{ Success = $true; Message = "Published successfully" }
    } catch {
        Write-Host "  ✗ Failed to publish $moduleName" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

# Main execution
try {
    # Create modules directory if it doesn't exist
    if (-not (Test-Path $ModulesPath)) {
        New-Item -Path $ModulesPath -ItemType Directory -Force | Out-Null
    }

    # Get script categories
    $scriptsPath = Join-Path $ToolkitRoot "scripts"
    $categories = Get-ChildItem -Path $scriptsPath -Directory

    $publishResults = @{}
    $totalModules = 0
    $successfulPublishes = 0

    # Create or update modules for each category
    foreach ($category in $categories) {
        if ($ModuleName -and $category.Name -ne $ModuleName.Replace("Az.Toolkit.", "")) {
            continue
        }

        $moduleInfo = New-ToolkitModule -CategoryPath $category.FullName -CategoryName $category.Name
        $totalModules++

        # Validate module
        $validationIssues = Test-ModuleForPublishing -ModulePath $moduleInfo.ManifestPath

        if ($validationIssues.Count -gt 0 -and -not $Force) {
            Write-Host "  ⚠ Validation issues found:" -ForegroundColor Yellow
            foreach ($issue in $validationIssues) {
                Write-Host "    - $issue" -ForegroundColor Yellow
            }
            Write-Host "  Skipping publish (use -Force to override)" -ForegroundColor Yellow
            $publishResults[$moduleInfo.Name] = @{ Success = $false; Message = "Validation failed" }
            continue
        }

        # Publish module
        if ($PSCmdlet.ShouldProcess($moduleInfo.Name, "Publish Module")) {
            $result = Publish-ToolkitModule -ModulePath $moduleInfo.ManifestPath -ApiKey $ApiKey -WhatIf:$WhatIfPreference
            $publishResults[$moduleInfo.Name] = $result

            if ($result.Success) {
                $successfulPublishes++
            }
        }
    }

    # Create core toolkit module
    if (-not $ModuleName -or $ModuleName -eq "Az.Toolkit.Core") {
        Write-Host "Creating core toolkit module..." -ForegroundColor Cyan

        $coreModuleDir = Join-Path $ModulesPath "Az.Toolkit.Core"
        if (-not (Test-Path $coreModuleDir)) {
            New-Item -Path $coreModuleDir -ItemType Directory -Force | Out-Null
        }

        # Create core module that references all category modules
        $coreModuleFile = Join-Path $coreModuleDir "Az.Toolkit.Core.psm1"
        $coreContent = @"
#Requires -Version 7.0
#Requires -Modules Az.Accounts

<#
.SYNOPSIS
    Azure PowerShell Toolkit - Core Module

.DESCRIPTION
    Core module for Azure PowerShell Toolkit that provides enterprise Azure automation.
    This module aggregates all toolkit functionality.

.NOTES
    Author: Wesley Ellis
    Website: wesellis.com
    Module: Az.Toolkit.Core
#>

# Core toolkit functions
function Get-AzToolkitVersion {
    return "1.0.0"
}

function Get-AzToolkitModules {
    return Get-Module -Name "Az.Toolkit.*" -ListAvailable
}

function Install-AzToolkitDependencies {
    [CmdletBinding()]
    param()

    Write-Host "Installing Azure PowerShell Toolkit dependencies..." -ForegroundColor Cyan

    `$requiredModules = @(
        'Az.Accounts', 'Az.Resources', 'Az.Storage', 'Az.KeyVault',
        'Az.Compute', 'Az.Network', 'Az.Monitor', 'Az.Security'
    )

    foreach (`$module in `$requiredModules) {
        if (-not (Get-Module -Name `$module -ListAvailable)) {
            Write-Host "Installing `$module..." -ForegroundColor Yellow
            Install-Module -Name `$module -Force -AllowClobber
        }
    }

    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
}

Export-ModuleMember -Function *
"@

        Set-Content -Path $coreModuleFile -Value $coreContent -Encoding UTF8

        # Create core manifest
        $coreManifestPath = New-ToolkitModuleManifest -ModulePath $coreModuleDir -Name "Az.Toolkit.Core" -Version "1.0.0"
        $totalModules++

        # Publish core module
        if ($PSCmdlet.ShouldProcess("Az.Toolkit.Core", "Publish Module")) {
            $result = Publish-ToolkitModule -ModulePath $coreManifestPath -ApiKey $ApiKey -WhatIf:$WhatIfPreference
            $publishResults["Az.Toolkit.Core"] = $result

            if ($result.Success) {
                $successfulPublishes++
            }
        }
    }

    # Save publish log
    $publishLog = @{
        Timestamp = Get-Date
        TotalModules = $totalModules
        SuccessfulPublishes = $successfulPublishes
        Results = $publishResults
        WhatIf = $WhatIfPreference
    }

    $publishLog | ConvertTo-Json -Depth 3 | Out-File -FilePath $PublishLogPath -Encoding UTF8

    # Summary
    Write-Host ""
    Write-Host "=== Publishing Summary ===" -ForegroundColor Cyan
    Write-Host "Total Modules: $totalModules" -ForegroundColor White
    Write-Host "Successful: $successfulPublishes" -ForegroundColor Green
    Write-Host "Failed: $($totalModules - $successfulPublishes)" -ForegroundColor Red
    Write-Host "Log saved to: $PublishLogPath" -ForegroundColor Yellow

    if ($successfulPublishes -eq $totalModules) {
        Write-Host "All modules published successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Some modules failed to publish. Check the log for details." -ForegroundColor Yellow
        exit 1
    }

} catch {
    Write-Error "Publishing failed: $($_.Exception.Message)"
    exit 1
}
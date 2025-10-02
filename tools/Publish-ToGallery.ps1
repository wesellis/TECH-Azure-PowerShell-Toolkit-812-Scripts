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

try {
    Import-Module PowerShellGet -MinimumVersion 2.0.0 -Force -ErrorAction Stop
} catch {
    Write-Error "PowerShellGet 2.0+ is required. Update with: Install-Module -Name PowerShellGet -Force"
    exit 1
}
$ToolkitRoot = Split-Path -Parent $PSScriptRoot
$ModulesPath = Join-Path $ToolkitRoot "modules"
$PublishLogPath = Join-Path $ToolkitRoot "tools" "publish-log.json"

Write-Host "=== Azure PowerShell Toolkit - Gallery Publisher ===" -ForegroundColor Green
Write-Host "Modules Path: $ModulesPath" -ForegroundColor Green
Write-Output ""

function New-ToolkitModuleManifest {
    param(
        [string]$ModulePath,
        [string]$Name,
        [string]$Version = "1.0.0"
    )
    $ManifestPath = Join-Path $ModulePath "$Name.psd1"
    $ManifestData = @{
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

    New-ModuleManifest -Path $ManifestPath @manifestData
    return $ManifestPath
}

function New-ToolkitModule {
    param(
        [string]$CategoryPath,
        [string]$CategoryName
    )

    Write-Host "Creating module for category: $CategoryName" -ForegroundColor Green
    $ModuleDir = Join-Path $ModulesPath "Az.Toolkit.$CategoryName"
    if (-not (Test-Path $ModuleDir)) {
        New-Item -Path $ModuleDir -ItemType Directory -Force | Out-Null
    }
    $ModuleFile = Join-Path $ModuleDir "Az.Toolkit.$CategoryName.psm1"
    $ModuleContent = @"
#Requires -Modules Az.Accounts


`$ScriptPath = Join-Path (Split-Path `$PSScriptRoot -Parent) "scripts" "$CategoryName"
if (Test-Path `$ScriptPath) {
    Get-ChildItem -Path `$ScriptPath -Filter "*.ps1" | ForEach-Object {
        Write-Verbose "Loading `$(`$_.Name)"
        . `$_.FullName
    }
}

Export-ModuleMember -Function *
"@

    Set-Content -Path $ModuleFile -Value $ModuleContent -Encoding UTF8
    $ManifestPath = New-ToolkitModuleManifest -ModulePath $ModuleDir -Name "Az.Toolkit.$CategoryName"

    return @{
        ModuleDir = $ModuleDir
        ModuleFile = $ModuleFile
        ManifestPath = $ManifestPath
        Name = "Az.Toolkit.$CategoryName"
    }
}

function Test-ModuleForPublishing {
    param(
        [string]$ModulePath
    )

    Write-Host "Validating module: $ModulePath" -ForegroundColor Green
    $issues = @()

    try {
        $manifest = Test-ModuleManifest -Path $ModulePath -ErrorAction Stop
        Write-Host "  ✓ Module manifest is valid" -ForegroundColor Green

        if (-not $manifest.Author) { $issues += "Missing Author" }
        if (-not $manifest.Description) { $issues += "Missing Description" }
        if (-not $manifest.ProjectUri) { $issues += "Missing ProjectUri" }

        if ($manifest.Version -eq '0.0.1') {
            $issues += "Version is still default (0.0.1)"
        }

        try {
            $GalleryModule = Find-Module -Name $manifest.Name -ErrorAction SilentlyContinue
            if ($GalleryModule -and $GalleryModule.Version -ge $manifest.Version) {
                $issues += "Version $($manifest.Version) already exists or is lower than gallery version $($GalleryModule.Version)"
            }
        } catch {
        }

    } catch {
        $issues += "Module manifest test failed: $($_.Exception.Message)"
    }

    return $issues
}

function Publish-ToolkitModule {
    param(
        [string]$ModulePath,
        [string]$ApiKey,
        [switch]$WhatIf
    )
    $ModuleName = (Get-Item $ModulePath).BaseName -replace '\.psd1$', ''

    Write-Host "Publishing module: $ModuleName" -ForegroundColor Green

    if ($WhatIf) {
        Write-Host "  [WHAT-IF] Would publish $ModuleName to PowerShell Gallery" -ForegroundColor Green
        return @{ Success = $true; Message = "WhatIf - Would publish" }
    }

    try {
        Publish-Module -Path (Split-Path $ModulePath) -NuGetApiKey $ApiKey -Verbose
        Write-Host "  ✓ Successfully published $ModuleName" -ForegroundColor Green
        return @{ Success = $true; Message = "Published successfully" }
    } catch {
        Write-Host "  ✗ Failed to publish $ModuleName" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

try {
    if (-not (Test-Path $ModulesPath)) {
        New-Item -Path $ModulesPath -ItemType Directory -Force | Out-Null
    }
    $ScriptsPath = Join-Path $ToolkitRoot "scripts"
    $categories = Get-ChildItem -Path $ScriptsPath -Directory
    $PublishResults = @{}
    $TotalModules = 0
    $SuccessfulPublishes = 0

    foreach ($category in $categories) {
        if ($ModuleName -and $category.Name -ne $ModuleName.Replace("Az.Toolkit.", "")) {
            continue
        }
        $ModuleInfo = New-ToolkitModule -CategoryPath $category.FullName -CategoryName $category.Name
        $TotalModules++
        $ValidationIssues = Test-ModuleForPublishing -ModulePath $ModuleInfo.ManifestPath

        if ($ValidationIssues.Count -gt 0 -and -not $Force) {
            Write-Host "  ⚠ Validation issues found:" -ForegroundColor Yellow
            foreach ($issue in $ValidationIssues) {
                Write-Host "    - $issue" -ForegroundColor Yellow
            }
            Write-Host "  Skipping publish (use -Force to override)" -ForegroundColor Yellow
            $PublishResults[$ModuleInfo.Name] = @{ Success = $false; Message = "Validation failed" }
            continue
        }

        if ($PSCmdlet.ShouldProcess($ModuleInfo.Name, "Publish Module")) {
            $result = Publish-ToolkitModule -ModulePath $ModuleInfo.ManifestPath -ApiKey $ApiKey -WhatIf:$WhatIfPreference
            $PublishResults[$ModuleInfo.Name] = $result

            if ($result.Success) {
                $SuccessfulPublishes++
            }
        }
    }

    if (-not $ModuleName -or $ModuleName -eq "Az.Toolkit.Core") {
        Write-Host "Creating core toolkit module..." -ForegroundColor Green
        $CoreModuleDir = Join-Path $ModulesPath "Az.Toolkit.Core"
        if (-not (Test-Path $CoreModuleDir)) {
            New-Item -Path $CoreModuleDir -ItemType Directory -Force | Out-Null
        }
        $CoreModuleFile = Join-Path $CoreModuleDir "Az.Toolkit.Core.psm1"
        $CoreContent = @"
#Requires -Modules Az.Accounts


function Get-AzToolkitVersion {
    return "1.0.0"
}

function Get-AzToolkitModules {
    return Get-Module -Name "Az.Toolkit.*" -ListAvailable
}

function Install-AzToolkitDependencies {
    param()

    Write-Host "Installing Azure PowerShell Toolkit dependencies..." -ForegroundColor Green

    `$RequiredModules = @(
        'Az.Accounts', 'Az.Resources', 'Az.Storage', 'Az.KeyVault',
        'Az.Compute', 'Az.Network', 'Az.Monitor', 'Az.Security'
    )

    foreach (`$module in `$RequiredModules) {
        if (-not (Get-Module -Name `$module -ListAvailable)) {
            Write-Host "Installing `$module..." -ForegroundColor Green
            Install-Module -Name `$module -Force -AllowClobber
        }
    }

    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
}

Export-ModuleMember -Function *
"@

        Set-Content -Path $CoreModuleFile -Value $CoreContent -Encoding UTF8
        $CoreManifestPath = New-ToolkitModuleManifest -ModulePath $CoreModuleDir -Name "Az.Toolkit.Core" -Version "1.0.0"
        $TotalModules++

        if ($PSCmdlet.ShouldProcess("Az.Toolkit.Core", "Publish Module")) {
            $result = Publish-ToolkitModule -ModulePath $CoreManifestPath -ApiKey $ApiKey -WhatIf:$WhatIfPreference
            $PublishResults["Az.Toolkit.Core"] = $result

            if ($result.Success) {
                $SuccessfulPublishes++
            }
        }
    }
    $PublishLog = @{
        Timestamp = Get-Date
        TotalModules = $TotalModules
        SuccessfulPublishes = $SuccessfulPublishes
        Results = $PublishResults
        WhatIf = $WhatIfPreference
    }
    $PublishLog | ConvertTo-Json -Depth 3 | Out-File -FilePath $PublishLogPath -Encoding UTF8

    Write-Output ""
    Write-Host "=== Publishing Summary ===" -ForegroundColor Green
    Write-Host "Total Modules: $TotalModules" -ForegroundColor Green
    Write-Host "Successful: $SuccessfulPublishes" -ForegroundColor Green
    Write-Host "Failed: $($TotalModules - $SuccessfulPublishes)" -ForegroundColor Green
    Write-Host "Log saved to: $PublishLogPath" -ForegroundColor Green

    if ($SuccessfulPublishes -eq $TotalModules) {
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

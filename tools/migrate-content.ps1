#Requires -Version 7.0

    Migrates content from existing Azure repositories into consolidated structure

    This script copies content from multiple Azure-related repositories into a unified
    Azure Enterprise Toolkit structure, organizing scripts, modules, documentation,
    and tools into a standardized hierarchy.
.PARAMETER SourceBasePath
    Base path where source repositories are located
.PARAMETER TargetBasePath
    Target path for the consolidated Azure Enterprise Toolkit
.PARAMETER IncludeTests
    Include test files in migration
.PARAMETER WhatIf
    Preview migration operations without executing them

    .\Invoke-ContentMigration.ps1 -SourceBasePath "C:\GITHUB" -TargetBasePath "C:\GITHUB\Azure-Enterprise-Toolkit"

    Migrates content from source repositories to target location

    .\Invoke-ContentMigration.ps1 -WhatIf

    Shows what would be migrated without performing the operations

    Author: Wes Ellis (wes@wesellis.com)#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$SourceBasePath = "A:\GITHUB",

    [Parameter(Mandatory = $false)]
    [string]$TargetBasePath = "A:\GITHUB\Azure-Enterprise-Toolkit",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeTests,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Migration statistics
$migrationStats = @{
    FilesProcessed = 0
    DirectoriesCreated = 0
    Errors = @()
    Phases = @()
}

#endregion

#region Functions
function Write-MigrationHeader {
    [CmdletBinding()]
    param(
        [string]$Title
    )

    $separator = '=' * 65
    Write-Host $Title -InformationAction Continue
    Write-Host $separator -InformationAction Continue
}

function Write-PhaseHeader {
    [CmdletBinding()]
    param(
        [string]$PhaseTitle
    )

    Write-Host "`n$PhaseTitle" -InformationAction Continue
    $migrationStats.Phases += $PhaseTitle
}

function Copy-RepositoryContent {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Description,
        [string[]]$IncludePatterns = @('*'),
        [string[]]$ExcludePatterns = @('.git', 'node_modules', '*.log')
    )

    try {
        if (-not (Test-Path $SourcePath)) {
            Write-Warning "Source path not found: $SourcePath"
            return $false
        }

        # Ensure destination directory exists
        $destinationDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $destinationDir)) {
            if ($PSCmdlet.ShouldProcess($destinationDir, "Create directory")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                $migrationStats.DirectoriesCreated++
            }
        }

        # Copy content with filters
        $copyParams = @{
            Path = "$SourcePath\*"
            Destination = $DestinationPath
            Recurse = $true
            Force = $true
            ErrorAction = 'SilentlyContinue'
        }

        if ($PSCmdlet.ShouldProcess($SourcePath, "Copy to $DestinationPath")) {
            $result = Copy-Item @copyParams -PassThru
            $migrationStats.FilesProcessed += $result.Count
            Write-Host "  [OK] $Description" -InformationAction Continue
            return $true
        }
        else {
            Write-Host "  [WHATIF] Would copy $Description" -InformationAction Continue
            return $true
        
} catch {
        $errorMsg = "Failed to copy $Description`: $_"
        $migrationStats.Errors += $errorMsg
        Write-Warning $errorMsg
        return $false
    }
}

function Copy-SingleFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$SourceFile,
        [string]$DestinationFile,
        [string]$Description
    )

    try {
        if (-not (Test-Path $SourceFile)) {
            Write-Warning "Source file not found: $SourceFile"
            return $false
        }

        $destinationDir = Split-Path $DestinationFile -Parent
        if (-not (Test-Path $destinationDir)) {
            if ($PSCmdlet.ShouldProcess($destinationDir, "Create directory")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                $migrationStats.DirectoriesCreated++
            }
        }

        if ($PSCmdlet.ShouldProcess($SourceFile, "Copy to $DestinationFile")) {
            Copy-Item -Path $SourceFile -Destination $DestinationFile -Force
            $migrationStats.FilesProcessed++
            Write-Host "  [OK] $Description" -InformationAction Continue
            return $true
        }
        else {
            Write-Host "  [WHATIF] Would copy $Description" -InformationAction Continue
            return $true
        
} catch {
        $errorMsg = "Failed to copy $Description`: $_"
        $migrationStats.Errors += $errorMsg
        Write-Warning $errorMsg
        return $false
    }
}

function Get-MigrationPhases {
    [CmdletBinding()]
    param()

    return @(
        @{
            Name = "Azure Automation Scripts (124+ scripts)"
            SourceSubPath = "Azure-Automation-Scripts\scripts"
            TargetSubPath = "automation-scripts"
            Description = "PowerShell automation scripts"
            IncludeModules = $true
        },
        @{
            Name = "Cost Management Dashboard"
            SourceSubPath = "Azure-Cost-Management-Dashboard"
            TargetSubPath = "cost-management"
            Description = "Cost management dashboards and tools"
            IncludeModules = $false
        },
        @{
            Name = "DevOps Pipeline Templates"
            SourceSubPath = "Azure-DevOps-Pipeline-Templates"
            TargetSubPath = "devops-templates"
            Description = "Azure DevOps pipeline templates"
            IncludeModules = $false
        },
        @{
            Name = "Governance Toolkit"
            SourceSubPath = "Azure-Governance-Toolkit"
            TargetSubPath = "governance"
            Description = "Governance policies and tools"
            IncludeModules = $false
        },
        @{
            Name = "Essential Bookmarks"
            SourceSubPath = "Azure-Essentials-Bookmarks"
            TargetSubPath = "bookmarks"
            Description = "Azure essential bookmarks"
            IncludeModules = $false
        }
    )
}

#endregion

#region Main-Execution
try {
    Write-MigrationHeader "Azure Enterprise Toolkit Content Migration"

    # Validate paths
    if (-not (Test-Path $SourceBasePath)) {
        throw "Source base path does not exist: $SourceBasePath"
    }

    # Ensure target base exists
    if (-not (Test-Path $TargetBasePath)) {
        if ($PSCmdlet.ShouldProcess($TargetBasePath, "Create target directory")) {
            New-Item -Path $TargetBasePath -ItemType Directory -Force | Out-Null
            $migrationStats.DirectoriesCreated++
        }
    }

    # Change to target directory
    if ($PSCmdlet.ShouldProcess($TargetBasePath, "Set location")) {
        Set-Location -Path $TargetBasePath -ErrorAction Stop
    }

    # Execute migration phases
    $phases = Get-MigrationPhases
    foreach ($phase in $phases) {
        Write-PhaseHeader "PHASE $($phases.IndexOf($phase) + 1): $($phase.Name)"

        $sourcePath = Join-Path $SourceBasePath $phase.SourceSubPath
        $targetPath = Join-Path $TargetBasePath $phase.TargetSubPath

        # Copy main content
        if (Test-Path $sourcePath) {
            # Copy scripts/main content
            $scriptsSource = if (Test-Path "$sourcePath\scripts") { "$sourcePath\scripts" } else { $sourcePath }
            Copy-RepositoryContent -SourcePath $scriptsSource -DestinationPath $targetPath -Description $phase.Description

            # Copy modules if applicable
            if ($phase.IncludeModules) {
                $modulesSource = Join-Path $sourcePath "modules"
                if (Test-Path $modulesSource) {
                    Copy-RepositoryContent -SourcePath $modulesSource -DestinationPath "$targetPath\modules" -Description "PowerShell modules"
                }
            }

            # Copy standard subdirectories
            foreach ($subdir in @('dashboards', 'docs', 'examples', 'templates')) {
                $subdirPath = Join-Path $sourcePath $subdir
                if (Test-Path $subdirPath) {
                    Copy-RepositoryContent -SourcePath $subdirPath -DestinationPath "$targetPath\$subdir" -Description "$subdir content"
                }
            }

            # Copy README if exists
            $readmePath = Join-Path $sourcePath "README.md"
            if (Test-Path $readmePath) {
                Copy-SingleFile -SourceFile $readmePath -DestinationFile "$targetPath\README.md" -Description "README documentation"
            }
        }
        else {
            Write-Warning "Source not found: $sourcePath"
        }
    }

    # Unified Documentation Phase
    Write-PhaseHeader "PHASE 6: Creating Unified Documentation"
    $docFiles = @(
        @{ Source = "Azure-Automation-Scripts\CONTRIBUTING.md"; Target = "docs\CONTRIBUTING.md" },
        @{ Source = "Azure-Automation-Scripts\CHANGELOG.md"; Target = "docs\CHANGELOG.md" }
    )

    foreach ($docFile in $docFiles) {
        $sourcePath = Join-Path $SourceBasePath $docFile.Source
        $targetPath = Join-Path $TargetBasePath $docFile.Target
        if (Test-Path $sourcePath) {
            Copy-SingleFile -SourceFile $sourcePath -DestinationFile $targetPath -Description "Documentation file: $($docFile.Target)"
        }
    }

    # Utility Tools Phase
    Write-PhaseHeader "PHASE 7: Creating Utility Tools"
    $utilityFiles = @(
        @{ Source = "enhanced-github-upload.ps1"; Target = "tools\github-upload.ps1" },
        @{ Source = "github-download.ps1"; Target = "tools\github-download.ps1" }
    )

    foreach ($utilityFile in $utilityFiles) {
        $sourcePath = Join-Path $SourceBasePath $utilityFile.Source
        $targetPath = Join-Path $TargetBasePath $utilityFile.Target
        if (Test-Path $sourcePath) {
            Copy-SingleFile -SourceFile $sourcePath -DestinationFile $targetPath -Description "Utility tool: $($utilityFile.Target)"
        }
    }

    # Migration Summary
    Write-PhaseHeader "MIGRATION SUMMARY"
    Write-Host "Files processed: $($migrationStats.FilesProcessed)" -InformationAction Continue
    Write-Host "Directories created: $($migrationStats.DirectoriesCreated)" -InformationAction Continue
    Write-Host "Phases completed: $($migrationStats.Phases.Count)" -InformationAction Continue

    if ($migrationStats.Errors.Count -gt 0) {
        Write-Warning "Errors encountered: $($migrationStats.Errors.Count)"
        $migrationStats.Errors | ForEach-Object { Write-Warning "  - $_" }
    }

    Write-Host "`nContent migration completed successfully!" -InformationAction Continue
    Write-Host "Total consolidated components: $($phases.Count) major toolkits" -InformationAction Continue
    Write-Host "Ready for git operations" -InformationAction Continue
}
catch {
    Write-Error "Migration failed: $_"
    Write-Error "Migration statistics: $($migrationStats | ConvertTo-Json -Depth 2)"
    throw
}
finally {
    # Restore original location if needed
    if ($PWD.Path -ne $TargetBasePath) {
        Pop-Location -ErrorAction SilentlyContinue
    }
}

#endregion


#Requires -Version 7.0
<#
.SYNOPSIS
    migrate content
.DESCRIPTION
    migrate content operation
    Author: Wes Ellis (wes@wesellis.com)

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

    Author: Wes Ellis (wes@wesellis.com)
#>

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
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$MigrationStats = @{
    FilesProcessed = 0
    DirectoriesCreated = 0
    Errors = @()
    Phases = @()
}


function Write-Log {
    param(
        [string]$Title
    )
    $separator = '=' * 65
    Write-Output $Title -InformationAction Continue
    Write-Output $separator -InformationAction Continue
}

function Write-PhaseHeader {
    param(
        [string]$PhaseTitle
    )

    Write-Output "`n$PhaseTitle" -InformationAction Continue
    $MigrationStats.Phases += $PhaseTitle
}

function Copy-RepositoryContent {
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
        $DestinationDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $DestinationDir)) {
            if ($PSCmdlet.ShouldProcess($DestinationDir, "Create directory")) {
                New-Item -Path $DestinationDir -ItemType Directory -Force | Out-Null
                $MigrationStats.DirectoriesCreated++
            }
        }
        $CopyParams = @{
            Path = "$SourcePath\*"
            Destination = $DestinationPath
            Recurse = $true
            Force = $true
            ErrorAction = 'SilentlyContinue'
        }

        if ($PSCmdlet.ShouldProcess($SourcePath, "Copy to $DestinationPath")) {
            $result = Copy-Item @copyParams -PassThru
            $MigrationStats.FilesProcessed += $result.Count
            Write-Output "  [OK] $Description" -InformationAction Continue
            return $true
        }
        else {
            Write-Output "  [WHATIF] Would copy $Description" -InformationAction Continue
            return $true

} catch {
        $ErrorMsg = "Failed to copy $Description`: $_"
        $MigrationStats.Errors += $ErrorMsg
        Write-Warning $ErrorMsg
        return $false
    }
}

function Copy-SingleFile {
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
    [string]$DestinationDir = Split-Path $DestinationFile -Parent
        if (-not (Test-Path $DestinationDir)) {
            if ($PSCmdlet.ShouldProcess($DestinationDir, "Create directory")) {
                New-Item -Path $DestinationDir -ItemType Directory -Force | Out-Null
                $MigrationStats.DirectoriesCreated++
            }
        }

        if ($PSCmdlet.ShouldProcess($SourceFile, "Copy to $DestinationFile")) {
            Copy-Item -Path $SourceFile -Destination $DestinationFile -Force
            $MigrationStats.FilesProcessed++
            Write-Output "  [OK] $Description" -InformationAction Continue
            return $true
        }
        else {
            Write-Output "  [WHATIF] Would copy $Description" -InformationAction Continue
            return $true

} catch {
        $ErrorMsg = "Failed to copy $Description`: $_"
        $MigrationStats.Errors += $ErrorMsg
        Write-Warning $ErrorMsg
        return $false
    }
}

function Get-MigrationPhases {
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


try {
    Write-MigrationHeader "Azure Enterprise Toolkit Content Migration"

    if (-not (Test-Path $SourceBasePath)) {
        throw "Source base path does not exist: $SourceBasePath"
    }

    if (-not (Test-Path $TargetBasePath)) {
        if ($PSCmdlet.ShouldProcess($TargetBasePath, "Create target directory")) {
            New-Item -Path $TargetBasePath -ItemType Directory -Force | Out-Null
                $MigrationStats.DirectoriesCreated++
        }
    }

    if ($PSCmdlet.ShouldProcess($TargetBasePath, "Set location")) {
        Set-Location -Path $TargetBasePath -ErrorAction Stop
    }
    $phases = Get-MigrationPhases
    foreach ($phase in $phases) {
        Write-PhaseHeader "PHASE $($phases.IndexOf($phase) + 1): $($phase.Name)"
        $SourcePath = Join-Path $SourceBasePath $phase.SourceSubPath
        $TargetPath = Join-Path $TargetBasePath $phase.TargetSubPath

        if (Test-Path $SourcePath) {
        $ScriptsSource = if (Test-Path "$SourcePath\scripts") { "$SourcePath\scripts" } else { $SourcePath }
            Copy-RepositoryContent -SourcePath $ScriptsSource -DestinationPath $TargetPath -Description $phase.Description

            if ($phase.IncludeModules) {
        $ModulesSource = Join-Path $SourcePath "modules"
                if (Test-Path $ModulesSource) {
                    Copy-RepositoryContent -SourcePath $ModulesSource -DestinationPath "$TargetPath\modules" -Description "PowerShell modules"
                }
            }

            foreach ($subdir in @('dashboards', 'docs', 'examples', 'templates')) {
            $SubdirPath = Join-Path $SourcePath $subdir
                if (Test-Path $SubdirPath) {
                    Copy-RepositoryContent -SourcePath $SubdirPath -DestinationPath "$TargetPath\$subdir" -Description "$subdir content"
                }
            }
        $ReadmePath = Join-Path $SourcePath "README.md"
            if (Test-Path $ReadmePath) {
                Copy-SingleFile -SourceFile $ReadmePath -DestinationFile "$TargetPath\README.md" -Description "README documentation"
            }
        }
        else {
            Write-Warning "Source not found: $SourcePath"
        }
    }

    Write-PhaseHeader "PHASE 6: Creating Unified Documentation"
    $DocFiles = @(
        @{ Source = "Azure-Automation-Scripts\CONTRIBUTING.md"; Target = "docs\CONTRIBUTING.md" },
        @{ Source = "Azure-Automation-Scripts\CHANGELOG.md"; Target = "docs\CHANGELOG.md" }
    )

    foreach ($DocFile in $DocFiles) {
        $SourcePath = Join-Path $SourceBasePath $DocFile.Source
        $TargetPath = Join-Path $TargetBasePath $DocFile.Target
        if (Test-Path $SourcePath) {
            Copy-SingleFile -SourceFile $SourcePath -DestinationFile $TargetPath -Description "Documentation file: $($DocFile.Target)"
        }
    }

    Write-PhaseHeader "PHASE 7: Creating Utility Tools"
    $UtilityFiles = @(
        @{ Source = "enhanced-github-upload.ps1"; Target = "tools\github-upload.ps1" },
        @{ Source = "github-download.ps1"; Target = "tools\github-download.ps1" }
    )

    foreach ($UtilityFile in $UtilityFiles) {
        $SourcePath = Join-Path $SourceBasePath $UtilityFile.Source
        $TargetPath = Join-Path $TargetBasePath $UtilityFile.Target
        if (Test-Path $SourcePath) {
            Copy-SingleFile -SourceFile $SourcePath -DestinationFile $TargetPath -Description "Utility tool: $($UtilityFile.Target)"
        }
    }

    Write-PhaseHeader "MIGRATION SUMMARY"
    Write-Output "Files processed: $($MigrationStats.FilesProcessed)" -InformationAction Continue
    Write-Output "Directories created: $($MigrationStats.DirectoriesCreated)" -InformationAction Continue
    Write-Output "Phases completed: $($MigrationStats.Phases.Count)" -InformationAction Continue

    if ($MigrationStats.Errors.Count -gt 0) {
        Write-Warning "Errors encountered: $($MigrationStats.Errors.Count)"
        $MigrationStats.Errors | ForEach-Object { Write-Warning "  - $_" }
    }

    Write-Output "`nContent migration completed successfully!" -InformationAction Continue
    Write-Output "Total consolidated components: $($phases.Count) major toolkits" -InformationAction Continue
    Write-Output "Ready for git operations" -InformationAction Continue
}
catch {
    Write-Error "Migration failed: $_"
    Write-Error "Migration statistics: $($MigrationStats | ConvertTo-Json -Depth 2)"
    throw
}
finally {
    if ($PWD.Path -ne $TargetBasePath) {
        Pop-Location -ErrorAction SilentlyContinue
    }
`n}

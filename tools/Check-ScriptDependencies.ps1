#Requires -Version 7.0
<#
.SYNOPSIS
    Check ScriptDependencies
.DESCRIPTION
    Check ScriptDependencies operation
    Author: Wes Ellis (wes@wesellis.com)

    Check ScriptDependenciescom)
[CmdletBinding()]

    [Parameter()]
    [string]$ScriptPath,

    [Parameter()]
    [string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent),

    [switch]$InstallMissing,
    [switch]$GenerateReport,
    [switch]$CheckVersions,
    [switch]$ValidateAzureModules
)

    [hashtable]$Dependencies = @{}
    [hashtable]$MissingDependencies = @{}
    [hashtable]$VersionConflicts = @{}
    [array]$Scripts = @()

    [void] AnalyzeScript([string]$Path) {
        $ScriptName = [System.IO.Path]::GetFileName($Path)
        $content = Get-Content $Path -Raw

        $deps = @{
            Modules = @()
            Scripts = @()
            Variables = @()
            Functions = @()
            AzureResources = @()
            ExternalTools = @()
        }

        $ModulePattern = '#Requires\s+-Module[s]?\s+(.+)'
        $ImportPattern = 'Import-Module\s+([^\s;]+)'

        $content | Select-String -Pattern $ModulePattern -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                $modules = $_.Groups[1].Value -split ','
                $deps.Modules += $modules | ForEach-Object { $_.Trim() }
            }
        }

        $content | Select-String -Pattern $ImportPattern -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                $module = $_.Groups[1].Value.Trim('"', "'")
                if ($module -notmatch '^\$' -and $module -notmatch 'Join-Path') {
                    $deps.Modules += $module
                }
            }
        }

        $ScriptPattern = '\.\s+([^\s]+\.ps1)'
        $content | Select-String -Pattern $ScriptPattern -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                $deps.Scripts += $_.Groups[1].Value
            }
        }

        $AzureCmdlets = $content | Select-String -Pattern '(Get|Set|New|Remove|Update|Start|Stop|Restart)-Az\w+' -AllMatches
        $deps.AzureResources = $AzureCmdlets.Matches.Value | Select-Object -Unique

        $ToolPatterns = @(
            'git\s+',
            'docker\s+',
            'kubectl\s+',
            'terraform\s+',
            'az\s+',
            'dotnet\s+',
            'npm\s+',
            'python\s+'
        )

        foreach ($pattern in $ToolPatterns) {
            if ($content -match $pattern) {
                $tool = $pattern.Trim('\s+', ' ')
                $deps.ExternalTools += $tool
            }
        }

        $this.Dependencies[$ScriptName] = $deps
    }

    [hashtable] CheckInstalledModules() {
        $results = @{
            Installed = @()
            Missing = @()
            VersionInfo = @{}
        }

        $AllModules = $this.Dependencies.Values.Modules | Select-Object -Unique

        foreach ($module in $AllModules) {
            $installed = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue
            if ($installed) {
                $results.Installed += $module
                $results.VersionInfo[$module] = $installed.Version.ToString()
            } else {
                $results.Missing += $module
            }
        }

        return $results
    }

    [void] GenerateDependencyGraph() {
        $MermaidGraph = @"
graph TD
    subgraph "Script Dependencies"
"@

        foreach ($script in $this.Dependencies.Keys) {
            $deps = $this.Dependencies[$script]
            $ScriptId = $script -replace '[^a-zA-Z0-9]', ''

            foreach ($module in $deps.Modules) {
                $ModuleId = $module -replace '[^a-zA-Z0-9]', ''
                $MermaidGraph += "`n    $ScriptId --> $ModuleId[Module: $module]"
            }

            foreach ($DepScript in $deps.Scripts) {
                $DepScriptId = $DepScript -replace '[^a-zA-Z0-9]', ''
                $MermaidGraph += "`n    $ScriptId --> $DepScriptId[Script: $DepScript]"
            }
        }

        $MermaidGraph += "`n    end"

        $GraphPath = Join-Path $RepositoryPath "dependency-graph.md"
        @"

``````mermaid
$MermaidGraph
``````
"@ | Out-File $GraphPath -Encoding UTF8
    }

    [string] GenerateReport() {
        $report = @"
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

- Total Scripts Analyzed: $($this.Dependencies.Count)
- Unique Module Dependencies: $(($this.Dependencies.Values.Modules | Select-Object -Unique).Count)
- Unique Script Dependencies: $(($this.Dependencies.Values.Scripts | Select-Object -Unique).Count)
- External Tools Required: $(($this.Dependencies.Values.ExternalTools | Select-Object -Unique).Count)

"@

        $ModuleUsage = @{}
        foreach ($script in $this.Dependencies.Keys) {
            foreach ($module in $this.Dependencies[$script].Modules) {
                if (-not $ModuleUsage.ContainsKey($module)) {
                    $ModuleUsage[$module] = @()
                }
                $ModuleUsage[$module] += $script
            }
        }

        foreach ($module in ($ModuleUsage.Keys | Sort-Object)) {
            $report += "`n### $module`n"
            $report += "Used by $($ModuleUsage[$module].Count) script(s):`n"
            foreach ($script in $ModuleUsage[$module]) {
                $report += "- $script`n"
            }
        }

        $report += "`n## Installation Status`n"
        $InstallStatus = $this.CheckInstalledModules()

        $report += "`n### Installed Modules`n"
        foreach ($module in $InstallStatus.Installed) {
            $version = $InstallStatus.VersionInfo[$module]
            $report += "-  $module (v$version)`n"
        }

        $report += "`n### Missing Modules`n"
        foreach ($module in $InstallStatus.Missing) {
            $report += "-  $module`n"
        }

        if ($InstallStatus.Missing.Count -gt 0) {
            $report += "`n### Installation Commands`n"
            $report += "``````powershell`n"
            foreach ($module in $InstallStatus.Missing) {
                $report += "Install-Module -Name $module -Force -AllowClobber`n"
            }
            $report += "```````n"
        }

        return $report
    }
}

$analyzer = [DependencyAnalyzer]::new()

Write-Output "Starting dependency analysis..." # Color: $2

if ($ScriptPath) {
    if (Test-Path $ScriptPath) {
        Write-Output "Analyzing single script: $ScriptPath" # Color: $2
        $analyzer.AnalyzeScript($ScriptPath)
    } else {
        Write-Error "Script not found: $ScriptPath"
        return
    }
} else {
    Write-Output "Analyzing all scripts in repository..." # Color: $2
    $scripts = Get-ChildItem -Path (Join-Path $RepositoryPath "automation-scripts") -Filter "*.ps1" -Recurse

    $progress = 0
    foreach ($script in $scripts) {
        $progress++
        Write-Progress -Activity "Analyzing dependencies" -Status "$progress of $($scripts.Count)" -PercentComplete (($progress / $scripts.Count) * 100)
        $analyzer.AnalyzeScript($script.FullName)
    }
}

Write-Output "`nChecking installed modules..." # Color: $2
$InstallStatus = $analyzer.CheckInstalledModules()

Write-Output "Installed: $($InstallStatus.Installed.Count) modules" # Color: $2
Write-Output "Missing: $($InstallStatus.Missing.Count) modules" -ForegroundColor $(if ($InstallStatus.Missing.Count -gt 0) { "Red" } else { "Green" })

if ($InstallMissing -and $InstallStatus.Missing.Count -gt 0) {
    Write-Output "`nInstalling missing modules..." # Color: $2
    foreach ($module in $InstallStatus.Missing) {
        try {
            Write-Output "Installing $module..." -NoNewline
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
            Write-Output " " # Color: $2
        } catch {
            Write-Output "Failed: $_" # Color: $2
        }
    }
}

if ($GenerateReport) {
    $ReportPath = Join-Path $RepositoryPath "DEPENDENCY-REPORT.md"
    $report = $analyzer.GenerateReport()
    $report | Out-File $ReportPath -Encoding UTF8
    Write-Output "`nDependency report saved to: $ReportPath" # Color: $2

    $analyzer.GenerateDependencyGraph()
    Write-Output "Dependency graph saved to: $(Join-Path $RepositoryPath 'dependency-graph.md')" # Color: $2
}

if ($ValidateAzureModules) {
    Write-Output "`nValidating Azure module versions..." # Color: $2
    $AzModules = $InstallStatus.Installed | Where-Object { $_ -like "Az.*" }

    foreach ($module in $AzModules) {
        $current = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        $latest = Find-Module -Name $module -ErrorAction SilentlyContinue

        if ($latest -and $current.Version -lt $latest.Version) {
            Write-Output "$module : Current v$($current.Version) -> Available v$($latest.Version)" # Color: $2
        } else {
            Write-Output "$module : v$($current.Version) (latest)" # Color: $2
        }
    }
}

Write-Output "`nDependency analysis complete!" # Color: $2




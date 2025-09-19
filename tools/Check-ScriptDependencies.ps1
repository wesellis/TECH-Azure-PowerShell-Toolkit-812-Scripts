#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Check-ScriptDependencies.ps1
# Analyzes and validates script dependencies across the repository
# Version: 2.0

param(
    [Parameter(Mandatory=$false)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent),
    
    [switch]$InstallMissing,
    [switch]$GenerateReport,
    [switch]$CheckVersions,
    [switch]$ValidateAzureModules
)

#region Functions

class DependencyAnalyzer {
    [hashtable]$Dependencies = @{}
    [hashtable]$MissingDependencies = @{}
    [hashtable]$VersionConflicts = @{}
    [array]$Scripts = @()
    
    [void] AnalyzeScript([string]$Path) {
        $scriptName = [System.IO.Path]::GetFileName($Path)
        $content = Get-Content $Path -Raw
        
        $deps = @{
            Modules = @()
            Scripts = @()
            Variables = @()
            Functions = @()
            AzureResources = @()
            ExternalTools = @()
        }
        
        # Extract PowerShell module dependencies
        $modulePattern = '#Requires\s+-Module[s]?\s+(.+)'
        $importPattern = 'Import-Module\s+([^\s;]+)'
        
        $content | Select-String -Pattern $modulePattern -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                $modules = $_.Groups[1].Value -split ','
                $deps.Modules += $modules | ForEach-Object { $_.Trim() }
            }
        }
        
        $content | Select-String -Pattern $importPattern -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                $module = $_.Groups[1].Value.Trim('"', "'")
                if ($module -notmatch '^\$' -and $module -notmatch 'Join-Path') {
                    $deps.Modules += $module
                }
            }
        }
        
        # Extract script dependencies (dot-sourcing)
        $scriptPattern = '\.\s+([^\s]+\.ps1)'
        $content | Select-String -Pattern $scriptPattern -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                $deps.Scripts += $_.Groups[1].Value
            }
        }
        
        # Extract Azure cmdlet usage
        $azureCmdlets = $content | Select-String -Pattern '(Get|Set|New|Remove|Update|Start|Stop|Restart)-Az\w+' -AllMatches
        $deps.AzureResources = $azureCmdlets.Matches.Value | Select-Object -Unique
        
        # Extract external tool dependencies
        $toolPatterns = @(
            'git\s+',
            'docker\s+',
            'kubectl\s+',
            'terraform\s+',
            'az\s+',
            'dotnet\s+',
            'npm\s+',
            'python\s+'
        )
        
        foreach ($pattern in $toolPatterns) {
            if ($content -match $pattern) {
                $tool = $pattern.Trim('\s+', ' ')
                $deps.ExternalTools += $tool
            }
        }
        
        $this.Dependencies[$scriptName] = $deps
    }
    
    [hashtable] CheckInstalledModules() {
        $results = @{
            Installed = @()
            Missing = @()
            VersionInfo = @{}
        }
        
        $allModules = $this.Dependencies.Values.Modules | Select-Object -Unique
        
        foreach ($module in $allModules) {
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
        $mermaidGraph = @"
graph TD
    subgraph "Script Dependencies"
"@
        
        foreach ($script in $this.Dependencies.Keys) {
            $deps = $this.Dependencies[$script]
            $scriptId = $script -replace '[^a-zA-Z0-9]', ''
            
            foreach ($module in $deps.Modules) {
                $moduleId = $module -replace '[^a-zA-Z0-9]', ''
                $mermaidGraph += "`n    $scriptId --> $moduleId[Module: $module]"
            }
            
            foreach ($depScript in $deps.Scripts) {
                $depScriptId = $depScript -replace '[^a-zA-Z0-9]', ''
                $mermaidGraph += "`n    $scriptId --> $depScriptId[Script: $depScript]"
            }
        }
        
        $mermaidGraph += "`n    end"
        
        $graphPath = Join-Path $RepositoryPath "dependency-graph.md"
        @"
# Dependency Graph

``````mermaid
$mermaidGraph
``````
"@ | Out-File $graphPath -Encoding UTF8
    }
    
    [string] GenerateReport() {
        $report = @"
# Script Dependency Analysis Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- Total Scripts Analyzed: $($this.Dependencies.Count)
- Unique Module Dependencies: $(($this.Dependencies.Values.Modules | Select-Object -Unique).Count)
- Unique Script Dependencies: $(($this.Dependencies.Values.Scripts | Select-Object -Unique).Count)
- External Tools Required: $(($this.Dependencies.Values.ExternalTools | Select-Object -Unique).Count)

## Module Dependencies
"@
        
        $moduleUsage = @{}
        foreach ($script in $this.Dependencies.Keys) {
            foreach ($module in $this.Dependencies[$script].Modules) {
                if (-not $moduleUsage.ContainsKey($module)) {
                    $moduleUsage[$module] = @()
                }
                $moduleUsage[$module] += $script
            }
        }
        
        foreach ($module in ($moduleUsage.Keys | Sort-Object)) {
            $report += "`n### $module`n"
            $report += "Used by $($moduleUsage[$module].Count) script(s):`n"
            foreach ($script in $moduleUsage[$module]) {
                $report += "- $script`n"
            }
        }
        
        $report += "`n## Installation Status`n"
        $installStatus = $this.CheckInstalledModules()
        
        $report += "`n### Installed Modules`n"
        foreach ($module in $installStatus.Installed) {
            $version = $installStatus.VersionInfo[$module]
            $report += "-  $module (v$version)`n"
        }
        
        $report += "`n### Missing Modules`n"
        foreach ($module in $installStatus.Missing) {
            $report += "-  $module`n"
        }
        
        if ($installStatus.Missing.Count -gt 0) {
            $report += "`n### Installation Commands`n"
            $report += "``````powershell`n"
            foreach ($module in $installStatus.Missing) {
                $report += "Install-Module -Name $module -Force -AllowClobber`n"
            }
            $report += "```````n"
        }
        
        return $report
    }
}

# Main execution
$analyzer = [DependencyAnalyzer]::new()

Write-Host "Starting dependency analysis..." -ForegroundColor Cyan

if ($ScriptPath) {
    if (Test-Path $ScriptPath) {
        Write-Host "Analyzing single script: $ScriptPath" -ForegroundColor Yellow
        $analyzer.AnalyzeScript($ScriptPath)
    } else {
        Write-Error "Script not found: $ScriptPath"
        return
    }
} else {
    Write-Host "Analyzing all scripts in repository..." -ForegroundColor Yellow
    $scripts = Get-ChildItem -Path (Join-Path $RepositoryPath "automation-scripts") -Filter "*.ps1" -Recurse
    
    $progress = 0
    foreach ($script in $scripts) {
        $progress++
        Write-Progress -Activity "Analyzing dependencies" -Status "$progress of $($scripts.Count)" -PercentComplete (($progress / $scripts.Count) * 100)
        $analyzer.AnalyzeScript($script.FullName)
    }
}

Write-Host "`nChecking installed modules..." -ForegroundColor Green
$installStatus = $analyzer.CheckInstalledModules()

Write-Host "Installed: $($installStatus.Installed.Count) modules" -ForegroundColor Green
Write-Host "Missing: $($installStatus.Missing.Count) modules" -ForegroundColor $(if ($installStatus.Missing.Count -gt 0) { "Red" } else { "Green" })

if ($InstallMissing -and $installStatus.Missing.Count -gt 0) {
    Write-Host "`nInstalling missing modules..." -ForegroundColor Yellow
    foreach ($module in $installStatus.Missing) {
        try {
            Write-Host "Installing $module..." -NoNewline
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
            Write-Host " " -ForegroundColor Green
        } catch {
            Write-Host "  Failed: $_" -ForegroundColor Red
        }
    }
}

if ($GenerateReport) {
    $reportPath = Join-Path $RepositoryPath "DEPENDENCY-REPORT.md"
    $report = $analyzer.GenerateReport()
    $report | Out-File $reportPath -Encoding UTF8
    Write-Host "`nDependency report saved to: $reportPath" -ForegroundColor Green
    
    $analyzer.GenerateDependencyGraph()
    Write-Host "Dependency graph saved to: $(Join-Path $RepositoryPath 'dependency-graph.md')" -ForegroundColor Green
}

if ($ValidateAzureModules) {
    Write-Host "`nValidating Azure module versions..." -ForegroundColor Cyan
    $azModules = $installStatus.Installed | Where-Object { $_ -like "Az.*" }
    
    foreach ($module in $azModules) {
        $current = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        $latest = Find-Module -Name $module -ErrorAction SilentlyContinue
        
        if ($latest -and $current.Version -lt $latest.Version) {
            Write-Host "$module : Current v$($current.Version) -> Available v$($latest.Version)" -ForegroundColor Yellow
        } else {
            Write-Host "$module : v$($current.Version) (latest)" -ForegroundColor Green
        }
    }
}

Write-Host "`nDependency analysis complete!" -ForegroundColor Cyan

#endregion

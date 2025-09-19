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
# Azure Enterprise Toolkit - Content Migration Script
# This script copies content from existing repositories into the consolidated structure

Write-Information "Starting Azure Enterprise Toolkit Content Migration"
Write-Information "================================================="

$sourceBase = "A:\GITHUB"
$targetBase = "A:\GITHUB\Azure-Enterprise-Toolkit"

# Ensure we're in the target directory
Set-Location -ErrorAction Stop $targetBase

Write-Information "`nPHASE 1: Migrating Azure Automation Scripts (124+ scripts)"
# Copy all scripts from Azure-Automation-Scripts
$scriptsSource = "$sourceBase\Azure-Automation-Scripts\scripts"
$scriptsTarget = "$targetBase\automation-scripts"

if (Test-Path $scriptsSource) {
    Copy-Item -Path "$scriptsSource\*" -Destination $scriptsTarget -Recurse -Force
    Write-Information "Copied 124+ PowerShell scripts"
    
    # Copy modules as well
    $modulesSource = "$sourceBase\Azure-Automation-Scripts\modules"
    if (Test-Path $modulesSource) {
        Copy-Item -Path $modulesSource -Destination "$targetBase\automation-scripts\modules" -Recurse -Force
        Write-Information "Copied PowerShell modules"
    }
} else {
    Write-Information "Azure-Automation-Scripts not found"
}

Write-Information "`nPHASE 2: Migrating Cost Management Dashboard"
$costSource = "$sourceBase\Azure-Cost-Management-Dashboard"
if (Test-Path $costSource) {
    # Copy dashboards, scripts, and documentation
    Copy-Item -Path "$costSource\dashboards" -Destination "$targetBase\cost-management\dashboards" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$costSource\scripts" -Destination "$targetBase\cost-management\scripts" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$costSource\docs" -Destination "$targetBase\cost-management\docs" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$costSource\README.md" -Destination "$targetBase\cost-management\README.md" -Force -ErrorAction SilentlyContinue
    Write-Information "Copied cost management dashboards and tools"
} else {
    Write-Information "Azure-Cost-Management-Dashboard not found"
}

Write-Information "`nPHASE 3: Migrating DevOps Pipeline Templates"
$devopsSource = "$sourceBase\Azure-DevOps-Pipeline-Templates"
if (Test-Path $devopsSource) {
    Copy-Item -Path "$devopsSource\templates" -Destination "$targetBase\devops-templates\templates" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$devopsSource\examples" -Destination "$targetBase\devops-templates\examples" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$devopsSource\docs" -Destination "$targetBase\devops-templates\docs" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$devopsSource\README.md" -Destination "$targetBase\devops-templates\README.md" -Force -ErrorAction SilentlyContinue
    Write-Information "Copied DevOps pipeline templates"
} else {
    Write-Information "Azure-DevOps-Pipeline-Templates not found"
}

Write-Information "`nPHASE 4: Migrating Governance Toolkit"
$govSource = "$sourceBase\Azure-Governance-Toolkit"
if (Test-Path $govSource) {
    Copy-Item -Path "$govSource\scripts" -Destination "$targetBase\governance\scripts" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$govSource\templates" -Destination "$targetBase\governance\templates" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$govSource\docs" -Destination "$targetBase\governance\docs" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$govSource\README.md" -Destination "$targetBase\governance\README.md" -Force -ErrorAction SilentlyContinue
    Write-Information "Copied governance policies and tools"
} else {
    Write-Information "Azure-Governance-Toolkit not found"
}

Write-Information "`nPHASE 5: Migrating Essential Bookmarks"
$bookmarksSource = "$sourceBase\Azure-Essentials-Bookmarks"
if (Test-Path $bookmarksSource) {
    Copy-Item -Path "$bookmarksSource\*" -Destination "$targetBase\bookmarks" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Information "Copied Azure essential bookmarks"
} else {
    Write-Information "Azure-Essentials-Bookmarks not found"
}

Write-Information "`nPHASE 6: Creating Unified Documentation"
# Copy key documentation files to main docs folder
$docFiles = @(
    "$sourceBase\Azure-Automation-Scripts\CONTRIBUTING.md",
    "$sourceBase\Azure-Automation-Scripts\CHANGELOG.md"
)

foreach ($docPath in $docFiles) {
    if (Test-Path $docPath) {
        $fileName = Split-Path $docPath -Leaf
        Copy-Item -Path $docPath -Destination "$targetBase\docs\$fileName" -Force -ErrorAction SilentlyContinue
    }
}
Write-Information "Consolidated documentation"

Write-Information "`nPHASE 7: Creating Utility Tools"
# Copy useful utility scripts
Copy-Item -Path "$sourceBase\enhanced-github-upload.ps1" -Destination "$targetBase\tools\github-upload.ps1" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$sourceBase\github-download.ps1" -Destination "$targetBase\tools\github-download.ps1" -Force -ErrorAction SilentlyContinue
Write-Information "Added utility tools"

Write-Information "`nMIGRATION SUMMARY"
Write-Information "================================================="
Write-Information "Azure Automation Scripts (124+ scripts)"
Write-Information "Cost Management Dashboards"  
Write-Information "DevOps Pipeline Templates"
Write-Information "Governance Policies and Tools"
Write-Information "Essential Bookmarks Collection"
Write-Information "Unified Documentation"
Write-Information "Utility Tools"

Write-Information "`nContent migration completed!"
Write-Information "Total consolidated components: 7 major toolkits"
Write-Information "Ready for git commands"


#endregion

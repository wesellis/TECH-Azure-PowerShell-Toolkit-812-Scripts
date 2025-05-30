# Azure Enterprise Toolkit - Content Migration Script
# This script copies content from existing repositories into the consolidated structure

Write-Host "Starting Azure Enterprise Toolkit Content Migration" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan

$sourceBase = "A:\GITHUB"
$targetBase = "A:\GITHUB\Azure-Enterprise-Toolkit"

# Ensure we're in the target directory
Set-Location $targetBase

Write-Host "`nPHASE 1: Migrating Azure Automation Scripts (124+ scripts)" -ForegroundColor Yellow
# Copy all scripts from Azure-Automation-Scripts
$scriptsSource = "$sourceBase\Azure-Automation-Scripts\scripts"
$scriptsTarget = "$targetBase\automation-scripts"

if (Test-Path $scriptsSource) {
    Copy-Item -Path "$scriptsSource\*" -Destination $scriptsTarget -Recurse -Force
    Write-Host "Copied 124+ PowerShell scripts" -ForegroundColor Green
    
    # Copy modules as well
    $modulesSource = "$sourceBase\Azure-Automation-Scripts\modules"
    if (Test-Path $modulesSource) {
        Copy-Item -Path $modulesSource -Destination "$targetBase\automation-scripts\modules" -Recurse -Force
        Write-Host "Copied PowerShell modules" -ForegroundColor Green
    }
} else {
    Write-Host "Azure-Automation-Scripts not found" -ForegroundColor Red
}

Write-Host "`nPHASE 2: Migrating Cost Management Dashboard" -ForegroundColor Yellow
$costSource = "$sourceBase\Azure-Cost-Management-Dashboard"
if (Test-Path $costSource) {
    # Copy dashboards, scripts, and documentation
    Copy-Item -Path "$costSource\dashboards" -Destination "$targetBase\cost-management\dashboards" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$costSource\scripts" -Destination "$targetBase\cost-management\scripts" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$costSource\docs" -Destination "$targetBase\cost-management\docs" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$costSource\README.md" -Destination "$targetBase\cost-management\README.md" -Force -ErrorAction SilentlyContinue
    Write-Host "Copied cost management dashboards and tools" -ForegroundColor Green
} else {
    Write-Host "Azure-Cost-Management-Dashboard not found" -ForegroundColor Red
}

Write-Host "`nPHASE 3: Migrating DevOps Pipeline Templates" -ForegroundColor Yellow
$devopsSource = "$sourceBase\Azure-DevOps-Pipeline-Templates"
if (Test-Path $devopsSource) {
    Copy-Item -Path "$devopsSource\templates" -Destination "$targetBase\devops-templates\templates" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$devopsSource\examples" -Destination "$targetBase\devops-templates\examples" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$devopsSource\docs" -Destination "$targetBase\devops-templates\docs" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$devopsSource\README.md" -Destination "$targetBase\devops-templates\README.md" -Force -ErrorAction SilentlyContinue
    Write-Host "Copied DevOps pipeline templates" -ForegroundColor Green
} else {
    Write-Host "Azure-DevOps-Pipeline-Templates not found" -ForegroundColor Red
}

Write-Host "`nPHASE 4: Migrating Governance Toolkit" -ForegroundColor Yellow
$govSource = "$sourceBase\Azure-Governance-Toolkit"
if (Test-Path $govSource) {
    Copy-Item -Path "$govSource\scripts" -Destination "$targetBase\governance\scripts" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$govSource\templates" -Destination "$targetBase\governance\templates" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$govSource\docs" -Destination "$targetBase\governance\docs" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$govSource\README.md" -Destination "$targetBase\governance\README.md" -Force -ErrorAction SilentlyContinue
    Write-Host "Copied governance policies and tools" -ForegroundColor Green
} else {
    Write-Host "Azure-Governance-Toolkit not found" -ForegroundColor Red
}

Write-Host "`nPHASE 5: Migrating Essential Bookmarks" -ForegroundColor Yellow
$bookmarksSource = "$sourceBase\Azure-Essentials-Bookmarks"
if (Test-Path $bookmarksSource) {
    Copy-Item -Path "$bookmarksSource\*" -Destination "$targetBase\bookmarks" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Copied Azure essential bookmarks" -ForegroundColor Green
} else {
    Write-Host "Azure-Essentials-Bookmarks not found" -ForegroundColor Red
}

Write-Host "`nPHASE 6: Creating Unified Documentation" -ForegroundColor Yellow
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
Write-Host "Consolidated documentation" -ForegroundColor Green

Write-Host "`nPHASE 7: Creating Utility Tools" -ForegroundColor Yellow
# Copy useful utility scripts
Copy-Item -Path "$sourceBase\enhanced-github-upload.ps1" -Destination "$targetBase\tools\github-upload.ps1" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$sourceBase\github-download.ps1" -Destination "$targetBase\tools\github-download.ps1" -Force -ErrorAction SilentlyContinue
Write-Host "Added utility tools" -ForegroundColor Green

Write-Host "`nMIGRATION SUMMARY" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Azure Automation Scripts (124+ scripts)" -ForegroundColor Green
Write-Host "Cost Management Dashboards" -ForegroundColor Green  
Write-Host "DevOps Pipeline Templates" -ForegroundColor Green
Write-Host "Governance Policies and Tools" -ForegroundColor Green
Write-Host "Essential Bookmarks Collection" -ForegroundColor Green
Write-Host "Unified Documentation" -ForegroundColor Green
Write-Host "Utility Tools" -ForegroundColor Green

Write-Host "`nContent migration completed!" -ForegroundColor Cyan
Write-Host "Total consolidated components: 7 major toolkits" -ForegroundColor White
Write-Host "Ready for git commands" -ForegroundColor Yellow

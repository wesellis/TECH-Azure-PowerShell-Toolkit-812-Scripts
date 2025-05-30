# Initialize Azure Enterprise Toolkit Repository
Write-Host "🚀 Initializing Azure Enterprise Toolkit Git Repository" -ForegroundColor Green

Set-Location "A:\GITHUB\Azure-Enterprise-Toolkit"

# Initialize Git repository
git init
Write-Host "✅ Git repository initialized" -ForegroundColor Green

# Add remote origin
git remote add origin https://github.com/wesellis/Azure-Enterprise-Toolkit.git
Write-Host "✅ Remote origin added" -ForegroundColor Green

# Create initial README
$readmeContent = @"
# Azure Enterprise Toolkit

Enterprise-grade Azure automation toolkit with 124+ PowerShell scripts, cost management dashboards, DevOps templates, governance policies, and essential bookmarks for comprehensive Azure administration.

## Repository Structure

- **automation-scripts/** - 124+ PowerShell automation scripts
- **cost-management/** - Cost analysis dashboards and tools  
- **devops-templates/** - CI/CD pipeline templates
- **governance/** - Policy and compliance tools
- **bookmarks/** - Essential Azure resource links
- **docs/** - Comprehensive documentation
- **tools/** - Utility scripts and helpers

## Quick Start

Coming soon! Content is being migrated from existing repositories.

## Status

🚧 **Under Construction** - Content being consolidated from multiple repositories
"@

$readmeContent | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "✅ Initial README created" -ForegroundColor Green

# Add and commit initial structure
git add .
git commit -m "Initial repository structure and README"
Write-Host "✅ Initial commit created" -ForegroundColor Green

# Set default branch and push
git branch -M main
git push -u origin main
Write-Host "✅ Repository pushed to GitHub" -ForegroundColor Green

Write-Host "`n🎉 Repository is now initialized and connected to GitHub!" -ForegroundColor Cyan
Write-Host "Ready for content migration from existing repositories." -ForegroundColor Yellow

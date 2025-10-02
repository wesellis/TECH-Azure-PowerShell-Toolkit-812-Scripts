#Requires -Version 7.0
<#
.SYNOPSIS
    initialize repo
.DESCRIPTION
    initialize repo operation
    Author: Wes Ellis (wes@wesellis.com)

    initialize repocom)
Write-Output "Initializing Azure Enterprise Toolkit Git Repository"

Set-Location -ErrorAction Stop "A:\GITHUB\Azure-Enterprise-Toolkit"

git init
Write-Output "Git repository initialized"

git remote add origin https://github.com/wesellis/Azure-Enterprise-Toolkit.git
Write-Output "Remote origin added"

$ReadmeContent = @"


- **automation-scripts/** - 124+ PowerShell automation scripts
- **cost-management/** - Cost analysis dashboards and tools
- **devops-templates/** - CI/CD pipeline templates
- **governance/** - Policy and compliance tools
- **bookmarks/** - Essential Azure resource links
- **docs/** -
- **tools/** - Utility scripts and helpers


Coming soon! Content is being migrated from existing repositories.


 **Under Construction** - Content being consolidated from multiple repositories
"@

$ReadmeContent | Out-File -FilePath "README.md" -Encoding UTF8
Write-Output "Initial README created"

git add .
git commit -m "Initial repository structure and README"
Write-Output "Initial commit created"

git branch -M main
git push -u origin main
Write-Output "Repository pushed to GitHub"

Write-Output "`n Repository is now initialized and connected to GitHub!"
Write-Output "Ready for content migration from existing repositories."


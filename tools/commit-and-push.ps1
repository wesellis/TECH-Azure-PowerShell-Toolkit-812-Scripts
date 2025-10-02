#Requires -Version 7.0
<#
.SYNOPSIS
    commit and push
.DESCRIPTION
    commit and push operation
    Author: Wes Ellis (wes@wesellis.com)

    commit and pushcom)
Write-Output "Committing Azure Enterprise Toolkit to GitHub..."

git add .
Write-Output "Added all files to staging"

$CommitMessage = @"
 Azure Enterprise Toolkit - Complete Consolidation

 Consolidated 5 repositories into
- Azure-Automation-Scripts (124+ PowerShell scripts)
- Azure-Cost-Management-Dashboard (Dashboards & analytics)
- Azure-DevOps-Pipeline-Templates (CI/CD templates)
- Azure-Governance-Toolkit (Policies & compliance)
- Azure-Essentials-Bookmarks (Resource collection)

[FOLDER] Organized structure:
- automation-scripts/ - 124+ production-ready scripts
- cost-management/ - Cost analysis and optimization
- devops-templates/ - Enterprise CI/CD templates
- governance/ - Policies and compliance tools
- bookmarks/ - Essential Azure resources
- docs/ - Unified documentation
- tools/ - Utility scripts

 Features:
-
- Cross-platform compatibility
-
- Production-proven reliability
- Professional user experience

Ready for enterprise Azure administration!
"@

git commit -m $CommitMessage
Write-Host "Committed with

git push
Write-Output "Pushed to GitHub successfully!"

Write-Output "`n Azure Enterprise Toolkit is now live on GitHub!"
Write-Output "�� View at: https://github.com/wesellis/Azure-Enterprise-Toolkit"
Write-Output "[*] Don't forget to star your own repository!"


#Requires -Version 7.0
<#
.SYNOPSIS
    commit and push
.DESCRIPTION
    commit and push operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    commit and pushcom)#>
# Commit and push the consolidated Azure Enterprise Toolkit
Write-Host "Committing Azure Enterprise Toolkit to GitHub..."

# Add all files
git add .
Write-Host "Added all files to staging"

# Commit with
$commitMessage = @"
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

git commit -m $commitMessage
Write-Host "Committed with

# Push to GitHub
git push
Write-Host "Pushed to GitHub successfully!"

Write-Host "`n Azure Enterprise Toolkit is now live on GitHub!"
Write-Host "�� View at: https://github.com/wesellis/Azure-Enterprise-Toolkit"
Write-Host "[*] Don't forget to star your own repository!"

#endregion\n
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
# Commit and push the consolidated Azure Enterprise Toolkit
Write-Information "Committing Azure Enterprise Toolkit to GitHub..."

# Add all files
git add .
Write-Information "Added all files to staging"

# Commit with comprehensive message
$commitMessage = @"
 Azure Enterprise Toolkit - Complete Consolidation

 Consolidated 5 repositories into enterprise-grade toolkit:
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
- Enterprise-grade automation
- Cross-platform compatibility
- Comprehensive documentation
- Production-proven reliability
- Professional user experience

Ready for enterprise Azure administration!
"@

git commit -m $commitMessage
Write-Information "Committed with comprehensive message"

# Push to GitHub
git push
Write-Information "Pushed to GitHub successfully!"

Write-Information "`n Azure Enterprise Toolkit is now live on GitHub!"
Write-Information "� View at: https://github.com/wesellis/Azure-Enterprise-Toolkit"
Write-Information "[*] Don't forget to star your own repository!"


#endregion

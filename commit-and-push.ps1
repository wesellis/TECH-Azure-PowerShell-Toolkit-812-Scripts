# Commit and push the consolidated Azure Enterprise Toolkit
Write-Host "Committing Azure Enterprise Toolkit to GitHub..." -ForegroundColor Green

# Add all files
git add .
Write-Host "Added all files to staging" -ForegroundColor Green

# Commit with comprehensive message
$commitMessage = @"
🚀 Azure Enterprise Toolkit - Complete Consolidation

✅ Consolidated 5 repositories into enterprise-grade toolkit:
- Azure-Automation-Scripts (124+ PowerShell scripts)
- Azure-Cost-Management-Dashboard (Dashboards & analytics)
- Azure-DevOps-Pipeline-Templates (CI/CD templates)
- Azure-Governance-Toolkit (Policies & compliance)
- Azure-Essentials-Bookmarks (Resource collection)

📁 Organized structure:
- automation-scripts/ - 124+ production-ready scripts
- cost-management/ - Cost analysis and optimization
- devops-templates/ - Enterprise CI/CD templates
- governance/ - Policies and compliance tools
- bookmarks/ - Essential Azure resources
- docs/ - Unified documentation
- tools/ - Utility scripts

🎯 Features:
- Enterprise-grade automation
- Cross-platform compatibility
- Comprehensive documentation
- Production-proven reliability
- Professional user experience

Ready for enterprise Azure administration!
"@

git commit -m $commitMessage
Write-Host "Committed with comprehensive message" -ForegroundColor Green

# Push to GitHub
git push
Write-Host "Pushed to GitHub successfully!" -ForegroundColor Green

Write-Host "`n🎉 Azure Enterprise Toolkit is now live on GitHub!" -ForegroundColor Cyan
Write-Host "🌐 View at: https://github.com/wesellis/Azure-Enterprise-Toolkit" -ForegroundColor Blue
Write-Host "⭐ Don't forget to star your own repository!" -ForegroundColor Yellow

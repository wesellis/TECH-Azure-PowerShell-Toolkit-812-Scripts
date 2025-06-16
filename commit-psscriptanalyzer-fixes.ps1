# Commit PSScriptAnalyzer fixes for Virtual WAN Management Tool
Write-Host "🔧 Committing PSScriptAnalyzer fixes..." -ForegroundColor Green

# Change to repository directory
Set-Location "A:\GITHUB\Azure-Enterprise-Toolkit"

# Check git status
Write-Host "📋 Checking git status..." -ForegroundColor Yellow
git status --porcelain

# Add the specific file that was fixed
Write-Host "✅ Adding fixed file to staging..." -ForegroundColor Green
git add "automation-scripts/Network-Security/Azure-Virtual-WAN-Management-Tool.ps1"

# Commit with specific message about the fixes
$commitMessage = @"
🔧 Fix PSScriptAnalyzer ShouldProcess warnings in Virtual WAN tool

- Fixed 8 functions with ShouldProcess attribute but missing ShouldProcess calls
- Added proper ShouldProcess calls to all creation/modification functions  
- Added ShouldContinue calls for destructive operations in Remove-VirtualHub
- Removed ShouldProcess attribute from read-only Get-VirtualWANStatus function
- All PSScriptAnalyzer warnings resolved for CI pipeline

Functions fixed:
- New-ExpressRouteGateway
- New-AzureFirewall
- New-VpnSite  
- Set-P2SVpnConfiguration
- New-HubRouteTable
- Set-VirtualWANMonitoring
- Set-SecurityBaseline
- Remove-VirtualHub
"@

Write-Host "✅ Committing fixes with detailed message..." -ForegroundColor Green
git commit -m $commitMessage

# Push to GitHub
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Green
git push

Write-Host "`n🎉 PSScriptAnalyzer fixes deployed!" -ForegroundColor Cyan
Write-Host "⏱️  CI pipeline should now pass on next run" -ForegroundColor Yellow
Write-Host "🌐 View CI status at: https://github.com/wesellis/Azure-Enterprise-Toolkit/actions" -ForegroundColor Blue

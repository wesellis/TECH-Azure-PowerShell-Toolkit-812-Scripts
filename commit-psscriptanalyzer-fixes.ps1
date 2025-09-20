#Requires -Version 7.0
#Requires -Module Az.Resources
<#
.SYNOPSIS
    commit psscriptanalyzer fixes
.DESCRIPTION
    commit psscriptanalyzer fixes operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    commit psscriptanalyzer fixescom)#>
# Commit PSScriptAnalyzer fixes for Virtual WAN Management Tool
Write-Host "Committing PSScriptAnalyzer fixes..."

# Change to repository directory
Set-Location -ErrorAction Stop "A:\GITHUB\Azure-Enterprise-Toolkit"

# Check git status
Write-Host "�� Checking git status..."
git status --porcelain

# Add the specific file that was fixed
Write-Host "Adding fixed file to staging..."
git add "automation-scripts/Network-Security/Azure-Virtual-WAN-Management-Tool.ps1"

# Commit with specific message about the fixes
$commitMessage = @"
 Fix PSScriptAnalyzer ShouldProcess warnings in Virtual WAN tool

- Fixed 8 functions with ShouldProcess attribute but missing ShouldProcess calls
- Added proper ShouldProcess calls to all creation/modification functions  
- Added ShouldContinue calls for destructive operations in Remove-VirtualHub
- Removed ShouldProcess attribute from read-only Get-VirtualWANStatus -ErrorAction Stop function
- All PSScriptAnalyzer warnings resolved for CI pipeline

Functions fixed:
- New-ExpressRouteGateway
- New-AzureFirewall
- New-VpnSite -ErrorAction Stop  
- Set-P2SVpnConfiguration
- New-HubRouteTable
- Set-VirtualWANMonitoring
- Set-SecurityBaseline
- Remove-VirtualHub -ErrorAction Stop
"@

Write-Host "Committing fixes with detailed message..."
git commit -m $commitMessage

# Push to GitHub
Write-Host "Pushing to GitHub..."
git push

Write-Host "`n PSScriptAnalyzer fixes deployed!"
Write-Host "CI pipeline should now pass on next run"
Write-Host "�� View CI status at: https://github.com/wesellis/Azure-Enterprise-Toolkit/actions"

#endregion\n
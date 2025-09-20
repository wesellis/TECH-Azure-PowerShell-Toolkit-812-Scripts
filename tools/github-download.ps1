#Requires -Version 7.0
<#
.SYNOPSIS
    github download
.DESCRIPTION
    github download operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    github downloadcom)#>
# GitHub Repository Downloader
# Downloads/updates all Wesley's repositories from GitHub
# Usage: Run this script to get the latest versions of all repositories

Write-Host "=== GitHub Repository Downloader ==="
Write-Host "Downloading/updating all repositories from github.com/wesellis"

$githubUsername = "wesellis"
$baseDir = "A:\GITHUB"
Set-Location -ErrorAction Stop $baseDir

# Add Git to PATH
$env:PATH += ";C:\Program Files\Git\bin"

# All repositories
$repositories = @(
    "epic-games-tool",
    "epic-manifest-updater", 
    "wesellis",
    "CBR-to-CBZ-Converter",
    "Azure-DevOps-Pipeline-Templates",
    "Microsoft-Graph-API-Explorer",
    "Azure-Governance-Toolkit",
    "Microsoft-Teams-Automation-Bot",
	"VAPOR",
    "Azure-Automation-Scripts",
    "Defender-for-Cloud-Security-Playbooks",
    "Azure-Cost-Management-Dashboard",
    "Intune-Device-Management-Tools",
    "Azure-Essentials-Bookmarks",
    "YouTube-Subscription-Copier",
	"ProfilePop",
    "PowerShell-for-Azure-Intune-Management"
)

$updated = 0
$downloaded = 0
$failed = 0

foreach ($repo in $repositories) {
    $repoUrl = "https://github.com/$githubUsername/$repo.git"
    $localPath = Join-Path $baseDir $repo
    
    if (Test-Path $localPath) {
        Write-Host "Updating $repo..."
        try {
            Set-Location -ErrorAction Stop $localPath
            git pull --quiet
            Set-Location -ErrorAction Stop $baseDir
            Write-Host "Updated successfully"
            $updated++
        } catch {
            Write-Host "Update failed"
            Set-Location -ErrorAction Stop $baseDir
            $failed++
        }
    } else {
        Write-Host "Downloading $repo..."
        try {
            git clone $repoUrl --quiet
            if (Test-Path $localPath) {
                Write-Host "Downloaded successfully"
                $downloaded++
            } else {
                Write-Host "Download failed"
                $failed++
            }
        } catch {
            Write-Host "Download failed"
            $failed++
        }
    }
}

Write-Host "`n=== RESULTS ==="
Write-Host "Updated: $updated repositories"
Write-Host "Downloaded: $downloaded repositories"
Write-Host "Failed: $failed repositories"
Write-Host "Total: $($repositories.Count) repositories"

Write-Host "`nAll repositories are now up to date!"

#endregion\n
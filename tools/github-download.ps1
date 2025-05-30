# GitHub Repository Downloader
# Downloads/updates all Wesley's repositories from GitHub
# Usage: Run this script to get the latest versions of all repositories

Write-Host "=== GitHub Repository Downloader ===" -ForegroundColor Green
Write-Host "Downloading/updating all repositories from github.com/wesellis" -ForegroundColor Cyan

$githubUsername = "wesellis"
$baseDir = "A:\GITHUB"
Set-Location $baseDir

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
        Write-Host "Updating $repo..." -ForegroundColor Yellow
        try {
            Set-Location $localPath
            git pull --quiet
            Set-Location $baseDir
            Write-Host "  Updated successfully" -ForegroundColor Green
            $updated++
        } catch {
            Write-Host "  Update failed" -ForegroundColor Red
            Set-Location $baseDir
            $failed++
        }
    } else {
        Write-Host "Downloading $repo..." -ForegroundColor Cyan
        try {
            git clone $repoUrl --quiet
            if (Test-Path $localPath) {
                Write-Host "  Downloaded successfully" -ForegroundColor Green
                $downloaded++
            } else {
                Write-Host "  Download failed" -ForegroundColor Red
                $failed++
            }
        } catch {
            Write-Host "  Download failed" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host "`n=== RESULTS ===" -ForegroundColor Green
Write-Host "Updated: $updated repositories" -ForegroundColor Green
Write-Host "Downloaded: $downloaded repositories" -ForegroundColor Green
Write-Host "Failed: $failed repositories" -ForegroundColor Red
Write-Host "Total: $($repositories.Count) repositories" -ForegroundColor Cyan

Write-Host "`nAll repositories are now up to date!" -ForegroundColor Green

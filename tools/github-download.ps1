# GitHub Repository Downloader
# Downloads/updates all Wesley's repositories from GitHub
# Usage: Run this script to get the latest versions of all repositories

Write-Information "=== GitHub Repository Downloader ==="
Write-Information "Downloading/updating all repositories from github.com/wesellis"

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
        Write-Information "Updating $repo..."
        try {
            Set-Location -ErrorAction Stop $localPath
            git pull --quiet
            Set-Location -ErrorAction Stop $baseDir
            Write-Information "  Updated successfully"
            $updated++
        } catch {
            Write-Information "  Update failed"
            Set-Location -ErrorAction Stop $baseDir
            $failed++
        }
    } else {
        Write-Information "Downloading $repo..."
        try {
            git clone $repoUrl --quiet
            if (Test-Path $localPath) {
                Write-Information "  Downloaded successfully"
                $downloaded++
            } else {
                Write-Information "  Download failed"
                $failed++
            }
        } catch {
            Write-Information "  Download failed"
            $failed++
        }
    }
}

Write-Information "`n=== RESULTS ==="
Write-Information "Updated: $updated repositories"
Write-Information "Downloaded: $downloaded repositories"
Write-Information "Failed: $failed repositories"
Write-Information "Total: $($repositories.Count) repositories"

Write-Information "`nAll repositories are now up to date!"

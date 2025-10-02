#Requires -Version 7.0
<#
.SYNOPSIS
    github download
.DESCRIPTION
    github download operation
    Author: Wes Ellis (wes@wesellis.com)

    github downloadcom)

Write-Output "=== GitHub Repository Downloader ==="
Write-Output "Downloading/updating all repositories from github.com/wesellis"

$GithubUsername = "wesellis"
$BaseDir = "A:\GITHUB"
Set-Location -ErrorAction Stop $BaseDir

$env:PATH += ";C:\Program Files\Git\bin"

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
    $RepoUrl = "https://github.com/$GithubUsername/$repo.git"
    $LocalPath = Join-Path $BaseDir $repo

    if (Test-Path $LocalPath) {
        Write-Output "Updating $repo..."
        try {
            Set-Location -ErrorAction Stop $LocalPath
            git pull --quiet
            Set-Location -ErrorAction Stop $BaseDir
            Write-Output "Updated successfully"
            $updated++
        } catch {
            Write-Output "Update failed"
            Set-Location -ErrorAction Stop $BaseDir
            $failed++
        }
    } else {
        Write-Output "Downloading $repo..."
        try {
            git clone $RepoUrl --quiet
            if (Test-Path $LocalPath) {
                Write-Output "Downloaded successfully"
                $downloaded++
            } else {
                Write-Output "Download failed"
                $failed++
            }
        } catch {
            Write-Output "Download failed"
            $failed++
        }
    }
}

Write-Output "`n=== RESULTS ==="
Write-Output "Updated: $updated repositories"
Write-Output "Downloaded: $downloaded repositories"
Write-Output "Failed: $failed repositories"
Write-Output "Total: $($repositories.Count) repositories"

Write-Output "`nAll repositories are now up to date!"


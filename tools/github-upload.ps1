#Requires -Version 7.0
<#
.SYNOPSIS
    github upload
.DESCRIPTION
    github upload operation
    Author: Wes Ellis (wes@wesellis.com)

    Uploads local repository changes to GitHub with detailed status reporting

    This script checks for changes in local Git repositories and uploads them to GitHub.
    It provides detailed status reporting, handles untracked files, and can work with
    single repositories or scan multiple repositories in a base directory.
.PARAMETER RepositoryPath
    Path to specific repository to upload (optional)
.PARAMETER BaseDirectory
    Base directory containing multiple repositories to scan
.PARAMETER CommitMessage
    Custom commit message (defaults to timestamp-based message)
.PARAMETER Force
    Force push even if there are no apparent changes
.PARAMETER WhatIf
    Show what would be done without making changes

    .\Invoke-GitHubUpload.ps1 -RepositoryPath "C:\Source\MyRepo"

    Uploads changes from a specific repository

    .\Invoke-GitHubUpload.ps1 -BaseDirectory "C:\Source" -WhatIf

    Shows what would be uploaded from all repositories in the base directory

    Author: Wes Ellis (wes@wesellis.com)

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RepositoryPath,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$BaseDirectory = "A:\GITHUB",

    [Parameter(Mandatory = $false)]
    [string]$CommitMessage,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$GitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $GitPath) {
    $env:PATH += ";C:\Program Files\Git\bin"
    $GitPath = Get-Command git -ErrorAction SilentlyContinue
    if (-not $GitPath) {
        throw "Git is not available in PATH. Please install Git or update PATH."
    }
}
$UploadStats = @{
    RepositoriesProcessed = 0
    RepositoriesWithChanges = 0
    RepositoriesUploaded = 0
    Errors = @()
}


function Write-Log {
    param(
        [string]$Title
    )
    $separator = '=' * ($Title.Length + 10)
    Write-Output "=== $Title ===" -InformationAction Continue
    Write-Output $separator -InformationAction Continue
}

function Test-GitRepository {
    param(
        [string]$Path
    )
    $GitDir = Join-Path $Path ".git"
    return (Test-Path $GitDir)
}

function Get-GitStatus {
    param(
        [string]$RepositoryPath
    )

    try {
        Push-Location $RepositoryPath
        $result = @{
            HasChanges = $false
            StagedFiles = @()
            ModifiedFiles = @()
            UntrackedFiles = @()
            CurrentBranch = ''
            RemoteUrl = ''
        }
        $GitStatus = git status --porcelain 2>$null
        if ($GitStatus) {
            $result.HasChanges = $true
            $result.ModifiedFiles = $GitStatus -split "`n" | Where-Object { $_ -match '^.M|^M.' }
            $result.StagedFiles = $GitStatus -split "`n" | Where-Object { $_ -match '^A.|^M.' }
        }
        $UntrackedFiles = git ls-files --others --exclude-standard 2>$null
        if ($UntrackedFiles) {
            $result.UntrackedFiles = $UntrackedFiles -split "`n" | Where-Object { $_ }
            $result.HasChanges = $true
        }
        $result.CurrentBranch = git branch --show-current 2>$null
        $result.RemoteUrl = git remote get-url origin 2>$null

        return $result
    }
    catch {
        Write-Warning "Failed to get Git status for $RepositoryPath`: $_"
        return $null
    }
    finally {
        Pop-Location
    }
}

function Invoke-GitCommitAndPush {
    param(
        [string]$RepositoryPath,
        [string]$Message,
        [object]$Status
    )

    try {
        Push-Location $RepositoryPath
        $RepoName = Split-Path $RepositoryPath -Leaf

        if (-not $Message) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $Message = "Updated $RepoName - $timestamp"
        }

        if ($PSCmdlet.ShouldProcess($RepositoryPath, "Stage all changes")) {
            git add . 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to stage changes"
            }
        }

        if ($PSCmdlet.ShouldProcess($RepositoryPath, "Commit with message: $Message")) {
            git commit -m $Message 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to commit changes"
            }
            Write-Output "  [OK] Changes committed" -InformationAction Continue
        }

        if ($PSCmdlet.ShouldProcess($RepositoryPath, "Push to remote")) {
            git push 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Output "  [OK] Successfully pushed to GitHub" -InformationAction Continue
                return $true
            }
            else {
                Write-Warning "  [FAIL] Failed to push to GitHub - authentication may be required"
                return $false
            }
        }

        return $true
    }
    catch {
        Write-Warning "  [FAIL] Failed to upload changes: $_"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Show-RepositoryInfo {
    param(
        [string]$RepositoryPath,
        [object]$Status
    )
        $RepoName = Split-Path $RepositoryPath -Leaf
    Write-Output "`n--- Repository: $RepoName ---" -InformationAction Continue
    Write-Output "Path: $RepositoryPath" -InformationAction Continue
    Write-Output "Branch: $($Status.CurrentBranch)" -InformationAction Continue
    Write-Output "Remote: $($Status.RemoteUrl)" -InformationAction Continue

    if ($Status.ModifiedFiles.Count -gt 0) {
        Write-Output "Modified files: $($Status.ModifiedFiles.Count)" -InformationAction Continue
    }

    if ($Status.UntrackedFiles.Count -gt 0) {
        Write-Output "Untracked files: $($Status.UntrackedFiles.Count)" -InformationAction Continue
        $Status.UntrackedFiles | Select-Object -First 5 | ForEach-Object {
            Write-Output "  $_" -InformationAction Continue
        }
        if ($Status.UntrackedFiles.Count -gt 5) {
            Write-Output "  ... and $($Status.UntrackedFiles.Count - 5) more" -InformationAction Continue
        }
    }
}

function Get-RecentCommits {
    param(
        [string]$RepositoryPath,
        [int]$Count = 5
    )

    try {
        Push-Location $RepositoryPath
        $commits = git log --oneline -$Count 2>$null
        if ($commits) {
            Write-Output "Recent commits:" -InformationAction Continue
            $commits | ForEach-Object {
                Write-Output "  $_" -InformationAction Continue
            }

} catch {
        Write-Warning "Could not retrieve commit history: $_"
    }
    finally {
        Pop-Location
    }
}


try {
    Write-UploadHeader "GitHub Repository Uploader"
    $RepositoriesToProcess = @()

    if ($RepositoryPath) {
        if (-not (Test-GitRepository -Path $RepositoryPath)) {
            throw "Specified path is not a Git repository: $RepositoryPath"
        }
        $RepositoriesToProcess += $RepositoryPath
        Write-Output "Processing single repository: $RepositoryPath" -InformationAction Continue
    }
    else {
        if (-not (Test-Path $BaseDirectory)) {
            throw "Base directory does not exist: $BaseDirectory"
        }
        $RepositoriesToProcess = Get-ChildItem $BaseDirectory -Directory |
            Where-Object { Test-GitRepository -Path $_.FullName } |
            Select-Object -ExpandProperty FullName

        Write-Output "Found $($RepositoriesToProcess.Count) Git repositories in: $BaseDirectory" -InformationAction Continue
    }

    if ($RepositoriesToProcess.Count -eq 0) {
        Write-Warning "No Git repositories found to process."
        return
    }

    foreach ($RepoPath in $RepositoriesToProcess) {
        $UploadStats.RepositoriesProcessed++

        try {
            $status = Get-GitStatus -RepositoryPath $RepoPath
            if (-not $status) {
                $UploadStats.Errors += "Failed to get status for: $RepoPath"
                continue
            }

            Show-RepositoryInfo -RepositoryPath $RepoPath -Status $status

            if ($status.HasChanges -or $Force) {
                $UploadStats.RepositoriesWithChanges++

                if ($PSCmdlet.ShouldProcess($RepoPath, "Upload changes to GitHub")) {
                    $UploadResult = Invoke-GitCommitAndPush -RepositoryPath $RepoPath -Message $CommitMessage -Status $status
                    if ($UploadResult) {
                        $UploadStats.RepositoriesUploaded++
                        Get-RecentCommits -RepositoryPath $RepoPath
                    }
                }
                else {
                    Write-Output "  [WHATIF] Would upload changes" -InformationAction Continue
                }
            }
            else {
                Write-Output "  [OK] No changes to upload" -InformationAction Continue

        } catch {
            $ErrorMsg = "Failed to process repository $RepoPath`: $_"
            $UploadStats.Errors += $ErrorMsg
            Write-Warning $ErrorMsg
        }
    }

    Write-UploadHeader "Upload Summary"
    Write-Output "Repositories processed: $($UploadStats.RepositoriesProcessed)" -InformationAction Continue
    Write-Output "Repositories with changes: $($UploadStats.RepositoriesWithChanges)" -InformationAction Continue
    Write-Output "Repositories uploaded: $($UploadStats.RepositoriesUploaded)" -InformationAction Continue

    if ($UploadStats.Errors.Count -gt 0) {
        Write-Output "Errors encountered: $($UploadStats.Errors.Count)" -InformationAction Continue
        $UploadStats.Errors | ForEach-Object {
            Write-Warning "  - $_"
        }
    }
    else {
        Write-Output "No errors encountered" -InformationAction Continue
    }

    Write-Output "`nUpload process completed!" -InformationAction Continue
}
catch {
    Write-Error "Upload process failed: $_"
    throw`n}

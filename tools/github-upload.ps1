#Requires -Version 7.0
<#
.SYNOPSIS
    github upload
.DESCRIPTION
    github upload operation
    Author: Wes Ellis (wes@wesellis.com)
#>

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

    Author: Wes Ellis (wes@wesellis.com)#>

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

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Ensure Git is available
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    $env:PATH += ";C:\Program Files\Git\bin"
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitPath) {
        throw "Git is not available in PATH. Please install Git or update PATH."
    }
}

# Upload statistics
$uploadStats = @{
    RepositoriesProcessed = 0
    RepositoriesWithChanges = 0
    RepositoriesUploaded = 0
    Errors = @()
}

#endregion

#region Functions
[OutputType([bool])]
 {
    [CmdletBinding()]
    param(
        [string]$Title
    )

    $separator = '=' * ($Title.Length + 10)
    Write-Host "=== $Title ===" -InformationAction Continue
    Write-Host $separator -InformationAction Continue
}

function Test-GitRepository {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    $gitDir = Join-Path $Path ".git"
    return (Test-Path $gitDir)
}

function Get-GitStatus {
    [CmdletBinding()]
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

        # Get status
        $gitStatus = git status --porcelain 2>$null
        if ($gitStatus) {
            $result.HasChanges = $true
            $result.ModifiedFiles = $gitStatus -split "`n" | Where-Object { $_ -match '^.M|^M.' }
            $result.StagedFiles = $gitStatus -split "`n" | Where-Object { $_ -match '^A.|^M.' }
        }

        # Get untracked files
        $untrackedFiles = git ls-files --others --exclude-standard 2>$null
        if ($untrackedFiles) {
            $result.UntrackedFiles = $untrackedFiles -split "`n" | Where-Object { $_ }
            $result.HasChanges = $true
        }

        # Get branch info
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
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$RepositoryPath,
        [string]$Message,
        [object]$Status
    )

    try {
        Push-Location $RepositoryPath

        $repoName = Split-Path $RepositoryPath -Leaf

        if (-not $Message) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $Message = "Updated $repoName - $timestamp"
        }

        # Stage all changes
        if ($PSCmdlet.ShouldProcess($RepositoryPath, "Stage all changes")) {
            git add . 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to stage changes"
            }
        }

        # Commit changes
        if ($PSCmdlet.ShouldProcess($RepositoryPath, "Commit with message: $Message")) {
            git commit -m $Message 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to commit changes"
            }
            Write-Host "  [OK] Changes committed" -InformationAction Continue
        }

        # Push to remote
        if ($PSCmdlet.ShouldProcess($RepositoryPath, "Push to remote")) {
            git push 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Successfully pushed to GitHub" -InformationAction Continue
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
    [CmdletBinding()]
    param(
        [string]$RepositoryPath,
        [object]$Status
    )

    $repoName = Split-Path $RepositoryPath -Leaf
    Write-Host "`n--- Repository: $repoName ---" -InformationAction Continue
    Write-Host "Path: $RepositoryPath" -InformationAction Continue
    Write-Host "Branch: $($Status.CurrentBranch)" -InformationAction Continue
    Write-Host "Remote: $($Status.RemoteUrl)" -InformationAction Continue

    if ($Status.ModifiedFiles.Count -gt 0) {
        Write-Host "Modified files: $($Status.ModifiedFiles.Count)" -InformationAction Continue
    }

    if ($Status.UntrackedFiles.Count -gt 0) {
        Write-Host "Untracked files: $($Status.UntrackedFiles.Count)" -InformationAction Continue
        $Status.UntrackedFiles | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $_" -InformationAction Continue
        }
        if ($Status.UntrackedFiles.Count -gt 5) {
            Write-Host "  ... and $($Status.UntrackedFiles.Count - 5) more" -InformationAction Continue
        }
    }
}

function Get-RecentCommits {
    [CmdletBinding()]
    param(
        [string]$RepositoryPath,
        [int]$Count = 5
    )

    try {
        Push-Location $RepositoryPath
        $commits = git log --oneline -$Count 2>$null
        if ($commits) {
            Write-Host "Recent commits:" -InformationAction Continue
            $commits | ForEach-Object {
                Write-Host "  $_" -InformationAction Continue
            }
        
} catch {
        Write-Warning "Could not retrieve commit history: $_"
    }
    finally {
        Pop-Location
    }
}

#endregion

#region Main-Execution
try {
    Write-UploadHeader "GitHub Repository Uploader"

    # Determine repositories to process
    $repositoriesToProcess = @()

    if ($RepositoryPath) {
        # Process single repository
        if (-not (Test-GitRepository -Path $RepositoryPath)) {
            throw "Specified path is not a Git repository: $RepositoryPath"
        }
        $repositoriesToProcess += $RepositoryPath
        Write-Host "Processing single repository: $RepositoryPath" -InformationAction Continue
    }
    else {
        # Process all repositories in base directory
        if (-not (Test-Path $BaseDirectory)) {
            throw "Base directory does not exist: $BaseDirectory"
        }

        $repositoriesToProcess = Get-ChildItem $BaseDirectory -Directory |
            Where-Object { Test-GitRepository -Path $_.FullName } |
            Select-Object -ExpandProperty FullName

        Write-Host "Found $($repositoriesToProcess.Count) Git repositories in: $BaseDirectory" -InformationAction Continue
    }

    if ($repositoriesToProcess.Count -eq 0) {
        Write-Warning "No Git repositories found to process."
        return
    }

    # Process each repository
    foreach ($repoPath in $repositoriesToProcess) {
        $uploadStats.RepositoriesProcessed++

        try {
            $status = Get-GitStatus -RepositoryPath $repoPath
            if (-not $status) {
                $uploadStats.Errors += "Failed to get status for: $repoPath"
                continue
            }

            Show-RepositoryInfo -RepositoryPath $repoPath -Status $status

            if ($status.HasChanges -or $Force) {
                $uploadStats.RepositoriesWithChanges++

                if ($PSCmdlet.ShouldProcess($repoPath, "Upload changes to GitHub")) {
                    $uploadResult = Invoke-GitCommitAndPush -RepositoryPath $repoPath -Message $CommitMessage -Status $status
                    if ($uploadResult) {
                        $uploadStats.RepositoriesUploaded++
                        Get-RecentCommits -RepositoryPath $repoPath
                    }
                }
                else {
                    Write-Host "  [WHATIF] Would upload changes" -InformationAction Continue
                }
            }
            else {
                Write-Host "  [OK] No changes to upload" -InformationAction Continue
            
} catch {
            $errorMsg = "Failed to process repository $repoPath`: $_"
            $uploadStats.Errors += $errorMsg
            Write-Warning $errorMsg
        }
    }

    # Display summary
    Write-UploadHeader "Upload Summary"
    Write-Host "Repositories processed: $($uploadStats.RepositoriesProcessed)" -InformationAction Continue
    Write-Host "Repositories with changes: $($uploadStats.RepositoriesWithChanges)" -InformationAction Continue
    Write-Host "Repositories uploaded: $($uploadStats.RepositoriesUploaded)" -InformationAction Continue

    if ($uploadStats.Errors.Count -gt 0) {
        Write-Host "Errors encountered: $($uploadStats.Errors.Count)" -InformationAction Continue
        $uploadStats.Errors | ForEach-Object {
            Write-Warning "  - $_"
        }
    }
    else {
        Write-Host "No errors encountered" -InformationAction Continue
    }

    Write-Host "`nUpload process completed!" -InformationAction Continue
}
catch {
    Write-Error "Upload process failed: $_"
    throw
}

#endregion\n


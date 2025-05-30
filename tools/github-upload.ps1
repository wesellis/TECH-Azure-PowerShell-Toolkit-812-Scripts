# Enhanced GitHub Repository Uploader with Detailed Status
# Uploads local changes to GitHub for all repositories with better change detection

Write-Host "=== Enhanced GitHub Repository Uploader ===" -ForegroundColor Green
Write-Host "Checking and uploading local changes to github.com/wesellis" -ForegroundColor Cyan

$baseDir = "A:\GITHUB"
Set-Location $baseDir

# Add Git to PATH
$env:PATH += ";C:\Program Files\Git\bin"

# Focus on Azure-Automation-Scripts repository for detailed analysis
$repoPath = "A:\GITHUB\Azure-Automation-Scripts"
Write-Host "`n=== Detailed Analysis: Azure-Automation-Scripts ===" -ForegroundColor Yellow

if (Test-Path $repoPath) {
    Set-Location $repoPath
    
    Write-Host "Current directory: $((Get-Location).Path)" -ForegroundColor Cyan
    
    # Check if this is a Git repository
    if (Test-Path ".git") {
        Write-Host "✓ Git repository detected" -ForegroundColor Green
        
        # Get detailed Git status
        Write-Host "`nChecking Git status..." -ForegroundColor Cyan
        $gitStatus = git status --porcelain 2>$null
        
        if ([string]::IsNullOrWhiteSpace($gitStatus)) {
            Write-Host "Git status shows no changes" -ForegroundColor Yellow
            
            # Check for untracked files specifically
            Write-Host "`nChecking for untracked files..." -ForegroundColor Cyan
            $untrackedFiles = git ls-files --others --exclude-standard 2>$null
            
            if (![string]::IsNullOrWhiteSpace($untrackedFiles)) {
                Write-Host "Found untracked files:" -ForegroundColor Red
                $untrackedFiles -split "`n" | ForEach-Object { 
                    if (![string]::IsNullOrWhiteSpace($_)) {
                        Write-Host "  $_" -ForegroundColor White
                    }
                }
                
                # Add and commit untracked files
                Write-Host "`nAdding untracked files..." -ForegroundColor Yellow
                git add . 2>$null
                
                $newStatus = git status --porcelain 2>$null
                if (![string]::IsNullOrWhiteSpace($newStatus)) {
                    Write-Host "Files staged for commit:" -ForegroundColor Green
                    $newStatus -split "`n" | ForEach-Object { 
                        if (![string]::IsNullOrWhiteSpace($_)) {
                            Write-Host "  $_" -ForegroundColor White
                        }
                    }
                    
                    # Commit the changes
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $commitMessage = "Enhanced Azure Automation Scripts - Added enterprise features - $timestamp"
                    
                    Write-Host "`nCommitting changes..." -ForegroundColor Yellow
                    git commit -m $commitMessage 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✓ Changes committed successfully" -ForegroundColor Green
                        
                        # Push to GitHub
                        Write-Host "`nPushing to GitHub..." -ForegroundColor Yellow
                        git push 2>$null
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "✓ Successfully pushed to GitHub!" -ForegroundColor Green
                        } else {
                            Write-Host "✗ Failed to push to GitHub" -ForegroundColor Red
                            Write-Host "You may need to authenticate with GitHub" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "✗ Failed to commit changes" -ForegroundColor Red
                    }
                } else {
                    Write-Host "No changes after adding files" -ForegroundColor Gray
                }
            } else {
                Write-Host "No untracked files found" -ForegroundColor Gray
            }
        } else {
            Write-Host "Found changes to commit:" -ForegroundColor Green
            $gitStatus -split "`n" | ForEach-Object { 
                if (![string]::IsNullOrWhiteSpace($_)) {
                    Write-Host "  $_" -ForegroundColor White
                }
            }
            
            # Commit and push existing changes
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            git add . 2>$null
            git commit -m "Updated Azure Automation Scripts - $timestamp" 2>$null
            git push 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Changes uploaded successfully!" -ForegroundColor Green
            } else {
                Write-Host "✗ Failed to upload changes" -ForegroundColor Red
            }
        }
        
        # Show recent commits
        Write-Host "`nRecent commits:" -ForegroundColor Cyan
        git log --oneline -5 2>$null | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        
        # Show branch info
        Write-Host "`nBranch information:" -ForegroundColor Cyan
        $currentBranch = git branch --show-current 2>$null
        Write-Host "  Current branch: $currentBranch" -ForegroundColor White
        
        $remoteUrl = git remote get-url origin 2>$null
        Write-Host "  Remote URL: $remoteUrl" -ForegroundColor White
        
    } else {
        Write-Host "✗ Not a Git repository" -ForegroundColor Red
        Write-Host "Initialize Git repository? (y/n):" -ForegroundColor Yellow
        $response = Read-Host
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            git init 2>$null
            git remote add origin "https://github.com/wesellis/Azure-Automation-Scripts.git" 2>$null
            git add . 2>$null
            git commit -m "Initial commit with enhanced Azure automation scripts" 2>$null
            git branch -M main 2>$null
            git push -u origin main 2>$null
            
            Write-Host "✓ Repository initialized and pushed to GitHub" -ForegroundColor Green
        }
    }
} else {
    Write-Host "✗ Repository path not found: $repoPath" -ForegroundColor Red
}

Write-Host "`n=== Quick Check: All Repositories ===" -ForegroundColor Yellow

# Quick check of all repositories
$repositories = Get-ChildItem $baseDir -Directory | Where-Object { 
    $_.Name -notlike ".*" 
} | Select-Object -ExpandProperty Name

$summary = @{
    HasChanges = 0
    NoChanges = 0
    NotGitRepo = 0
}

foreach ($repo in $repositories) {
    $repoPath = Join-Path $baseDir $repo
    Set-Location $repoPath
    
    if (Test-Path ".git") {
        $status = git status --porcelain 2>$null
        $untracked = git ls-files --others --exclude-standard 2>$null
        
        if (![string]::IsNullOrWhiteSpace($status) -or ![string]::IsNullOrWhiteSpace($untracked)) {
            Write-Host "$repo - Has changes or untracked files" -ForegroundColor Yellow
            $summary.HasChanges++
        } else {
            Write-Host "$repo - No changes" -ForegroundColor Gray
            $summary.NoChanges++
        }
    } else {
        Write-Host "$repo - Not a Git repository" -ForegroundColor Red
        $summary.NotGitRepo++
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host "Repositories with changes: $($summary.HasChanges)" -ForegroundColor Yellow
Write-Host "Repositories with no changes: $($summary.NoChanges)" -ForegroundColor Gray
Write-Host "Not Git repositories: $($summary.NotGitRepo)" -ForegroundColor Red
Write-Host "Total repositories: $($repositories.Count)" -ForegroundColor Cyan

Write-Host "`nEnhanced upload process complete!" -ForegroundColor Green

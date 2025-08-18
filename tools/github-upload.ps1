# Enhanced GitHub Repository Uploader with Detailed Status
# Uploads local changes to GitHub for all repositories with better change detection

Write-Information "=== Enhanced GitHub Repository Uploader ==="
Write-Information "Checking and uploading local changes to github.com/wesellis"

$baseDir = "A:\GITHUB"
Set-Location -ErrorAction Stop $baseDir

# Add Git to PATH
$env:PATH += ";C:\Program Files\Git\bin"

# Focus on Azure-Automation-Scripts repository for detailed analysis
$repoPath = "A:\GITHUB\Azure-Automation-Scripts"
Write-Information "`n=== Detailed Analysis: Azure-Automation-Scripts ==="

if (Test-Path $repoPath) {
    Set-Location -ErrorAction Stop $repoPath
    
    Write-Information "Current directory: $((Get-Location).Path)"
    
    # Check if this is a Git repository
    if (Test-Path ".git") {
        Write-Information "✓ Git repository detected"
        
        # Get detailed Git status
        Write-Information "`nChecking Git status..."
        $gitStatus = git status --porcelain 2>$null
        
        if ([string]::IsNullOrWhiteSpace($gitStatus)) {
            Write-Information "Git status shows no changes"
            
            # Check for untracked files specifically
            Write-Information "`nChecking for untracked files..."
            $untrackedFiles = git ls-files --others --exclude-standard 2>$null
            
            if (![string]::IsNullOrWhiteSpace($untrackedFiles)) {
                Write-Information "Found untracked files:"
                $untrackedFiles -split "`n" | ForEach-Object { 
                    if (![string]::IsNullOrWhiteSpace($_)) {
                        Write-Information "  $_"
                    }
                }
                
                # Add and commit untracked files
                Write-Information "`nAdding untracked files..."
                git add . 2>$null
                
                $newStatus = git status --porcelain 2>$null
                if (![string]::IsNullOrWhiteSpace($newStatus)) {
                    Write-Information "Files staged for commit:"
                    $newStatus -split "`n" | ForEach-Object { 
                        if (![string]::IsNullOrWhiteSpace($_)) {
                            Write-Information "  $_"
                        }
                    }
                    
                    # Commit the changes
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $commitMessage = "Enhanced Azure Automation Scripts - Added enterprise features - $timestamp"
                    
                    Write-Information "`nCommitting changes..."
                    git commit -m $commitMessage 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Information "✓ Changes committed successfully"
                        
                        # Push to GitHub
                        Write-Information "`nPushing to GitHub..."
                        git push 2>$null
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Information "✓ Successfully pushed to GitHub!"
                        } else {
                            Write-Information "✗ Failed to push to GitHub"
                            Write-Information "You may need to authenticate with GitHub"
                        }
                    } else {
                        Write-Information "✗ Failed to commit changes"
                    }
                } else {
                    Write-Information "No changes after adding files"
                }
            } else {
                Write-Information "No untracked files found"
            }
        } else {
            Write-Information "Found changes to commit:"
            $gitStatus -split "`n" | ForEach-Object { 
                if (![string]::IsNullOrWhiteSpace($_)) {
                    Write-Information "  $_"
                }
            }
            
            # Commit and push existing changes
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            git add . 2>$null
            git commit -m "Updated Azure Automation Scripts - $timestamp" 2>$null
            git push 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Information "✓ Changes uploaded successfully!"
            } else {
                Write-Information "✗ Failed to upload changes"
            }
        }
        
        # Show recent commits
        Write-Information "`nRecent commits:"
        git log --oneline -5 2>$null | ForEach-Object { Write-Information "  $_" }
        
        # Show branch info
        Write-Information "`nBranch information:"
        $currentBranch = git branch --show-current 2>$null
        Write-Information "  Current branch: $currentBranch"
        
        $remoteUrl = git remote get-url -ErrorAction Stop origin 2>$null
        Write-Information "  Remote URL: $remoteUrl"
        
    } else {
        Write-Information "✗ Not a Git repository"
        Write-Information "Initialize Git repository? (y/n):"
        $response = Read-Host
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            git init 2>$null
            git remote add origin "https://github.com/wesellis/Azure-Automation-Scripts.git" 2>$null
            git add . 2>$null
            git commit -m "Initial commit with enhanced Azure automation scripts" 2>$null
            git branch -M main 2>$null
            git push -u origin main 2>$null
            
            Write-Information "✓ Repository initialized and pushed to GitHub"
        }
    }
} else {
    Write-Information "✗ Repository path not found: $repoPath"
}

Write-Information "`n=== Quick Check: All Repositories ==="

# Quick check of all repositories
$repositories = Get-ChildItem -ErrorAction Stop $baseDir -Directory | Where-Object { 
    $_.Name -notlike ".*" 
} | Select-Object -ExpandProperty Name

$summary = @{
    HasChanges = 0
    NoChanges = 0
    NotGitRepo = 0
}

foreach ($repo in $repositories) {
    $repoPath = Join-Path $baseDir $repo
    Set-Location -ErrorAction Stop $repoPath
    
    if (Test-Path ".git") {
        $status = git status --porcelain 2>$null
        $untracked = git ls-files --others --exclude-standard 2>$null
        
        if (![string]::IsNullOrWhiteSpace($status) -or ![string]::IsNullOrWhiteSpace($untracked)) {
            Write-Information "$repo - Has changes or untracked files"
            $summary.HasChanges++
        } else {
            Write-Information "$repo - No changes"
            $summary.NoChanges++
        }
    } else {
        Write-Information "$repo - Not a Git repository"
        $summary.NotGitRepo++
    }
}

Write-Information "`n=== SUMMARY ==="
Write-Information "Repositories with changes: $($summary.HasChanges)"
Write-Information "Repositories with no changes: $($summary.NoChanges)"
Write-Information "Not Git repositories: $($summary.NotGitRepo)"
Write-Information "Total repositories: $($repositories.Count)"

Write-Information "`nEnhanced upload process complete!"

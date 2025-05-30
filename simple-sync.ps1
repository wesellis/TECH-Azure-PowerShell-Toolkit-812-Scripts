# Simple GitHub Sync - Run from anywhere
# Basic sync script that handles the Azure Enterprise Toolkit

Write-Host "[SYNC] Azure Enterprise Toolkit Sync" -ForegroundColor Green

$repoPath = "A:\GITHUB\Azure-Enterprise-Toolkit"

# Navigate to the repository
if (!(Test-Path $repoPath)) {
    Write-Host "[ERROR] Repository not found: $repoPath" -ForegroundColor Red
    exit 1
}

Set-Location $repoPath
Write-Host "Working in: $repoPath" -ForegroundColor Cyan

# Check if it's a Git repository
if (!(Test-Path ".git")) {
    Write-Host "[ERROR] Not a Git repository" -ForegroundColor Red
    exit 1
}

# Check for changes
Write-Host "`n[CHECK] Checking for changes..." -ForegroundColor Cyan
$changes = git status --porcelain 2>$null

if (![string]::IsNullOrWhiteSpace($changes)) {
    Write-Host "[CHANGES] Found local changes - committing and pushing" -ForegroundColor Green
    
    # Show what's changed
    Write-Host "`nChanges found:" -ForegroundColor Yellow
    $changes -split "`n" | ForEach-Object { 
        if (![string]::IsNullOrWhiteSpace($_)) {
            Write-Host "  $_" -ForegroundColor White
        }
    }
    
    # Add, commit, and push
    git add .
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fileCount = ($changes -split "`n" | Where-Object { ![string]::IsNullOrWhiteSpace($_) }).Count
    $commitMessage = "Azure Enterprise Toolkit Update - $fileCount files - $timestamp"
    
    Write-Host "`n[COMMIT] $commitMessage" -ForegroundColor Cyan
    git commit -m $commitMessage
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PUSH] Pushing to GitHub..." -ForegroundColor Cyan
        git push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Successfully synced to GitHub!" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Push failed - you may need to authenticate" -ForegroundColor Red
            Write-Host "[TIP] Try running: git push" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[ERROR] Commit failed" -ForegroundColor Red
    }
} else {
    Write-Host "[CHECK] Checking if remote has newer changes..." -ForegroundColor Cyan
    git fetch origin 2>$null
    
    $status = git status -uno 2>$null
    $behind = $status | Select-String "behind"
    
    if ($behind) {
        Write-Host "[PULL] Remote has newer changes - pulling..." -ForegroundColor Blue
        git pull origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Successfully pulled latest changes!" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Pull failed" -ForegroundColor Red
        }
    } else {
        Write-Host "[OK] Everything is up to date!" -ForegroundColor Green
    }
}

# Show final status
Write-Host "`n[STATUS] Final repository status:" -ForegroundColor Green
$finalStatus = git status -s 2>$null
if ([string]::IsNullOrWhiteSpace($finalStatus)) {
    Write-Host "  Clean working directory - all synced!" -ForegroundColor Green
} else {
    Write-Host "  Still has changes:" -ForegroundColor Yellow
    $finalStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
}

Write-Host "`n[COMPLETE] Sync operation finished!" -ForegroundColor Green
Write-Host "[GITHUB] https://github.com/wesellis/Azure-Enterprise-Toolkit" -ForegroundColor Blue

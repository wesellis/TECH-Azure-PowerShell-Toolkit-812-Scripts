# Azure Enterprise Toolkit - GitHub Sync
# Professional sync script without Unicode characters
param(
    [string]$RepositoryPath = "A:\GITHUB\Azure-Enterprise-Toolkit",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

Write-Host "AZURE ENTERPRISE TOOLKIT - GITHUB SYNC" -ForegroundColor Green
Write-Host "Repository: $RepositoryPath" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Ensure we're in the right directory
if (!(Test-Path $RepositoryPath)) {
    Write-Host "ERROR: Repository path not found: $RepositoryPath" -ForegroundColor Red
    exit 1
}

Set-Location $RepositoryPath

# Verify it's a Git repository
if (!(Test-Path ".git")) {
    Write-Host "ERROR: Not a Git repository. Run 'git init' first." -ForegroundColor Red
    exit 1
}

function Write-VerboseOutput {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "  VERBOSE: $Message" -ForegroundColor Gray
    }
}

# Step 1: Fetch latest from remote
Write-Host "`nFETCHING: Getting latest information from GitHub..." -ForegroundColor Cyan
Write-VerboseOutput "Running: git fetch origin"

if (!$DryRun) {
    git fetch origin 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Could not fetch from remote. Proceeding with local state." -ForegroundColor Yellow
    }
}

# Step 2: Check for local changes
Write-Host "`nANALYZING: Checking for changes..." -ForegroundColor Cyan

# Check for local changes
$localChanges = git status --porcelain 2>$null
$hasLocalChanges = ![string]::IsNullOrWhiteSpace($localChanges)

# Check if we're ahead/behind remote
$statusOutput = git status -uno 2>$null
$isAhead = $statusOutput | Select-String "ahead"
$isBehind = $statusOutput | Select-String "behind"

Write-Host "`nSync Analysis:" -ForegroundColor Yellow
Write-Host "  Local changes: $(if($hasLocalChanges) { 'YES' } else { 'NO' })" -ForegroundColor $(if($hasLocalChanges) { 'Green' } else { 'Gray' })
Write-Host "  Ahead of remote: $(if($isAhead) { 'YES' } else { 'NO' })" -ForegroundColor $(if($isAhead) { 'Green' } else { 'Gray' })
Write-Host "  Behind remote: $(if($isBehind) { 'YES' } else { 'NO' })" -ForegroundColor $(if($isBehind) { 'Yellow' } else { 'Gray' })

# Step 3: Smart sync decision
if ($hasLocalChanges) {
    Write-Host "`nUPLOADING: Local changes detected - pushing to GitHub" -ForegroundColor Green
    
    if ($localChanges -and $Verbose) {
        Write-Host "`nChanged files:" -ForegroundColor Yellow
        $localChanges -split "`n" | ForEach-Object { 
            if (![string]::IsNullOrWhiteSpace($_)) {
                Write-Host "  $_" -ForegroundColor White
            }
        }
    }
    
    if (!$DryRun) {
        # Add all changes
        Write-VerboseOutput "Adding all changes to staging"
        git add .
        
        # Create commit message
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $fileCount = ($localChanges -split "`n" | Where-Object { ![string]::IsNullOrWhiteSpace($_) }).Count
        $commitMessage = "Azure Enterprise Toolkit Update - $fileCount files updated - $timestamp"
        
        Write-Host "  Committing: $commitMessage" -ForegroundColor Cyan
        git commit -m $commitMessage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  SUCCESS: Changes committed" -ForegroundColor Green
            
            # Push to GitHub
            Write-Host "  PUSHING: Uploading to GitHub..." -ForegroundColor Cyan
            git push
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  SUCCESS: Pushed to GitHub!" -ForegroundColor Green
            } else {
                Write-Host "  ERROR: Failed to push to GitHub" -ForegroundColor Red
                Write-Host "  TIP: You may need to authenticate with: git push" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ERROR: Failed to commit changes" -ForegroundColor Red
        }
    } else {
        Write-Host "  DRY RUN: Would commit and push $fileCount files" -ForegroundColor Yellow
    }
    
} elseif ($isBehind) {
    Write-Host "`nDOWNLOADING: Remote is newer - pulling from GitHub" -ForegroundColor Blue
    
    if (!$DryRun) {
        Write-VerboseOutput "Pulling latest changes from remote"
        git pull origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  SUCCESS: Pulled latest changes!" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Failed to pull changes" -ForegroundColor Red
        }
    } else {
        Write-Host "  DRY RUN: Would pull latest changes from remote" -ForegroundColor Yellow
    }
    
} elseif ($isAhead) {
    Write-Host "`nUPLOADING: Local is ahead - pushing to GitHub" -ForegroundColor Green
    
    if (!$DryRun) {
        Write-VerboseOutput "Pushing local commits to remote"
        git push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  SUCCESS: Pushed to GitHub!" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Failed to push to GitHub" -ForegroundColor Red
        }
    } else {
        Write-Host "  DRY RUN: Would push local commits to remote" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "`nSUCCESS: Everything is in sync - no action needed" -ForegroundColor Green
}

# Step 4: Final status report
Write-Host "`nFINAL STATUS:" -ForegroundColor Green
Write-Host "Repository: $(Split-Path $RepositoryPath -Leaf)" -ForegroundColor Cyan

$finalStatus = git status -uno 2>$null | Where-Object { $_ -notlike "*nothing to commit*" -and $_ -notlike "*working tree clean*" }
if ($finalStatus) {
    $finalStatus | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
} else {
    Write-Host "  SUCCESS: Working tree clean, up to date with remote" -ForegroundColor Green
}

# Show GitHub URL
$remoteUrl = git remote get-url origin 2>$null
if ($remoteUrl) {
    $webUrl = $remoteUrl -replace "\.git$", "" -replace "git@github\.com:", "https://github.com/"
    Write-Host "`nGITHUB: $webUrl" -ForegroundColor Blue
}

Write-Host "`nCOMPLETE: Sync operation finished successfully" -ForegroundColor Green

# Fix Bookmarks Submodule Issue
# This script removes the bookmarks submodule reference and adds it as a regular directory

Write-Host "Fixing bookmarks submodule issue..." -ForegroundColor Green

# Change to repository root
Set-Location "A:\GITHUB\Azure-Enterprise-Toolkit"

try {
    # Remove the submodule from git index (this won't delete the files)
    Write-Host "Removing submodule reference from git index..." -ForegroundColor Yellow
    git rm --cached bookmarks
    
    # Add the bookmarks directory as regular files
    Write-Host "Adding bookmarks as regular directory..." -ForegroundColor Yellow
    git add bookmarks/
    
    # Commit the changes
    Write-Host "Committing changes..." -ForegroundColor Yellow
    git commit -m "Convert bookmarks from submodule to regular directory"
    
    Write-Host "Bookmarks submodule issue fixed successfully!" -ForegroundColor Green
    Write-Host "You can now push the changes: git push origin main" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You may need to run these commands manually:" -ForegroundColor Yellow
    Write-Host "  git rm --cached bookmarks" -ForegroundColor Gray
    Write-Host "  git add bookmarks/" -ForegroundColor Gray
    Write-Host "  git commit -m 'Convert bookmarks from submodule to regular directory'" -ForegroundColor Gray
}

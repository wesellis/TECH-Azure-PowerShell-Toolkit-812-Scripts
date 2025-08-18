# Fix Bookmarks Submodule Issue
# This script removes the bookmarks submodule reference and adds it as a regular directory

Write-Information "Fixing bookmarks submodule issue..."

# Change to repository root
Set-Location -ErrorAction Stop "A:\GITHUB\Azure-Enterprise-Toolkit"

try {
    # Remove the submodule from git index (this won't delete the files)
    Write-Information "Removing submodule reference from git index..."
    git rm --cached bookmarks
    
    # Add the bookmarks directory as regular files
    Write-Information "Adding bookmarks as regular directory..."
    git add bookmarks/
    
    # Commit the changes
    Write-Information "Committing changes..."
    git commit -m "Convert bookmarks from submodule to regular directory"
    
    Write-Information "Bookmarks submodule issue fixed successfully!"
    Write-Information "You can now push the changes: git push origin main"
    
} catch {
    Write-Information "Error occurred: $($_.Exception.Message)"
    Write-Information "You may need to run these commands manually:"
    Write-Information "  git rm --cached bookmarks"
    Write-Information "  git add bookmarks/"
    Write-Information "  git commit -m 'Convert bookmarks from submodule to regular directory'"
}

#Requires -Version 7.0
<#
.SYNOPSIS
    fix bookmarks submodule
.DESCRIPTION
    fix bookmarks submodule operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    fix bookmarks submodulecom)#>
# Fix Bookmarks Submodule Issue
# This script removes the bookmarks submodule reference and adds it as a regular directory

Write-Host "Fixing bookmarks submodule issue..."

# Change to repository root
Set-Location -ErrorAction Stop "A:\GITHUB\Azure-Enterprise-Toolkit"

try {
    # Remove the submodule from git index (this won't delete the files)
    Write-Host "Removing submodule reference from git index..."
    git rm --cached bookmarks
    
    # Add the bookmarks directory as regular files
    Write-Host "Adding bookmarks as regular directory..."
    git add bookmarks/
    
    # Commit the changes
    Write-Host "Committing changes..."
    git commit -m "Convert bookmarks from submodule to regular directory"
    
    Write-Host "Bookmarks submodule issue fixed successfully!"
    Write-Host "You can now push the changes: git push origin main"
    
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)"
    Write-Host "You may need to run these commands manually:"
    Write-Host "  git rm --cached bookmarks"
    Write-Host "  git add bookmarks/"
    Write-Host "  git commit -m 'Convert bookmarks from submodule to regular directory'"
}

#endregion\n
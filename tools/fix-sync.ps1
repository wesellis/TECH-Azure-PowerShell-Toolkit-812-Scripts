#Requires -Version 7.0

    fix synccom)#>
# Fix GitHub sync issue
Write-Host "Fixing GitHub sync..."

# Pull the remote changes first
git pull origin main --allow-unrelated-histories
Write-Host "Pulled remote changes"

# Push our local changes
git push -u origin main
Write-Host "Repository fully synchronized!"

#endregion


# Fix GitHub sync issue
Write-Information "Fixing GitHub sync..."

# Pull the remote changes first
git pull origin main --allow-unrelated-histories
Write-Information "Pulled remote changes"

# Push our local changes
git push -u origin main
Write-Information "Repository fully synchronized!"

# Fix GitHub sync issue
Write-Host "Fixing GitHub sync..." -ForegroundColor Yellow

# Pull the remote changes first
git pull origin main --allow-unrelated-histories
Write-Host "Pulled remote changes" -ForegroundColor Green

# Push our local changes
git push -u origin main
Write-Host "Repository fully synchronized!" -ForegroundColor Green

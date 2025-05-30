# Azure Enterprise Toolkit - Simple Sync Launcher
# Clean version without Unicode characters

Write-Host "AZURE ENTERPRISE TOOLKIT - SYNC LAUNCHER" -ForegroundColor Green

$currentRepo = (Get-Location).Path
Write-Host "Working in: $currentRepo" -ForegroundColor Cyan

# Check if clean-sync.ps1 exists in current directory
if (Test-Path ".\clean-sync.ps1") {
    Write-Host "STATUS: Using local clean-sync.ps1" -ForegroundColor Green
    & ".\clean-sync.ps1" -RepositoryPath $currentRepo -Verbose
} elseif (Test-Path "..\smart-sync.ps1") {
    Write-Host "STATUS: Using parent directory smart-sync.ps1" -ForegroundColor Yellow
    & "..\smart-sync.ps1" -RepositoryPath $currentRepo -Verbose
} else {
    Write-Host "ERROR: No sync script found" -ForegroundColor Red
    Write-Host "TIP: Make sure clean-sync.ps1 exists in current directory" -ForegroundColor Yellow
}

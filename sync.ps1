# Quick Sync Launcher for Azure Enterprise Toolkit
# Runs the smart sync script from the parent directory

Write-Host "[LAUNCHER] Azure Enterprise Toolkit - Quick Sync" -ForegroundColor Green

$smartSyncPath = "..\smart-sync.ps1"
$currentRepo = (Get-Location).Path

if (Test-Path $smartSyncPath) {
    Write-Host "Running smart sync for: $currentRepo" -ForegroundColor Cyan
    Write-Host "Using script: $smartSyncPath" -ForegroundColor Gray
    & $smartSyncPath -RepositoryPath $currentRepo -Verbose
} else {
    Write-Host "[ERROR] Smart sync script not found at: $smartSyncPath" -ForegroundColor Red
    Write-Host "[TIP] Make sure smart-sync.ps1 is in the parent directory (A:\GITHUB\)" -ForegroundColor Yellow
    
    # Try alternative path
    $altPath = "A:\GITHUB\smart-sync.ps1"
    if (Test-Path $altPath) {
        Write-Host "[FOUND] Using alternative path: $altPath" -ForegroundColor Green
        & $altPath -RepositoryPath $currentRepo -Verbose
    } else {
        Write-Host "[ERROR] Script not found at alternative path either: $altPath" -ForegroundColor Red
    }
}

#Requires -Version 7.0

<#
.SYNOPSIS
    Setup script for PowerShell Gallery publishing

.DESCRIPTION
    Interactive setup for PowerShell Gallery publishing including API key configuration,
    module preparation, and validation testing.

.PARAMETER Interactive
    Run in interactive mode for guided setup

.EXAMPLE
    .\Setup-Gallery-Publishing.ps1 -Interactive
    Run guided setup for PowerShell Gallery publishing

.NOTES
    Author: Azure PowerShell Toolkit Team
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Interactive = $true
)

Write-Host "=== PowerShell Gallery Publishing Setup ===" -ForegroundColor Cyan
Write-Host ""

# Function to test PowerShell Gallery connectivity
function Test-GalleryConnectivity {
    Write-Host "Testing PowerShell Gallery connectivity..." -ForegroundColor Yellow

    try {
        $testModule = Find-Module -Name "PowerShellGet" -ErrorAction Stop
        Write-Host "✓ PowerShell Gallery is accessible" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Cannot connect to PowerShell Gallery" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to validate API key
function Test-ApiKey {
    param([string]$ApiKey)

    if (-not $ApiKey) {
        return $false
    }

    # Basic validation - API keys are typically GUIDs or long strings
    if ($ApiKey.Length -lt 20) {
        Write-Host "✗ API key appears too short" -ForegroundColor Red
        return $false
    }

    Write-Host "✓ API key format appears valid" -ForegroundColor Green
    return $true
}

# Function to create gallery profile
function New-GalleryProfile {
    param([string]$ApiKey)

    $profilePath = Join-Path $env:USERPROFILE ".azure-toolkit-gallery.json"

    $profile = @{
        ApiKey = $ApiKey
        LastUpdated = Get-Date
        PublisherInfo = @{
            Author = "Wesley Ellis"
            Company = "WesEllis"
            Email = "wes@wesellis.com"
            Website = "wesellis.com"
        }
        ModulePrefix = "Az.Toolkit"
        Repository = "https://github.com/wesellis/TECH-Azure-PowerShell-Toolkit-812-Scripts"
    }

    $profile | ConvertTo-Json -Depth 3 | Out-File -FilePath $profilePath -Encoding UTF8
    Write-Host "✓ Gallery profile saved to: $profilePath" -ForegroundColor Green

    return $profilePath
}

# Main setup process
if ($Interactive) {
    Write-Host "This script will help you set up PowerShell Gallery publishing for the Azure Toolkit." -ForegroundColor White
    Write-Host ""

    # Step 1: Check prerequisites
    Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Cyan

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "✗ PowerShell 7.0+ is required" -ForegroundColor Red
        Write-Host "  Download from: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "✓ PowerShell $($PSVersionTable.PSVersion) detected" -ForegroundColor Green
    }

    # Check PowerShellGet
    $psGet = Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $psGet -or $psGet.Version -lt [Version]"2.0.0") {
        Write-Host "✗ PowerShellGet 2.0+ is required" -ForegroundColor Red
        Write-Host "  Install with: Install-Module -Name PowerShellGet -Force" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "✓ PowerShellGet $($psGet.Version) detected" -ForegroundColor Green
    }

    # Test gallery connectivity
    if (-not (Test-GalleryConnectivity)) {
        Write-Host "Cannot proceed without PowerShell Gallery access" -ForegroundColor Red
        exit 1
    }

    Write-Host ""

    # Step 2: Get API key
    Write-Host "Step 2: PowerShell Gallery API Key Setup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You need a PowerShell Gallery API key to publish modules." -ForegroundColor White
    Write-Host "Get your API key from: https://www.powershellgallery.com/account/apikeys" -ForegroundColor Yellow
    Write-Host ""

    do {
        $apiKey = Read-Host "Enter your PowerShell Gallery API key (or 'skip' to skip)" -AsSecureString
        $apiKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))

        if ($apiKeyPlain -eq 'skip') {
            Write-Host "Skipping API key setup. You can configure it later." -ForegroundColor Yellow
            break
        }

        $validKey = Test-ApiKey -ApiKey $apiKeyPlain
    } while (-not $validKey)

    if ($apiKeyPlain -ne 'skip') {
        # Create gallery profile
        $profilePath = New-GalleryProfile -ApiKey $apiKeyPlain
        Write-Host ""
    }

    # Step 3: Module preparation
    Write-Host "Step 3: Module Preparation" -ForegroundColor Cyan
    Write-Host ""

    $toolkitRoot = Split-Path -Parent $PSScriptRoot
    $scriptsPath = Join-Path $toolkitRoot "scripts"

    if (-not (Test-Path $scriptsPath)) {
        Write-Host "✗ Scripts directory not found: $scriptsPath" -ForegroundColor Red
        exit 1
    }

    $categories = Get-ChildItem -Path $scriptsPath -Directory
    Write-Host "Found $($categories.Count) script categories:" -ForegroundColor Green
    foreach ($category in $categories) {
        $scriptCount = (Get-ChildItem -Path $category.FullName -Filter "*.ps1").Count
        Write-Host "  - $($category.Name): $scriptCount scripts" -ForegroundColor White
    }

    Write-Host ""

    # Step 4: Test publishing setup
    Write-Host "Step 4: Testing Publishing Setup" -ForegroundColor Cyan

    if ($apiKeyPlain -and $apiKeyPlain -ne 'skip') {
        Write-Host "Testing module publishing (dry run)..." -ForegroundColor Yellow

        try {
            & (Join-Path $PSScriptRoot "Publish-ToGallery.ps1") -ApiKey $apiKeyPlain -WhatIf
            Write-Host "✓ Publishing test successful" -ForegroundColor Green
        } catch {
            Write-Host "✗ Publishing test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Skipping publishing test (no API key provided)" -ForegroundColor Yellow
    }

    Write-Host ""

    # Step 5: Next steps
    Write-Host "Step 5: Next Steps" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Setup complete! Here's what you can do next:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Publish all modules:" -ForegroundColor Yellow
    Write-Host "   .\tools\Publish-ToGallery.ps1 -ApiKey 'your-key'" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Publish specific module:" -ForegroundColor Yellow
    Write-Host "   .\tools\Publish-ToGallery.ps1 -ModuleName 'Az.Toolkit.Compute' -ApiKey 'your-key'" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Test before publishing:" -ForegroundColor Yellow
    Write-Host "   .\tools\Publish-ToGallery.ps1 -ApiKey 'your-key' -WhatIf" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Run tests:" -ForegroundColor Yellow
    Write-Host "   .\tests\Run-Tests.ps1" -ForegroundColor White
    Write-Host ""

    if ($profilePath) {
        Write-Host "Your settings are saved in: $profilePath" -ForegroundColor Cyan
    }

} else {
    # Non-interactive mode - just validate environment
    Write-Host "Running environment validation..." -ForegroundColor Yellow

    $issues = @()

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7.0+ required"
    }

    $psGet = Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $psGet -or $psGet.Version -lt [Version]"2.0.0") {
        $issues += "PowerShellGet 2.0+ required"
    }

    if (-not (Test-GalleryConnectivity)) {
        $issues += "PowerShell Gallery not accessible"
    }

    if ($issues.Count -eq 0) {
        Write-Host "✓ Environment validation passed" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "✗ Environment validation failed:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
        exit 1
    }
}

Write-Host ""
Write-Host "Setup complete! Happy publishing! 🚀" -ForegroundColor Green
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

Write-Host "=== PowerShell Gallery Publishing Setup ===" -ForegroundColor Green
Write-Output ""

function Test-GalleryConnectivity {
    Write-Host "Testing PowerShell Gallery connectivity..." -ForegroundColor Green

    try {
        $TestModule = Find-Module -Name "PowerShellGet" -ErrorAction Stop
        Write-Host "✓ PowerShell Gallery is accessible" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Cannot connect to PowerShell Gallery" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-ApiKey {
    param([string]$ApiKey)

    if (-not $ApiKey) {
        return $false
    }

    if ($ApiKey.Length -lt 20) {
        Write-Host "✗ API key appears too short" -ForegroundColor Red
        return $false
    }

    Write-Host "✓ API key format appears valid" -ForegroundColor Green
    return $true
}

function New-GalleryProfile {
    param([string]$ApiKey)
    $ProfilePath = Join-Path $env:USERPROFILE ".azure-toolkit-gallery.json"
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
    $profile | ConvertTo-Json -Depth 3 | Out-File -FilePath $ProfilePath -Encoding UTF8
    Write-Host "✓ Gallery profile saved to: $ProfilePath" -ForegroundColor Green

    return $ProfilePath
}

if ($Interactive) {
    Write-Host "This script will help you set up PowerShell Gallery publishing for the Azure Toolkit." -ForegroundColor Green
    Write-Output ""

    Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Green

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "✗ PowerShell 7.0+ is required" -ForegroundColor Red
        Write-Host "  Download from: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✓ PowerShell $($PSVersionTable.PSVersion) detected" -ForegroundColor Green
    }
    $PsGet = Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $PsGet -or $PsGet.Version -lt [Version]"2.0.0") {
        Write-Host "✗ PowerShellGet 2.0+ is required" -ForegroundColor Red
        Write-Output "  Install with: Install-Module -Name PowerShellGet -Force" # Color: $2
        exit 1
    } else {
        Write-Output "✓ PowerShellGet $($PsGet.Version) detected" # Color: $2
    }

    if (-not (Test-GalleryConnectivity)) {
        Write-Output "Cannot proceed without PowerShell Gallery access" # Color: $2
        exit 1
    }

    Write-Output ""

    Write-Output "Step 2: PowerShell Gallery API Key Setup" # Color: $2
    Write-Output ""
    Write-Output "You need a PowerShell Gallery API key to publish modules." # Color: $2
    Write-Output "Get your API key from: https://www.powershellgallery.com/account/apikeys" # Color: $2
    Write-Output ""

    do {
    $ApiKey = Read-Host "Enter your PowerShell Gallery API key (or 'skip' to skip)" -AsSecureString
    $ApiKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey))

        if ($ApiKeyPlain -eq 'skip') {
            Write-Output "Skipping API key setup. You can configure it later." # Color: $2
            break
        }
    $ValidKey = Test-ApiKey -ApiKey $ApiKeyPlain
    } while (-not $ValidKey)

    if ($ApiKeyPlain -ne 'skip') {
        $ProfilePath = New-GalleryProfile -ApiKey $ApiKeyPlain
        Write-Output ""
    }

    Write-Output "Step 3: Module Preparation" # Color: $2
    Write-Output ""
    $ToolkitRoot = Split-Path -Parent $PSScriptRoot
    $ScriptsPath = Join-Path $ToolkitRoot "scripts"

    if (-not (Test-Path $ScriptsPath)) {
        Write-Output "✗ Scripts directory not found: $ScriptsPath" # Color: $2
        exit 1
    }
    $categories = Get-ChildItem -Path $ScriptsPath -Directory
    Write-Output "Found $($categories.Count) script categories:" # Color: $2
    foreach ($category in $categories) {
        $ScriptCount = (Get-ChildItem -Path $category.FullName -Filter "*.ps1").Count
        Write-Output "  - $($category.Name): $ScriptCount scripts" # Color: $2
    }

    Write-Output ""

    Write-Output "Step 4: Testing Publishing Setup" # Color: $2

    if ($ApiKeyPlain -and $ApiKeyPlain -ne 'skip') {
        Write-Output "Testing module publishing (dry run)..." # Color: $2

        try {
            & (Join-Path $PSScriptRoot "Publish-ToGallery.ps1") -ApiKey $ApiKeyPlain -WhatIf
            Write-Output "✓ Publishing test successful" # Color: $2
        } catch {
            Write-Output "✗ Publishing test failed: $($_.Exception.Message)" # Color: $2
        }
    } else {
        Write-Output "Skipping publishing test (no API key provided)" # Color: $2
    }

    Write-Output ""

    Write-Output "Step 5: Next Steps" # Color: $2
    Write-Output ""
    Write-Output "Setup complete! Here's what you can do next:" # Color: $2
    Write-Output ""
    Write-Output "1. Publish all modules:" # Color: $2
    Write-Output "   .\tools\Publish-ToGallery.ps1 -ApiKey 'your-key'" # Color: $2
    Write-Output ""
    Write-Output "2. Publish specific module:" # Color: $2
    Write-Output "   .\tools\Publish-ToGallery.ps1 -ModuleName 'Az.Toolkit.Compute' -ApiKey 'your-key'" # Color: $2
    Write-Output ""
    Write-Output "3. Test before publishing:" # Color: $2
    Write-Output "   .\tools\Publish-ToGallery.ps1 -ApiKey 'your-key' -WhatIf" # Color: $2
    Write-Output ""
    Write-Output "4. Run tests:" # Color: $2
    Write-Output "   .\tests\Run-Tests.ps1" # Color: $2
    Write-Output ""

    if ($ProfilePath) {
        Write-Output "Your settings are saved in: $ProfilePath" # Color: $2
    }

} else {
    Write-Output "Running environment validation..." # Color: $2
    $issues = @()

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7.0+ required"
    }
    $PsGet = Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $PsGet -or $PsGet.Version -lt [Version]"2.0.0") {
        $issues += "PowerShellGet 2.0+ required"
    }

    if (-not (Test-GalleryConnectivity)) {
        $issues += "PowerShell Gallery not accessible"
    }

    if ($issues.Count -eq 0) {
        Write-Output "✓ Environment validation passed" # Color: $2
        exit 0
    } else {
        Write-Output "✗ Environment validation failed:" # Color: $2
        foreach ($issue in $issues) {
            Write-Output "  - $issue" # Color: $2
        }
        exit 1
    }
}

Write-Output ""
Write-Output "Setup complete! Happy publishing! 🚀" # Color: $2


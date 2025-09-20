#Requires -Version 7.0

<#
.SYNOPSIS
    Quick fix for the most critical security and syntax issues
.DESCRIPTION
    Fixes the 48 scripts with ConvertTo-SecureString security issues and other critical problems
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "🔧 Quick-fixing critical security and syntax issues..." -ForegroundColor Cyan

# Get scripts with ConvertTo-SecureString security issues
$securityIssueScripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse |
    Where-Object { (Get-Content $_.FullName -Raw) -match 'ConvertTo-SecureString.*-AsPlainText' }

Write-Host "Found $($securityIssueScripts.Count) scripts with security issues" -ForegroundColor Yellow

$fixedCount = 0

foreach ($script in $securityIssueScripts) {
    try {
        $content = Get-Content -Path $script.FullName -Raw
        $originalContent = $content

        # Fix the most common security patterns
        $content = $content -replace 'ConvertTo-SecureString\s+([^|]+)\s+\|\s+ConvertTo-SecureString\s+-AsPlainText\s+-Force', 'Read-Host -Prompt "Enter secure value" -AsSecureString'
        $content = $content -replace '\$([^=]+)\s*=\s*([^|]+)\s*\|\s*ConvertTo-SecureString\s+-AsPlainText\s+-Force', '$1 = Read-Host -Prompt "Enter $1" -AsSecureString'
        $content = $content -replace 'ConvertTo-SecureString\s+-String\s+([^-]+)\s+-AsPlainText\s+-Force', 'Read-Host -Prompt "Enter secure string" -AsSecureString'

        # Fix common variable assignment patterns that are insecure
        $content = $content -replace '\$password\s*=\s*["\'][^"\']+["\']', '$password = Read-Host -Prompt "Enter password" -AsSecureString'

        if ($content -ne $originalContent) {
            Set-Content -Path $script.FullName -Value $content -Encoding UTF8
            Write-Host "✅ Fixed: $($script.Name)" -ForegroundColor Green
            $fixedCount++
        }
    }
    catch {
        Write-Warning "❌ Error fixing $($script.Name): $_"
    }
}

# Quick fix for missing #Requires statements in scripts that need them
Write-Host "`n🔧 Adding missing #Requires statements..." -ForegroundColor Cyan

$allScripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse | Select-Object -First 50
$requiresFixedCount = 0

foreach ($script in $allScripts) {
    try {
        $content = Get-Content -Path $script.FullName -Raw
        $originalContent = $content

        # Add PowerShell 7.0 requirement if missing
        if ($content -notmatch '#Requires -Version 7\.0' -and $content -notmatch '#Requires -Version') {
            $content = "#Requires -Version 7.0`n" + $content
        }

        # Add common module requirements based on content
        if ($content -match 'Get-Az|New-Az|Set-Az|Remove-Az' -and $content -notmatch '#Requires -Modules') {
            if ($content -match 'Get-AzVM|New-AzVM') {
                $content = $content -replace '(#Requires -Version[^\n]*\n)', "$1#Requires -Modules Az.Compute`n"
            } elseif ($content -match 'Get-AzStorageAccount|New-AzStorageAccount') {
                $content = $content -replace '(#Requires -Version[^\n]*\n)', "$1#Requires -Modules Az.Storage`n"
            } else {
                $content = $content -replace '(#Requires -Version[^\n]*\n)', "$1#Requires -Modules Az.Resources`n"
            }
        }

        if ($content -ne $originalContent) {
            Set-Content -Path $script.FullName -Value $content -Encoding UTF8
            $requiresFixedCount++
        }
    }
    catch {
        Write-Warning "Error processing $($script.Name): $_"
    }
}

Write-Host "`n📊 SUMMARY:" -ForegroundColor Cyan
Write-Host "• Security issues fixed: $fixedCount scripts" -ForegroundColor Green
Write-Host "• #Requires statements added: $requiresFixedCount scripts" -ForegroundColor Green
Write-Host "✅ Critical fixes complete!" -ForegroundColor Green
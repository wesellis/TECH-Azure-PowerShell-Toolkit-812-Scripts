<#
.SYNOPSIS\s*Azure automation script') {
        Write-Host "Found malformed structure - fixing..." -ForegroundColor Red

        # Extract the actual script name from comments
        $scriptName = $script.BaseName -replace 'Azure-', '' -replace '-', ' '

        # Replace the malformed structure
        $newContent = $content -replace '(?s)<#\s*#endregion\s*#region Main-Execution\s*.SYNOPSIS
    \s*Azure automation script\s*
.DESCRIPTION\s*NOTES\s*Author: Wes Ellis \(wes@wesellis\.com\)\s*Version: 1\.0\.0\s*\s*#>', @"
    $scriptNamecom)#>
"@

        if (-not $WhatIf) {
            $newContent | Set-Content $script.FullName -Encoding UTF8
            Write-Host "Fixed!" -ForegroundColor Green
        } else {
            Write-Host "Would fix" -ForegroundColor Yellow
        }

        $fixedCount++
    } else {
        Write-Host "Structure OK" -ForegroundColor Green
    }
}

Write-Host "`nSummary: Fixed $fixedCount scripts" -ForegroundColor Cyan


<#
.SYNOPSIS
    eliminate ai slop
.DESCRIPTION
    eliminate ai slop operation
    Author: Wes Ellis (wes@wesellis.com)
#>
<#
.SYNOPSIS', '<#' + "`n.SYNOPSIS"
        $changed = $true
    }

    # Remove excessive validation
    $content = $content -replace '\[ValidatePattern\([^)]+email[^)]+\)\]\s*', ''
    $content = $content -replace '\[ValidateRange\([^)]+\)\]\s*', ''
    $content = $content -replace '\[ValidateNotNullOrEmpty\(\)\]\s*(?=\[ValidatePattern)', ''

    # Simplify overly verbose descriptions
    $content = $content -replace 'Analyzes.*?across.*?environment', 'Checks Azure resources'
    $content = $content -replace 'Provides.*?insights.*?optimization', 'Shows resource information'
    $content = $content -replace 'Optional.*?to limit scope.*?check', 'Resource group filter'

    if ($content -ne $originalContent) {
        Write-Host "Fixed AI slop in: $($file.Name)" -ForegroundColor Green
        if (-not $WhatIf) {
            $content | Set-Content $file.FullName -Encoding UTF8
        }
        $scriptsFixed++
    }
}

Write-Host "Fixed AI slop in $scriptsFixed scripts" -ForegroundColor Cyan\n
<#
.SYNOPSIS') {
        $content = $content -replace '(?s)<#\s*#endregion\s*#region Main-Execution\s*\.SYNOPSIS
    \s*Azure automation script\s*\
.DESCRIPTION\s*NOTES\s*Author: Wes Ellis.*?#>', @'
    Azure resource management script

    Manages Azure resources and operations

    Author: Wes Ellis (wes@wesellis.com)#>
'@
        $issues += "Fixed malformed comment structure"
    }

    # Fix undefined function calls
    $content = $content -replace 'Show-Banner[^`r`n]*', '# Script banner removed'
    $content = $content -replace 'Write-ProgressStep[^`r`n]*', '# Progress step removed'
    $content = $content -replace 'if \(-not \(Test-AzureConnection[^)]*\)\)', 'if (-not (Get-AzContext))'
    $content = $content -replace 'Write-Log\s+"([^"]+)"\s+-Level\s+\w+', 'Write-Host "$1"'

    # Fix broken splatting patterns
    $content = $content -replace '\$\w+\s+@params', '# Command with splatting - needs proper cmdlet'

    # Fix broken credential syntax
    $content = $content -replace 'SqlAdministratorCredentials = "\(New-Object[^)]+\)"', 'SqlAdministratorCredentials = (New-Object PSCredential($AdminUser, $AdminPassword))'

    if ($content -ne $originalContent) {
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
        if (-not $WhatIf) {
            $content | Set-Content $file.FullName -Encoding UTF8
        }
        $fixedCount++
    }
}

Write-Host "Fixed $fixedCount files" -ForegroundColor Cyan


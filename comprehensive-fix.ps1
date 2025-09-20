<#
.SYNOPSIS') {
        $content = $content -replace '<#\s*#endregion\s*#region\s+Main-Execution\s*\.SYNOPSIS', '<#' + "`n.SYNOPSIS"
    }

    # Fix the generic template descriptions that scream AI
    $content = $content -replace 'Azure automation script', 'PowerShell script'
    $content = $content -replace '*"GetInfo".*"ConfigureDomain".*"ManagePhoneNumbers"') {
        $content = $content -replace '\[ValidateSet\([^)]*\)\]', '[ValidateSet("Create", "Delete", "GetInfo")]'
    }

    # Remove excessive parameters that do nothing
    $lines = $content -split "`n"
    $filteredLines = @()
    $skipNext = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Skip overly complex parameter blocks
        if ($line -match '\[Parameter\(Mandatory=\$false\)\]' -and
            $lines[$i+1] -match '\[ValidateSet.*"TollFree"' -or
            $lines[$i+1] -match '\[string\]\$PhoneNumber') {
            # Skip this parameter and the next few lines
            while ($i -lt $lines.Count -and $lines[$i] -notmatch '^\s*\[Parameter' -and $lines[$i] -notmatch '^\s*\)') {
                $i++
            }
            $i-- # Back up one since the loop will increment
            continue
        }

        $filteredLines += $line
    }

    $content = $filteredLines -join "`n"

    # Remove try/catch blocks that just call undefined functions
    $content = $content -replace 'try \{\s*Write-Banner[^}]*\}', ''
    $content = $content -replace 'Show-Banner[^`r`n]*', ''
    $content = $content -replace 'Write-ProgressStep[^`r`n]*', 'Write-Host'

    # Fix broken function calls
    $content = $content -replace 'Test-AzureConnection', '(Get-AzContext)'

    # Remove excessive error handling that doesn't work
    $content = $content -replace 'catch \{\s*Write-Information[^}]*exit 1[^}]*\}', 'catch { throw }'

    # Simplify overly complex hashtable parameter passing
    $content = $content -replace '\$\w+Params = @\{[^}]*\}', ''

    if ($content -ne $originalContent) {
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Green

        if (-not $WhatIf) {
            $content | Set-Content $file.FullName -Encoding UTF8
        }
        $fixedCount++
    }
}

Write-Host "`nFix Complete:" -ForegroundColor Cyan
Write-Host "Files processed: $totalFiles" -ForegroundColor White
Write-Host "Files fixed: $fixedCount" -ForegroundColor Green


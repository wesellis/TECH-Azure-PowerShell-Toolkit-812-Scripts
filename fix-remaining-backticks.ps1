#Requires -Version 7.0

    Aggressively fixes remaining backticks and modernization issues in PowerShell scripts

    Enhanced modernization script that handles complex backtick scenarios,
    converts to splatting, and fixes remaining code quality issues.
.PARAMETER Path
    Root path to scan for PowerShell scripts
.PARAMETER Force
    Force changes even on complex scenarios

    Author: Wes Ellis (wes@wesellis.com)

    $Content = $Content -replace 'Enterprise PowerShell Framework', 'Wes Ellis (wes@wesellis.com)'

    return $Content
}

function Fix-ScriptFile {
    param([string]$FilePath)

    try {
        Write-Host "Processing: $FilePath" -ForegroundColor Cyan

        $content = Get-Content -Path $FilePath -Raw
        $originalContent = $content

        # Apply all fixes
        $content = Fix-BackticksAggressive -Content $content
        $content = Fix-SpecificPatterns -Content $content
        $content = Fix-WriteStatements -Content $content
        $content = Remove-AIAttributions -Content $content

        # Fix parameter defaults with subexpressions
        $content = $content -replace '(\$\w+\s*=\s*)"([^"]*)\$\(([^)]+)\)([^"]*)"', '$1$null # Dynamic default set in script body'

        # Fix Unicode if still present
        $unicodeReplacements = @{
            '' = '[OK]'
            '' = '[FAIL]'
            '' = '[WARN]'
            '' = '[OK]'
            '' = '[FAIL]'
            '' = '[!]'
            '' = '->'
            '' = '<-'
        }

        foreach ($char in $unicodeReplacements.Keys) {
            $content = $content -replace [regex]::Escape($char), $unicodeReplacements[$char]
        }

        # Save if changed
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Fix backticks and modernize")) {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Host "Fixed: $FilePath" -ForegroundColor Green
                return $true
            }
        }
        else {
            Write-Host "No changes needed" -ForegroundColor Yellow
            return $false

} catch {
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Main
Write-Host "`n=== Aggressive Backtick Fix ===" -ForegroundColor Cyan
Write-Host "Scanning for scripts with backticks...`n" -ForegroundColor Yellow

# Find all scripts with backticks
$scriptsWithBackticks = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse |
    Where-Object {
        $content = Get-Content $_.FullName -Raw
        $content -match '`\s*$'
    }

Write-Host "Found $($scriptsWithBackticks.Count) scripts with backticks" -ForegroundColor Yellow

$fixed = 0
$failed = 0

foreach ($script in $scriptsWithBackticks) {
    if (Fix-ScriptFile -FilePath $script.FullName) {
        $fixed++
    }
    else {
        $failed++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Scripts fixed: $fixed" -ForegroundColor Green
Write-Host "Scripts failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Total processed: $($scriptsWithBackticks.Count)" -ForegroundColor Yellow

if ($fixed -gt 0) {
    Write-Host "`nBackticks have been removed from $fixed scripts!" -ForegroundColor Green
}

#endregion


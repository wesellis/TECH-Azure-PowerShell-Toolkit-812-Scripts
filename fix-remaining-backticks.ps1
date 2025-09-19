#Requires -Version 7.0

<#
.SYNOPSIS
    Aggressively fixes remaining backticks and modernization issues in PowerShell scripts

.DESCRIPTION
    Enhanced modernization script that handles complex backtick scenarios,
    converts to splatting, and fixes remaining code quality issues.

.PARAMETER Path
    Root path to scan for PowerShell scripts

.PARAMETER Force
    Force changes even on complex scenarios

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0.0
    Created: 2025-09-19
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter()]
    [switch]$Force
)

#region Functions
function Fix-BackticksAggressive {
    param([string]$Content)

    $lines = $Content -split "`r?`n"
    $fixedLines = [System.Collections.ArrayList]::new()
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        # Check if line ends with backtick
        if ($line -match '^(\s*)(.*?)\s*`\s*$') {
            $indent = $Matches[1]
            $lineContent = $Matches[2]

            # Collect all continuation lines
            $continuationLines = [System.Collections.ArrayList]::new()
            [void]$continuationLines.Add($lineContent)
            $i++

            while ($i -lt $lines.Count) {
                if ($lines[$i] -match '^(\s*)(.*?)\s*`\s*$') {
                    # Another continuation line
                    [void]$continuationLines.Add($Matches[2].Trim())
                    $i++
                }
                elseif ($lines[$i] -match '^\s*(.+)$') {
                    # Last line of continuation
                    [void]$continuationLines.Add($Matches[1].Trim())
                    $i++
                    break
                }
                else {
                    # Empty line, stop here
                    break
                }
            }

            # Now convert to splatting or proper format
            $fullCommand = $continuationLines -join ' '

            # Check if it's a command with parameters
            if ($fullCommand -match '^(\S+)\s+(.+)$') {
                $command = $Matches[1]
                $paramString = $Matches[2]

                # Parse parameters
                $params = @{}
                $currentParam = $null
                $currentValue = ''

                # Split by parameter markers
                $tokens = $paramString -split '\s+(?=-)'

                foreach ($token in $tokens) {
                    $token = $token.Trim()
                    if ([string]::IsNullOrWhiteSpace($token)) { continue }

                    if ($token -match '^-(\w+)\s*(.*)$') {
                        # Save previous parameter if exists
                        if ($currentParam) {
                            $params[$currentParam] = $currentValue.Trim()
                        }

                        $currentParam = $Matches[1]
                        $currentValue = $Matches[2]
                    }
                    else {
                        # Part of current parameter value
                        $currentValue += " $token"
                    }
                }

                # Save last parameter
                if ($currentParam) {
                    $params[$currentParam] = $currentValue.Trim()
                }

                # Generate splatted version
                if ($params.Count -gt 2) {
                    [void]$fixedLines.Add("${indent}`$params = @{")
                    foreach ($key in $params.Keys) {
                        $value = $params[$key]
                        # Clean up the value
                        $value = $value -replace '^\$', '$'
                        $value = $value -replace '^"(.*)"$', '"$1"'
                        $value = $value -replace "^'(.*)'$", '''$1'''

                        if ([string]::IsNullOrWhiteSpace($value)) {
                            [void]$fixedLines.Add("${indent}    $key = `$true")
                        }
                        else {
                            [void]$fixedLines.Add("${indent}    $key = $value")
                        }
                    }
                    [void]$fixedLines.Add("${indent}}")
                    [void]$fixedLines.Add("${indent}$command @params")
                }
                else {
                    # For simple commands, use single line
                    [void]$fixedLines.Add("${indent}$fullCommand")
                }
            }
            else {
                # Not a command with parameters, just join
                [void]$fixedLines.Add("${indent}$fullCommand")
            }
        }
        else {
            # Regular line, keep as is
            [void]$fixedLines.Add($line)
            $i++
        }
    }

    return $fixedLines -join "`n"
}

function Fix-SpecificPatterns {
    param([string]$Content)

    # Fix Build-OMSSignature backticks
    $Content = $Content -replace 'Build-OMSSignature\s*`[\r\n\s]+-customerId\s+\$customerId\s*`[\r\n\s]+-sharedKey\s+\$sharedKey\s*`[\r\n\s]+-date\s+\$rfc1123date\s*`[\r\n\s]+-contentLength\s+\$contentLength\s*`[\r\n\s]+-fileName\s+\$fileName\s*`[\r\n\s]+-method\s+\$method\s*`[\r\n\s]+-contentType\s+\$contentType\s*`[\r\n\s]+-resource\s+\$resource',
        @'
$signatureParams = @{
    customerId = $customerId
    sharedKey = $sharedKey
    date = $rfc1123date
    contentLength = $contentLength
    fileName = $fileName
    method = $method
    contentType = $contentType
    resource = $resource
}
$signature = Build-OMSSignature @signatureParams
'@

    # Fix New-AzResource backticks
    $Content = $Content -replace 'New-AzResource\s*`[\r\n\s]+(.*?)`[\r\n\s]+(.*?)`[\r\n\s]+(.*?)[\r\n]',
        @'
$resourceParams = @{
    $1
    $2
    $3
}
New-AzResource @resourceParams
'@

    # Fix common Azure cmdlet patterns
    $azureCmdlets = @(
        'Get-AzResource',
        'Set-AzResource',
        'New-AzResourceGroup',
        'Remove-AzResource',
        'Get-AzVM',
        'New-AzVM',
        'Set-AzVM',
        'Get-AzStorageAccount',
        'New-AzStorageAccount'
    )

    foreach ($cmdlet in $azureCmdlets) {
        $pattern = "$cmdlet\s*``[\r\n\s]+(.*?)[\r\n]"
        if ($Content -match $pattern) {
            $Content = $Content -replace $pattern, "$cmdlet $1"
        }
    }

    return $Content
}

function Fix-WriteStatements {
    param([string]$Content)

    # Fix Write-Host/Output/Error with backticks
    $Content = $Content -replace 'Write-(Host|Output|Error|Warning|Verbose|Debug)\s*`[\r\n\s]+"([^"]+)"',
        'Write-$1 "$2"'

    # Fix Write-Log patterns
    $Content = $Content -replace 'Write-Log\s*`[\r\n\s]+"([^"]+)"\s*`[\r\n\s]+(\w+)',
        'Write-Log "$1" -Level $2'

    return $Content
}

function Remove-AIAttributions {
    param([string]$Content)

    # Remove all AI-related comments and attributions
    $Content = $Content -replace '# Enhanced by AI.*', ''
    $Content = $Content -replace '# AI-Enhanced.*', ''
    $Content = $Content -replace '# Generated by AI.*', ''
    $Content = $Content -replace '# Wesley Ellis Enterprise PowerShell Framework', '# Wes Ellis (wes@wesellis.com)'
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
            '→' = '->'
            '←' = '<-'
        }

        foreach ($char in $unicodeReplacements.Keys) {
            $content = $content -replace [regex]::Escape($char), $unicodeReplacements[$char]
        }

        # Save if changed
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Fix backticks and modernize")) {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Host "  Fixed: $FilePath" -ForegroundColor Green
                return $true
            }
        }
        else {
            Write-Host "  No changes needed" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
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

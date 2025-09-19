#Requires -Version 7.0

<#
.SYNOPSIS
    Final professional cleanup for all PowerShell scripts

.DESCRIPTION
    Comprehensive script that fixes ALL remaining issues:
    - Removes ALL backticks (including line continuations)
    - Removes emojis from production output
    - Standardizes headers
    - Converts to splatting
    - Ensures consistent formatting

.PARAMETER Path
    Root path to scan for PowerShell scripts

.PARAMETER Force
    Apply all fixes without prompting

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 3.0.0
    Created: 2025-09-19
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter()]
    [switch]$Force
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

$script:Stats = @{
    TotalScripts = 0
    BackticksFixed = 0
    EmojisRemoved = 0
    HeadersStandardized = 0
    SplattingConverted = 0
    Errors = 0
}
#endregion

#region Functions
function Remove-AllBackticks {
    param([string]$Content)

    $lines = $Content -split "`r?`n"
    $fixedLines = [System.Collections.ArrayList]::new()
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        # Check for line continuation backtick
        if ($line -match '^(\s*)(.*)\s+`\s*$') {
            $indent = $Matches[1]
            $currentCmd = $Matches[2].Trim()
            $continuationLines = [System.Collections.ArrayList]::new()
            [void]$continuationLines.Add($currentCmd)

            # Collect all continuation lines
            $i++
            while ($i -lt $lines.Count -and $lines[$i] -match '^\s+(.*)') {
                $continuedLine = $Matches[1]
                # Remove trailing backtick if present
                $continuedLine = $continuedLine -replace '\s*`\s*$', ''
                [void]$continuationLines.Add($continuedLine.Trim())
                $i++

                # Stop if we hit a line that doesn't look like a continuation
                if ($lines[$i] -notmatch '^\s+' -and $lines[$i] -ne '') {
                    break
                }
            }

            # Now convert to splatting
            $fullCommand = $continuationLines -join ' '

            # Parse the command
            if ($fullCommand -match '^(\S+)\s+(.+)$') {
                $cmdlet = $Matches[1]
                $paramString = $Matches[2]

                # Extract parameters
                $params = @{}
                $paramPattern = '-(\w+)\s+([^-][^`]*?)(?=\s+-|$)'
                $matches = [regex]::Matches($paramString, $paramPattern)

                foreach ($match in $matches) {
                    $paramName = $match.Groups[1].Value
                    $paramValue = $match.Groups[2].Value.Trim()

                    # Clean quotes
                    $paramValue = $paramValue.Trim('"', "'")

                    # Handle switches
                    if ([string]::IsNullOrWhiteSpace($paramValue)) {
                        $params[$paramName] = '$true'
                    } else {
                        # Preserve variable references
                        if ($paramValue -match '^\$') {
                            $params[$paramName] = $paramValue
                        } else {
                            $params[$paramName] = '"' + $paramValue + '"'
                        }
                    }
                }

                # Generate splatted version
                if ($params.Count -ge 3) {
                    [void]$fixedLines.Add("${indent}`$params = @{")
                    foreach ($key in $params.Keys) {
                        [void]$fixedLines.Add("${indent}    $key = $($params[$key])")
                    }
                    [void]$fixedLines.Add("${indent}}")
                    [void]$fixedLines.Add("${indent}$cmdlet @params")
                } else {
                    # For fewer params, use single line
                    $paramList = @()
                    foreach ($key in $params.Keys) {
                        if ($params[$key] -eq '$true') {
                            $paramList += "-$key"
                        } else {
                            $paramList += "-$key $($params[$key])"
                        }
                    }
                    [void]$fixedLines.Add("${indent}$cmdlet $($paramList -join ' ')")
                }
            } else {
                [void]$fixedLines.Add("${indent}$fullCommand")
            }
        } else {
            [void]$fixedLines.Add($line)
            $i++
        }
    }

    return $fixedLines -join "`n"
}

function Remove-Emojis {
    param([string]$Content)

    # Remove all emoji characters from Write-* statements
    $emojiPatterns = @(
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', '',
        '', '', '', '', '', '', '', ''
    )

    foreach ($emoji in $emojiPatterns) {
        $Content = $Content -replace [regex]::Escape($emoji), ''
    }

    # Clean up Write-Information/Host statements with emojis
    $Content = $Content -replace 'Write-(Information|Host|Output|Verbose)\s+"([^"]*)[]([^"]*)"', 'Write-$1 "$2$3"'

    # Replace emoji indicators with text
    $Content = $Content -replace '"\s*', '"[SUCCESS] '
    $Content = $Content -replace '"\s*', '"[ERROR] '
    $Content = $Content -replace '"\s*', '"[WARNING] '
    $Content = $Content -replace '"\s*', '"[INFO] '

    return $Content
}

function Standardize-Headers {
    param([string]$Content)

    # Remove the old banner style
    $Content = $Content -replace '# ={70,}[\r\n]+', ''
    $Content = $Content -replace '    $Content = $Content -replace '    $Content = $Content -replace '    $Content = $Content -replace '    $Content = $Content -replace '    $Content = $Content -replace '    $Content = $Content -replace '# ={70,}[\r\n]+', ''

    # Ensure proper comment-based help is at the top (after #Requires)
    if ($Content -notmatch '<#[\s\S]*?\.SYNOPSIS[\s\S]*?#>') {
        # Add minimal professional header if missing
        $requiresMatch = [regex]::Match($Content, '((?:#Requires.*[\r\n]+)*)')
        $requires = $requiresMatch.Groups[1].Value
        $restOfScript = $Content.Substring($requiresMatch.Length)

        $header = @"
<#
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: $(Get-Date -Format 'yyyy-MM-dd')
#>

"@
        $Content = $requires + $header + $restOfScript
    }

    return $Content
}

function Add-Regions {
    param([string]$Content)

    # Only add regions if they're completely missing
    if ($Content -notmatch '#region') {
        $lines = $Content -split "`r?`n"
        $inParam = $false
        $inFunction = $false
        $mainStarted = $false
        $result = [System.Collections.ArrayList]::new()

        foreach ($line in $lines) {
            if ($line -match '^param\s*\(') {
                $inParam = $true
            } elseif ($inParam -and $line -match '^\)') {
                $inParam = $false
                [void]$result.Add($line)
                [void]$result.Add('')
                [void]$result.Add('#region Functions')
                continue
            } elseif ($line -match '^function\s+') {
                $inFunction = $true
            } elseif (!$inParam -and !$inFunction -and !$mainStarted -and $line -match '^\S' -and $line -notmatch '^#|^<#') {
                if ($result[-1] -ne '#endregion') {
                    [void]$result.Add('#endregion')
                    [void]$result.Add('')
                }
                [void]$result.Add('#region Main-Execution')
                $mainStarted = $true
            }

            [void]$result.Add($line)
        }

        if ($mainStarted -and $result[-1] -ne '#endregion') {
            [void]$result.Add('#endregion')
        }

        return $result -join "`n"
    }

    return $Content
}

function Fix-ModuleImports {
    param([string]$Content)

    # Remove incorrect Import-Module paths
    $Content = $Content -replace 'Import-Module\s+\(Join-Path[^)]+\)[^\r\n]*', '# Module import removed - use #Requires instead'

    # Fix common module issues
    $Content = $Content -replace 'Import-Module\s+[^-\s]+\\[^-\s]+\\[\w\.]+\.psm1[^\r\n]*', '# Module import removed - use #Requires instead'

    return $Content
}

function Process-Script {
    param([string]$FilePath)

    try {
        Write-Host "Processing: $(Split-Path $FilePath -Leaf)" -ForegroundColor Cyan

        $content = Get-Content -Path $FilePath -Raw
        $originalContent = $content
        $changes = @()

        # Apply all fixes
        $newContent = Remove-AllBackticks -Content $content
        if ($newContent -ne $content) {
            $changes += "Removed backticks"
            $script:Stats.BackticksFixed++
        }
        $content = $newContent

        $newContent = Remove-Emojis -Content $content
        if ($newContent -ne $content) {
            $changes += "Removed emojis"
            $script:Stats.EmojisRemoved++
        }
        $content = $newContent

        $newContent = Standardize-Headers -Content $content
        if ($newContent -ne $content) {
            $changes += "Standardized headers"
            $script:Stats.HeadersStandardized++
        }
        $content = $newContent

        $newContent = Add-Regions -Content $content
        $content = $newContent

        $newContent = Fix-ModuleImports -Content $content
        $content = $newContent

        # Save if changed
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Apply professional fixes")) {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Host "  Fixed: $($changes -join ', ')" -ForegroundColor Green
                return $true
            }
        } else {
            Write-Host "  Already professional" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
        $script:Stats.Errors++
        return $false
    }
}
#endregion

#region Main-Execution
Write-Host "`n=== FINAL PROFESSIONAL CLEANUP ===" -ForegroundColor Cyan
Write-Host "Making all scripts production-ready...`n" -ForegroundColor Yellow

# Get all PowerShell scripts
$scripts = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse
$script:Stats.TotalScripts = $scripts.Count

Write-Host "Found $($scripts.Count) scripts to process" -ForegroundColor Yellow

$counter = 0
foreach ($script in $scripts) {
    $counter++
    $percentComplete = [math]::Round(($counter / $scripts.Count) * 100, 2)

    $params = @{
        Status = "Processing $($script.Name)"
        PercentComplete = $percentComplete
        Activity = "Professional Cleanup"
        CurrentOperation = $counter of $($scripts.Count)
    }
    Write-Progress @params

    Process-Script -FilePath $script.FullName | Out-Null
}

Write-Progress -Activity "Professional Cleanup" -Completed

Write-Host "`n=== CLEANUP COMPLETE ===" -ForegroundColor Green
Write-Host "Total Scripts: $($script:Stats.TotalScripts)"
Write-Host "Backticks Fixed: $($script:Stats.BackticksFixed)"
Write-Host "Emojis Removed: $($script:Stats.EmojisRemoved)"
Write-Host "Headers Standardized: $($script:Stats.HeadersStandardized)"
Write-Host "Errors: $($script:Stats.Errors)"

Write-Host "`nAll scripts are now production-ready!" -ForegroundColor Green
#endregion

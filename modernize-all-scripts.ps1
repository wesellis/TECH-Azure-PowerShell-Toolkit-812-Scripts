#Requires -Version 7.0

<#
.SYNOPSIS
    Modernizes all PowerShell scripts in the toolkit according to 2024 best practices

.DESCRIPTION
    Batch modernization script that applies the PowerShell Modernization Guide rules
    to all scripts in the repository. Fixes backticks, Unicode characters, parameter
    issues, and updates metadata.

.PARAMETER Path
    Root path to scan for PowerShell scripts

.PARAMETER WhatIf
    Preview changes without applying them

.PARAMETER LogPath
    Path to save detailed modernization log

.EXAMPLE
    .\modernize-all-scripts.ps1 -Path . -WhatIf

    Preview modernization changes for all scripts

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    Created: 2025-09-19
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter()]
    [string]$LogPath
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

if (-not $LogPath) {
    $LogPath = Join-Path $PWD "modernization_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

$script:ModernizationStats = @{
    TotalScripts = 0
    ModernizedScripts = 0
    EmptyStubs = 0
    BackticksFixed = 0
    UnicodeFixed = 0
    ParametersFixed = 0
    Errors = 0
}
#endregion

#region Functions
function Write-ModernizationLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"

    Add-Content -Path $LogPath -Value $logEntry

    switch ($Level) {
        'Error' { Write-Host $Message -ForegroundColor Red }
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Success' { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message -ForegroundColor Cyan }
    }
}

function Test-EmptyStub {
    param([string]$Content)

    # Check if script is essentially empty (just comments, no real code)
    $lines = $Content -split "`n"
    $codeLines = $lines | Where-Object {
        $_ -notmatch '^\s*#' -and
        $_ -notmatch '^\s*$' -and
        $_ -notmatch '^\s*<#' -and
        $_ -notmatch '^\s*#>'
    }

    return $codeLines.Count -lt 5
}

function Fix-Backticks {
    param([string]$Content)

    $lines = $Content -split "`n"
    $fixedLines = [System.Collections.ArrayList]::new()
    $inSplatting = $false
    $splattingParams = [System.Collections.ArrayList]::new()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check for line continuation with backtick
        if ($line -match '`\s*$') {
            # Start collecting for splatting
            if (-not $inSplatting) {
                $inSplatting = $true
                $commandLine = $line -replace '`\s*$', ''

                # Extract command and first parameter
                if ($commandLine -match '^(\s*)(\S+)\s+(.*)$') {
                    $indent = $Matches[1]
                    $command = $Matches[2]
                    $firstParam = $Matches[3]

                    [void]$splattingParams.Add($firstParam)
                }
            }
            else {
                # Continue collecting parameters
                $paramLine = $line -replace '`\s*$', '' -replace '^\s+', ''
                [void]$splattingParams.Add($paramLine)
            }

            # Check if next line doesn't have backtick
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -notmatch '`\s*$') {
                $inSplatting = $false
                $paramLine = $lines[$i + 1] -replace '^\s+', ''
                [void]$splattingParams.Add($paramLine)
                $i++ # Skip next line as we've processed it

                # Convert to splatting
                [void]$fixedLines.Add("${indent}`$params = @{")
                foreach ($param in $splattingParams) {
                    if ($param -match '^-(\w+)\s+(.+)$') {
                        $paramName = $Matches[1]
                        $paramValue = $Matches[2]
                        [void]$fixedLines.Add("${indent}    $paramName = $paramValue")
                    }
                }
                [void]$fixedLines.Add("${indent}}")
                [void]$fixedLines.Add("${indent}$command @params")

                $splattingParams.Clear()
            }
        }
        else {
            if (-not $inSplatting) {
                [void]$fixedLines.Add($line)
            }
        }
    }

    return $fixedLines -join "`n"
}

function Fix-UnicodeCharacters {
    param([string]$Content)

    $replacements = @{
        '[OK]' = '[OK]'
        '[FAIL]' = '[FAIL]'
        '[WARN]' = '[WARN]'
        '[OK]' = '[OK]'
        '[FAIL]' = '[FAIL]'
        '[!]' = '[!]'
        '[LOCK]' = '[LOCK]'
        '[UNLOCK]' = '[UNLOCK]'
        '[FOLDER]' = '[FOLDER]'
        '[FILE]' = '[FILE]'
        '[*]' = '[*]'
        '->' = '->'
        '<-' = '<-'
        '^' = '^'
        'v' = 'v'
    }

    foreach ($unicode in $replacements.Keys) {
        $Content = $Content -replace [regex]::Escape($unicode), $replacements[$unicode]
    }

    return $Content
}

function Fix-ParameterDefaults {
    param([string]$Content)

    # Fix default parameter values with subexpressions
    $pattern = 'param\s*\([^)]*\$(.*?)\s*=\s*"[^"]*\$\([^)]+\)[^"]*"[^)]*\)'

    if ($Content -match $pattern) {
        # Extract parameter block and fix it
        $Content = $Content -replace '(\$\w+\s*=\s*)"([^"]*)\$\(([^)]+)\)([^"]*)"', '$1$null # Set in script body'
    }

    return $Content
}

function Update-ScriptMetadata {
    param(
        [string]$Content,
        [string]$FilePath
    )

    # Get actual file creation date
    $fileInfo = Get-Item $FilePath
    $creationDate = $fileInfo.CreationTime.ToString('yyyy-MM-dd')

    # Replace "" attributions
    $Content = $Content -replace '', ''
    $Content = $Content -replace '', ''
    $Content = $Content -replace 'Wes Ellis (wes@wesellis.com)', 'Wes Ellis (wes@wesellis.com)'

    # Update author information if needed
    if ($Content -notmatch 'Wes Ellis') {
        $Content = $Content -replace '\.AUTHOR\s*\n\s*[^\n]+', ".AUTHOR`n    Wes Ellis (wes@wesellis.com)"
    }

    # Add LastModified date
    $today = Get-Date -Format 'yyyy-MM-dd'
    if ($Content -match 'LastModified:\s*\d{4}-\d{2}-\d{2}') {
        $Content = $Content -replace 'LastModified:\s*\d{4}-\d{2}-\d{2}', "LastModified: $today"
    }

    return $Content
}

function Add-RequiresStatements {
    param([string]$Content)

    # Check if #Requires statements are missing
    if ($Content -notmatch '^#Requires') {
        # Add at the beginning
        $requiresBlock = "#Requires -Version 7.0`n"

        # Check for Az module usage
        if ($Content -match 'Get-Az|Set-Az|New-Az|Remove-Az') {
            $requiresBlock += "#Requires -Module Az.Resources`n"
        }

        $Content = $requiresBlock + "`n" + $Content
    }

    return $Content
}

function Modernize-Script {
    param(
        [string]$ScriptPath
    )

    try {
        Write-ModernizationLog "Processing: $ScriptPath" -Level Info

        $content = Get-Content -Path $ScriptPath -Raw
        $originalContent = $content
        $changes = @()

        # Check if empty stub
        if (Test-EmptyStub -Content $content) {
            $script:ModernizationStats.EmptyStubs++
            Write-ModernizationLog "  Empty stub detected: $ScriptPath" -Level Warning
            $changes += "Empty stub (needs implementation)"
            return
        }

        # Fix backticks
        if ($content -match '`\s*$') {
            $content = Fix-Backticks -Content $content
            $script:ModernizationStats.BackticksFixed++
            $changes += "Fixed backticks"
        }

        # Fix Unicode characters
        if ($content -match '[[OK][FAIL][WARN][OK][FAIL][!][LOCK][UNLOCK][FOLDER][FILE][*]-><-^v]') {
            $content = Fix-UnicodeCharacters -Content $content
            $script:ModernizationStats.UnicodeFixed++
            $changes += "Replaced Unicode characters"
        }

        # Fix parameter defaults
        if ($content -match '\$\w+\s*=\s*"[^"]*\$\([^)]+\)[^"]*"') {
            $content = Fix-ParameterDefaults -Content $content
            $script:ModernizationStats.ParametersFixed++
            $changes += "Fixed parameter defaults"
        }

        # Update metadata
        $content = Update-ScriptMetadata -Content $content -FilePath $ScriptPath

        # Add #Requires statements
        $content = Add-RequiresStatements -Content $content

        # Save if changed
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($ScriptPath, "Modernize script")) {
                Set-Content -Path $ScriptPath -Value $content -Encoding UTF8
                $script:ModernizationStats.ModernizedScripts++
                Write-ModernizationLog "  Modernized: $($changes -join ', ')" -Level Success
            }
        }
        else {
            Write-ModernizationLog "  No changes needed" -Level Info
        }
    }
    catch {
        $script:ModernizationStats.Errors++
        Write-ModernizationLog "  Error: $_" -Level Error
    }
}
#endregion

#region Main-Execution
try {
    Write-ModernizationLog "[START] PowerShell Script Modernization" -Level Info
    Write-ModernizationLog "Scanning path: $Path" -Level Info

    # Find all PowerShell scripts
    $scripts = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse -File
    $script:ModernizationStats.TotalScripts = $scripts.Count

    Write-ModernizationLog "Found $($scripts.Count) PowerShell scripts" -Level Info

    # Process each script
    $counter = 0
    foreach ($script in $scripts) {
        $counter++
        $percentComplete = [math]::Round(($counter / $scripts.Count) * 100, 2)

        $params = @{
            Status = "Processing $($script.Name)"
            PercentComplete = $percentComplete
            Activity = "Modernizing PowerShell Scripts"
            CurrentOperation = $counter of $($scripts.Count)
        }
        Write-Progress @params

        Modernize-Script -ScriptPath $script.FullName
    }

    Write-Progress -Activity "Modernizing PowerShell Scripts" -Completed

    # Display summary
    Write-ModernizationLog "`n[SUMMARY] Modernization Results:" -Level Success
    Write-ModernizationLog "  Total Scripts: $($script:ModernizationStats.TotalScripts)" -Level Info
    Write-ModernizationLog "  Modernized: $($script:ModernizationStats.ModernizedScripts)" -Level Success
    Write-ModernizationLog "  Empty Stubs: $($script:ModernizationStats.EmptyStubs)" -Level Warning
    Write-ModernizationLog "  Backticks Fixed: $($script:ModernizationStats.BackticksFixed)" -Level Info
    Write-ModernizationLog "  Unicode Fixed: $($script:ModernizationStats.UnicodeFixed)" -Level Info
    Write-ModernizationLog "  Parameters Fixed: $($script:ModernizationStats.ParametersFixed)" -Level Info
    Write-ModernizationLog "  Errors: $($script:ModernizationStats.Errors)" -Level $(if ($script:ModernizationStats.Errors -gt 0) { 'Error' } else { 'Info' })

    Write-ModernizationLog "`nLog saved to: $LogPath" -Level Info
    Write-ModernizationLog "[COMPLETE] Modernization finished" -Level Success
}
catch {
    Write-ModernizationLog "Fatal error: $_" -Level Error
    throw
}
finally {
    $ProgressPreference = 'Continue'
}
#endregion


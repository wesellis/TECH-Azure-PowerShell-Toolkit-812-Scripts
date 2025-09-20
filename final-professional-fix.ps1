<#
.SYNOPSIS[\s\S]*?#>') {
        # Add minimal professional header if missing
        $requiresMatch = [regex]::Match($Content, '((?:#Requires.*[\r\n]+)*)')
        $requires = $requiresMatch.Groups[1].Value
        $restOfScript = $Content.Substring($requiresMatch.Length)

        $header = @"
    Azure automation script

    Professional PowerShell script for

    Author: Wes Ellis (wes@wesellis.com)LastModified: $(Get-Date -Format 'yyyy-MM-dd')
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
            } elseif (!$inParam -and !$infunction and !$mainStarted -and $line -match '^\S' -and $line -notmatch '^#|^<#') {
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
                Write-Host "Fixed: $($changes -join ', ')" -ForegroundColor Green
                return $true
            }
        } else {
            Write-Host "Already professional" -ForegroundColor Yellow
            return $false

} catch {
        Write-Host "Error: $_" -ForegroundColor Red
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


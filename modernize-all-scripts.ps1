#Requires -Version 7.0

    Modernizes all PowerShell scripts in the toolkit according to 2024 best practices

    Batch modernization script that applies the PowerShell Modernization Guide rules
    to all scripts in the repository. Fixes backticks, Unicode characters, parameter
    issues, and updates metadata.
.PARAMETER Path
    Root path to scan for PowerShell scripts
.PARAMETER WhatIf
    Preview changes without applying them
.PARAMETER LogPath
    Path to save detailed modernization log

    .\modernize-all-scripts.ps1 -Path . -WhatIf

    Preview modernization changes for all scripts

    Author: Wes Ellis (wes@wesellis.com)

    # Update author information if needed
    if ($Content -notmatch 'Wes Ellis') {

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

} catch {
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


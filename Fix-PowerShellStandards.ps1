#Requires -Version 7.0

<#
.SYNOPSIS
    Fix PowerShell standards across all scripts in the repository

.DESCRIPTION
    This script systematically fixes common PowerShell standards violations across all scripts:
    - Adds [CmdletBinding()] to scripts missing it
    - Fixes malformed comment blocks with escaped newlines
    - Adds proper #Requires statements
    - Standardizes comment-based help format
    - Adds basic parameter validation

.PARAMETER ScriptPath
    Path to the scripts directory to process

.EXAMPLE
    .\Fix-PowerShellStandards.ps1 -ScriptPath ".\scripts"

.NOTES
    Author: Azure PowerShell Toolkit Remediation
    Version: 1.0
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$ScriptPath
)

function Fix-PowerShellScript {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    Write-Verbose "Processing: $FilePath"

    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $originalContent = $content
        $changes = @()

        # Fix escaped newlines in comment blocks
        if ($content -match '\\n') {
            $content = $content -replace '\\n', "`n"
            $changes += "Fixed escaped newlines"
        }

        # Check if script needs CmdletBinding
        $needsCmdletBinding = $false

        # If script has param() block but no [CmdletBinding()]
        if ($content -match 'param\s*\(' -and $content -notmatch '\[CmdletBinding') {
            $needsCmdletBinding = $true
        }

        # If script uses Write-Verbose, Write-Debug, or $PSCmdlet but no [CmdletBinding()]
        if (($content -match 'Write-Verbose|Write-Debug|\$PSCmdlet') -and $content -notmatch '\[CmdletBinding') {
            $needsCmdletBinding = $true
        }

        if ($needsCmdletBinding) {
            # Find the param block and add CmdletBinding before it
            if ($content -match '(param\s*\()') {
                $content = $content -replace '(param\s*\()', '[CmdletBinding()]`nparam('
                $changes += "Added [CmdletBinding()]"
            }
        }

        # Add #Requires -Version 7.0 if missing
        if ($content -notmatch '#Requires\s+-Version') {
            # Find the best place to insert #Requires
            $lines = $content -split "`n"
            $insertIndex = 0

            # Skip initial comments and whitespace
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*$' -or $lines[$i] -match '^\s*#') {
                    continue
                } else {
                    $insertIndex = $i
                    break
                }
            }

            # Insert #Requires at the beginning
            $lines = @('#Requires -Version 7.0', '') + $lines
            $content = $lines -join "`n"
            $changes += "Added #Requires -Version 7.0"
        }

        # Fix common Azure module requirements
        $azureModules = @()
        if ($content -match 'Get-Az|New-Az|Set-Az|Remove-Az') {
            $azureModules += 'Az.Resources'
        }
        if ($content -match 'Get-AzVM|New-AzVM') {
            $azureModules += 'Az.Compute'
        }
        if ($content -match 'Get-AzStorageAccount|New-AzStorageAccount') {
            $azureModules += 'Az.Storage'
        }
        if ($content -match 'Get-AzVirtualNetwork|New-AzVirtualNetwork') {
            $azureModules += 'Az.Network'
        }
        if ($content -match 'Get-AzKeyVault|New-AzKeyVault') {
            $azureModules += 'Az.KeyVault'
        }

        foreach ($module in ($azureModules | Select-Object -Unique)) {
            if ($content -notmatch "#Requires\s+-Modules\s+$module") {
                # Add after the version requirement
                $content = $content -replace '(#Requires -Version 7\.0)', "`$1`n#Requires -Modules $module"
                $changes += "Added #Requires -Modules $module"
            }
        }

        # Fix malformed comment blocks
        $content = $content -replace '<#\s*\n\s*\.', '<#`n.'
        $content = $content -replace '(\s+Author:.*?)\s*\n\s*#>', "`n`$1`n#>"

        # Only write if changes were made
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Apply PowerShell standards fixes")) {
                Set-Content -Path $FilePath -Value $content -NoNewline
                Write-Host "Fixed: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
                if ($changes.Count -gt 0) {
                    Write-Host "  Changes: $($changes -join ', ')" -ForegroundColor Gray
                }
                return $true
            }
        } else {
            Write-Verbose "No changes needed for: $FilePath"
            return $false
        }

    } catch {
        Write-Warning "Failed to process $FilePath`: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-Host "Starting PowerShell standards remediation..." -ForegroundColor Cyan

$scriptFiles = Get-ChildItem -Path $ScriptPath -Filter "*.ps1" -Recurse
$totalFiles = $scriptFiles.Count
$processedFiles = 0
$modifiedFiles = 0

Write-Host "Found $totalFiles PowerShell scripts to process" -ForegroundColor Yellow

foreach ($file in $scriptFiles) {
    $processedFiles++
    Write-Progress -Activity "Processing PowerShell Scripts" -Status "File $processedFiles of $totalFiles" -PercentComplete (($processedFiles / $totalFiles) * 100)

    if (Fix-PowerShellScript -FilePath $file.FullName) {
        $modifiedFiles++
    }
}

Write-Progress -Activity "Processing PowerShell Scripts" -Completed

Write-Host "`nPowerShell Standards Remediation Complete!" -ForegroundColor Green
Write-Host "Processed: $processedFiles files" -ForegroundColor White
Write-Host "Modified: $modifiedFiles files" -ForegroundColor Green
Write-Host "Unchanged: $($processedFiles - $modifiedFiles) files" -ForegroundColor Gray

if ($modifiedFiles -gt 0) {
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Review the changes made to scripts" -ForegroundColor White
    Write-Host "2. Test critical scripts to ensure they still function" -ForegroundColor White
    Write-Host "3. Run PSScriptAnalyzer to validate compliance" -ForegroundColor White
    Write-Host "4. Commit changes with appropriate git message" -ForegroundColor White
}
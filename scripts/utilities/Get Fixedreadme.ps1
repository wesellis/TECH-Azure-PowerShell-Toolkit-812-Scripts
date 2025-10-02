#Requires -Version 7.4

<#
.SYNOPSIS
    Get Fixedreadme - Fix README Badge and Button Markup

.DESCRIPTION
    Azure automation script that fixes README badge and button markup by replacing existing badges with standardized markup.
    This script automatically processes README content and replaces badge links and deployment buttons with expected markup.

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER ReadmeContents
    The content of the README file to be fixed

.PARAMETER ExpectedMarkdown
    The expected markdown markup to replace badges and buttons

.EXAMPLE
    PS C:\> .\Get_Fixedreadme.ps1 -ReadmeContents $content -ExpectedMarkdown $markup
    Fixes README badges and buttons with the provided markup

.INPUTS
    String content for README and expected markdown

.OUTPUTS
    Fixed README content with proper badge and button markup

.NOTES
    This script processes badge links and deployment buttons in README files
    and standardizes them with expected markup patterns.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ReadmeContents,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedMarkdown
)

$ErrorActionPreference = "Stop"

function Convert-StringToLines {
    <#
    .SYNOPSIS
        Converts a string to an array of lines
    #>
    param([string]$Content)
    return $Content -split "`r`n|`r|`n"
}

function Convert-LinesToString {
    <#
    .SYNOPSIS
        Converts an array of lines back to a string
    #>
    param([string[]]$Lines)
    return ($Lines -join [System.Environment]::NewLine)
}

function Test-LineLooksBadgeLinkOrButton {
    <#
    .SYNOPSIS
        Tests if a line contains badge links or deployment buttons
    #>
    param([string]$line)

    if ($line -match "!\[") {
        if ($line -match "\/badges\/") {
            return $true
        }
        if ($line -match "deploytoazure.svg|deploytoazuregov.svg|visualizebutton.svg") {
            return $true
        }
    }
    return $false
}

try {
    $NewLine = [System.Environment]::NewLine
    $mark = "YAYBADGESYAY"
    $lines = Convert-StringToLines $ReadmeContents

    $ExpectedMsg = @"
The expected markup for the readme is:
$ExpectedMarkdown
"@

    # Mark badge and button lines for replacement
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (Test-LineLooksBadgeLinkOrButton $lines[$i]) {
            $lines[$i] = $mark
        }
    }

    $fixed = Convert-LinesToString $lines

    # If no badges found, insert at the beginning after title
    if ($fixed -notlike "*$mark*") {
        if ($fixed[0] -notlike "#*") {
            Write-Warning $ExpectedMsg
            throw "Unable to automatically fix README badges and buttons - no badges or buttons found, and the first line doesn't start with '#'"
        }
        # Insert after the first line (title)
        $lines = @($lines[0], "", $mark) + $lines[1..$lines.Length]
        $fixed = Convert-LinesToString $lines
    }
    else {
        # Consolidate multiple consecutive markers
        $fixed = $fixed -replace "$mark([`r`n]|$mark)*", "$mark"
    }

    # Check for non-contiguous badges
    if ($fixed -match "(?ms)$mark.*$mark") {
        Write-Warning $ExpectedMsg
        throw "Unable to automatically fix README badges and buttons - badges/buttons are not contiguous in the README. Either make them contiguous or fix manually."
    }

    # Replace marker with expected markdown
    $fixed = $fixed -replace "[`r`n]*$mark[`r`n]*", "$NewLine$NewLine$($ExpectedMarkdown.Trim())$NewLine$NewLine"

    return $fixed.Trim() + $NewLine
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
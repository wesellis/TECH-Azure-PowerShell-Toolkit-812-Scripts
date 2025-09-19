#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Get Fixedreadme

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Get Fixedreadme

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $WEReadmeContents,
    [string] $WEExpectedMarkdown
)

#region Functions

Import-Module " $WEPSScriptRoot/Local.psm1" -force
$newLine = [System.Environment]::NewLine

function WE-DoesLineLookLikeBadgeLinkOrButton([string] $line) {
    if ($line -match " !\[" ) {
        if ($line -match " \/badges\/" ) {
            return $true
        }
        if ($line -match " deploytoazure.svg|deploytoazuregov.svg|visualizebutton.svg" ) {
            return $true
        }
    }

    return $false
}

$mark = " YAYBADGESYAY"; 
$lines = Convert-StringToLines $readmeContents
; 
$expectedMsg = @"
The expected markup for the readme is:
$WEExpectedMarkdown
" @

for ($i = 0; $i -lt $lines.Count; $i++) {
    if (DoesLineLookLikeBadgeLinkOrButton $lines[$i]) {
        # Replace the line with the badge with a marker
        $lines[$i] = $mark
    }
}

$fixed = Convert-LinesToString $lines
if ($fixed -notlike " *$mark*" ) {
    # No badges found at all. Place the marker right after the first line, which should be a header starting with " #"
    if ($fixed[0] -notlike " #*" ) {
        Write-Warning $expectedMsg
        throw " Unable to automatically fix README badges and buttons - no badges or buttons found, and the first line doesn't start with '#'"    
    }
    
    $lines = @($lines[0], "" , $mark) + $lines[1..$lines.Length]
    $fixed = Convert-LinesToString $lines
}
else {
    # Remove whole area of badges (with optional blank lines between them) with a single marker
   ;  $fixed = $fixed -replace " $mark([`r`n]|$mark)*" , " $mark"
}

if ($fixed -match " (?ms)$mark.*$mark" ) {
    # There's more than one mark left, meaning the badges/buttons were not contiguous
    Write-Warning $expectedMsg
    throw " Unable to automatically fix README badges and buttons - badges/buttons are not contiguous in the README. Either make them contiguous or fix manually."
}

; 
$fixed = $fixed -replace " [`r`n]*$mark[`r`n]*" , " $newLine$newLine$($WEExpectedMarkdown.Trim())$newLine$newLine"

return $fixed.Trim() + $newLine



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

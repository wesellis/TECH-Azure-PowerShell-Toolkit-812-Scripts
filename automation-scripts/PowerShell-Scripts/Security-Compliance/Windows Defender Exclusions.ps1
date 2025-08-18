<#
.SYNOPSIS
    We Enhanced Windows Defender Exclusions

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)] [string] $WEExclusionPaths = "" ,
    [Parameter(Mandatory = $false)] [string] $WEExclusionExtensions = "" ,
    [Parameter(Mandatory = $false)] [string] $WEExclusionProcesses = ""
)

Set-StrictMode -Version Latest

$WEErrorActionPreference = " Stop"
; 
$parameters = @{}
if ($WEExclusionPaths.Trim() -ne "" ) {
    $parameters = $parameters + @{
        ExclusionPath = $WEExclusionPaths -split ","
    }
}

if ($WEExclusionExtensions.Trim() -ne "" ) {
    $parameters = $parameters + @{
        ExclusionExtension = $WEExclusionExtensions -split ","
    }
}

if ($WEExclusionProcesses.Trim() -ne "" ) {
    $parameters = $parameters + @{
        ExclusionProcess = $WEExclusionProcesses -split ","
    }
}

if ($parameters.Count -ne 0) {
    Add-MpPreference @parameters
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

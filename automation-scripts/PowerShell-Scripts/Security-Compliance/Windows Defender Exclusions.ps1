#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Defender Exclusions

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
    We Enhanced Windows Defender Exclusions

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
    [Parameter(Mandatory = $false)] [string] $WEExclusionPaths = "" ,
    [Parameter(Mandatory = $false)] [string] $WEExclusionExtensions = "" ,
    [Parameter(Mandatory = $false)] [string] $WEExclusionProcesses = ""
)

#region Functions

Set-StrictMode -Version Latest
; 
$WEErrorActionPreference = " Stop"
; 
$parameters = @{}
if ($WEExclusionPaths.Trim() -ne "" ) {
    $parameters = $parameters + @{
        ExclusionPath = $WEExclusionPaths -split " ,"
    }
}

if ($WEExclusionExtensions.Trim() -ne "" ) {
    $parameters = $parameters + @{
        ExclusionExtension = $WEExclusionExtensions -split " ,"
    }
}

if ($WEExclusionProcesses.Trim() -ne "" ) {
   ;  $parameters = $parameters + @{
        ExclusionProcess = $WEExclusionProcesses -split " ,"
    }
}

if ($parameters.Count -ne 0) {
    Add-MpPreference @parameters
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

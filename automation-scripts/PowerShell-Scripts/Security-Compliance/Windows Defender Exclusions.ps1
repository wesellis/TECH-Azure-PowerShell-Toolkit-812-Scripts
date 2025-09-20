<#
.SYNOPSIS
    Windows Defender Exclusions

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)] [string] $ExclusionPaths = "",
    [Parameter(Mandatory = $false)] [string] $ExclusionExtensions = "",
    [Parameter(Mandatory = $false)] [string] $ExclusionProcesses = ""
)
Set-StrictMode -Version Latest
try {
$parameters = @{}
if ($ExclusionPaths.Trim() -ne "") {
    $parameters = $parameters + @{
        ExclusionPath = $ExclusionPaths -split ","
    }
}
if ($ExclusionExtensions.Trim() -ne "") {
    $parameters = $parameters + @{
        ExclusionExtension = $ExclusionExtensions -split ","
    }
}
if ($ExclusionProcesses.Trim() -ne "") {
$parameters = $parameters + @{
        ExclusionProcess = $ExclusionProcesses -split ","
    }
}
if ($parameters.Count -ne 0) {
    Add-MpPreference @parameters
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


<#
.SYNOPSIS
    We Enhanced Windows Add To Path

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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]
    [string]$newPath
)

try {
    Write-WELog "Adding '$newPath' to system's Path environment variable" " INFO"
    if ($newPath.Contains(" ;")) {
        Write-WELog " WARNING: Cannot add path that contains ';' (semicolon) to system's Path environment variable" " INFO"
        Write-WELog " Not making any changes" " INFO"
        exit 0
    }
    
    $path = [Environment]::GetEnvironmentVariable('Path', 'Machine')
   ;  $pathPieces = $path -split " ;"
    if ($newPath -in $pathPieces) {
        Write-WELog " Path already contains '$newPath'. Not making any changes." " INFO"
    }
    else {
        $modifiedPath = $path + " ;" + $newPath
        [Environment]::SetEnvironmentVariable(" Path", $modifiedPath, 'Machine')
        Write-WELog " '$newPath' added to system's Path environment variable" " INFO"
    }
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
<#
.SYNOPSIS
    Windows Npm Global

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

<#
.SYNOPSIS
    We Enhanced Windows Npm Global

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$packages,
    [Parameter(Mandatory=$false)]
    [bool]$addToPath=$true
)

try {
   ;  $packageArray = $packages.split(" ," )
   ;  $npmPrefix = " C:\npm"
    npm config set prefix $npmPrefix

    for ($i = 0; $i -lt $packageArray.count; $i++) {
        $package = $packageArray[$i].trim()

        Write-WELog " Installing $package globally" " INFO"
        npm install -g $package
        Write-WELog " Installation complete" " INFO"
    }

    if ($addToPath) {
        Write-WELog " Adding npm prefix to PATH" " INFO"
	[Environment]::SetEnvironmentVariable(" PATH" , $env:Path + " ;$npmPrefix" , " Machine" )
        Write-WELog " npm prefix added to PATH" " INFO"
    }
} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
<#
.SYNOPSIS
    We Enhanced Windows Sysinternals Suite

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
    Installs the Sysinternals Suite
.DESCRIPTION
    Downloads and installs the Sysinternals Suite
    If the AddShortcuts parameter is set to true, it will also add shortcuts to the desktop for Procmon and Procexp


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)]
    [bool] $WEAddShortcuts = $false,
    [Parameter()]
    [string] $WESoftwareDir = "C:\.tools"
)

$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest
; 
$WESysinternalsSuiteUrl = " https://download.sysinternals.com/files/SysinternalsSuite.zip";

filter timestamp {" $(Get-Date ([datetime]::UtcNow) -Format G) UTC: $_"}

if (!(Test-Path -Path $WESoftwareDir)) {
    Write-Output " Path $WESoftwareDir doesn't exist. Creating new path" | timestamp
    New-Item -Path $WESoftwareDir -Type Directory
}

try{
    Write-Output " start download of Sysinternal tool suite" | timestamp
    $fileName=" SysinternalsSuite.zip"
    $WESysInternal =  [System.IO.Path]::Combine($WESoftwareDir, $fileName)
    Invoke-WebRequest -Uri $WESysinternalsSuiteUrl -UseBasicParsing -OutFile $WESysInternal
    Write-Output " Download of Sysinternal tool suite done." | timestamp

    $WEDestinationDirectory = Join-Path -Path $WESoftwareDir -ChildPath " SysinternalsSuite"
    if(!(Test-Path -Path $WEDestinationDirectory)){
        New-Item -Path $WEDestinationDirectory -Type Directory
    }
    $WEZip = Join-Path -Path $WESoftwareDir -ChildPath $fileName
    Write-Output " Extracting $fileName to $WEDestinationDirectory" | timestamp
    Expand-Archive -Path $WEZip -DestinationPath $WEDestinationDirectory -Force
    Write-Output " Extraction of $fileName to $WEDestinationDirectory done" | timestamp

    Write-Output " Deleting $fileName from $WESoftwareDir" | timestamp
    rm $WEZip

    # Add desktop shortcut for Procmon and Procexp if requested
    if ($WEAddShortcuts) {
       ;  $invokecommandScriptPath = (Join-Path $(Split-Path -Parent $WEPSScriptRoot) 'windows-create-shortcut/windows-create-shortcut.ps1')
        # Add shortcut on the desktop for Procmon64 and set run as admin.
        & $invokecommandScriptPath  -ShortcutName " Procmon64" -ShortcutTargetPath " $WEDestinationDirectory\Procmon64.exe" -EnableRunAsAdmin 'true'
        # Add shortcut on the desktop for Procexp64  and set run as admin.
        & $invokecommandScriptPath  -ShortcutName " Procexp64" -ShortcutTargetPath " $WEDestinationDirectory\procexp64.exe" -EnableRunAsAdmin 'true'
    }
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
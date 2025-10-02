#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Sysinternals Suite

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Installs the Sysinternals Suite
    Downloads and installs the Sysinternals Suite
    If the AddShortcuts parameter is set to true, it will also add shortcuts to the desktop for Procmon and Procexp
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)]
    [bool] $AddShortcuts = $false,
    [Parameter()]
    [string] $SoftwareDir = "C:\.tools"
)
Set-StrictMode -Version Latest
    $SysinternalsSuiteUrl = "https://download.sysinternals.com/files/SysinternalsSuite.zip" ;
filter timestamp {" $(Get-Date -ErrorAction Stop ([datetime]::UtcNow) -Format G) UTC: $_" }
if (!(Test-Path -Path $SoftwareDir)) {
    Write-Output "Path $SoftwareDir doesn't exist. Creating new path" | timestamp
    New-Item -Path $SoftwareDir -Type Directory
}
try{
    Write-Output " start download of Sysinternal tool suite" | timestamp
    $FileName="SysinternalsSuite.zip"
    $SysInternal =  [System.IO.Path]::Combine($SoftwareDir, $FileName)
    Invoke-WebRequest -Uri $SysinternalsSuiteUrl -UseBasicParsing -OutFile $SysInternal
    Write-Output "Download of Sysinternal tool suite done." | timestamp
    $DestinationDirectory = Join-Path -Path $SoftwareDir -ChildPath "SysinternalsSuite"
    if(!(Test-Path -Path $DestinationDirectory)){
        New-Item -Path $DestinationDirectory -Type Directory
    }
    $Zip = Join-Path -Path $SoftwareDir -ChildPath $FileName
    Write-Output "Extracting $FileName to $DestinationDirectory" | timestamp
    Expand-Archive -Path $Zip -DestinationPath $DestinationDirectory -Force
    Write-Output "Extraction of $FileName to $DestinationDirectory done" | timestamp
    Write-Output "Deleting $FileName from $SoftwareDir" | timestamp
    rm $Zip
    if ($AddShortcuts) {
    $InvokecommandScriptPath = (Join-Path $(Split-Path -Parent $PSScriptRoot) 'windows-create-shortcut/windows-create-shortcut.ps1')
        & $InvokecommandScriptPath  -ShortcutName "Procmon64" -ShortcutTargetPath " $DestinationDirectory\Procmon64.exe" -EnableRunAsAdmin 'true'
        & $InvokecommandScriptPath  -ShortcutName "Procexp64" -ShortcutTargetPath " $DestinationDirectory\procexp64.exe" -EnableRunAsAdmin 'true'

} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}

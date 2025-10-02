#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Disable Reservedstorage

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Uses DISM to disable Reserved Storage.
     Checks current state of Reserved Storage and if enabled will disable it using DISM command Set-ReservedStorageState.
    Sample Bicep snippet for using the artifact:
    {
      name: 'windows-disable-reservedstorage'
    }
[CmdletBinding()]
    [string]$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)] [bool] $IgnoreFailure = $false
)
Set-StrictMode -Version Latest
    [string]$OnFailureBlock = {
    [string]$DismLog = 'C:\WINDOWS\Logs\DISM\dism.log'
    [string]$LogTailLines = 200
    if (Test-Path -Path $DismLog -PathType Leaf) {
        Write-Output " === Tail of $DismLog :" "INFO"
        try {
            Get-Content -ErrorAction Stop $DismLog -Tail $LogTailLines
        }
        catch {
            LogError $_ " [WARN] Failed to read $DismLog"
        }
    }
}
try {
    Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-retry-utils.psm1')
    Write-Output "Using DISM to disable Reserved Storage." "INFO"
    RunWithRetries -retryAttempts 10 -waitBeforeRetrySeconds 2 -exponentialBackoff -runBlock {
    [string]$DismExitCode = (Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Set-ReservedStorageState -ErrorAction Stop /State:Disabled" -Wait -Passthru -NoNewWindow).ExitCode
        if ($DismExitCode -ne 0) {
            throw "DISM command failed with exit code $DismExitCode"
        }
        Write-Output "Reserved Storage has been disabled." "INFO"
    } -onFailureBlock $OnFailureBlock -ignoreFailure $IgnoreFailure
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}

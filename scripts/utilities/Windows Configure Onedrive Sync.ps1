#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Configure Onedrive Sync

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Configures OneDrive sync settings for top level user folders.
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)][bool] $EnableDocumentsSync = $true,
    [Parameter(Mandatory = $false)][bool] $EnablePicturesSync = $true,
    [Parameter(Mandatory = $false)][bool] $EnableDesktopSync = $false
)
Set-StrictMode -Version Latest
function ConfigureOnedriveSync($EnableDocumentsSync, $EnablePicturesSync, $EnableDesktopSync) {
    try {
    $RegistryParams = @(
            @{ Key = 'Documents'; Value = if ($EnableDocumentsSync) { 1 } else { 0 } },
            @{ Key = 'Desktop'; Value = if ($EnableDesktopSync) { 1 } else { 0 } },
            @{ Key = 'Pictures'; Value = if ($EnablePicturesSync) { 1 } else { 0 } }
        )
    $RegistryParams | ForEach-Object {
    $RegistryKey = $_.Key
    $RegistryValue = $_.Value
            Write-Output " === Setting registry value: HKLM\SOFTWARE\Policies\Microsoft\OneDrive\KFMSilentOptIn$RegistryKey = $RegistryValue"
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"/v "KFMSilentOptIn$RegistryKey"/t REG_DWORD /d $RegistryValue /f

} catch {
        Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
    }
}
if (( -not(Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    ConfigureOnedriveSync -enableDocumentsSync $EnableDocumentsSync -enablePicturesSync $EnablePicturesSync -enableDesktopSync $EnableDesktopSync`n}

<#
.SYNOPSIS
    Add Windows Defender exclusions

.DESCRIPTION
    Add Windows Defender exclusion that can access user local environment variables.
    Related: https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/configure-extension-file-exclusions-microsoft-defender-antivirus?view=o365-worldwide#system-environment-variables
    Sample Bicep snippet for adding the task via Dev Box Image Templates:
    {
        Task: 'add-defender-exclusions'
        Parameters: {
            DirsToExclude: [
                '%TEMP%\\CloudStore'
                '%TEMP%\\NuGetScratch'
                '%TEMP%\\MSBuildTemp%USERNAME%'
            ]
    }
#>
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][PSObject] $TaskParams
)
Set-StrictMode -Version Latest
try {
    foreach ($dir in $TaskParams.DirsToExclude) {
        $expandedDir = [Environment]::ExpandEnvironmentVariables($dir)
        Add-MpPreference -ExclusionPath $expandedDir
        Write-Host "Added Windows Defender exclusion for $expandedDir"
    }
} catch {
    Write-Host "[WARN] Unhandled exception (will be ignored):" -ForegroundColor Yellow
    Write-Information -Object $_
    Write-Information -Object $_.ScriptStackTrace
}


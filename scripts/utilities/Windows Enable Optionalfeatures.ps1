#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Enable Optionalfeatures

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [ValidateNotNullOrEmpty()]
    [string] $FeatureName
)
Set-StrictMode -Version Latest;
    $VerbosePreference = 'Continue'
Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart -All
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

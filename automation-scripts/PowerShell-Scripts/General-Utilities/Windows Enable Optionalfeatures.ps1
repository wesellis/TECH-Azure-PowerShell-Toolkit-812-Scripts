<#
.SYNOPSIS
    Windows Enable Optionalfeatures

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $FeatureName
)
#region Functions
Set-StrictMode -Version Latest;
$VerbosePreference = 'Continue'
Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart -All
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


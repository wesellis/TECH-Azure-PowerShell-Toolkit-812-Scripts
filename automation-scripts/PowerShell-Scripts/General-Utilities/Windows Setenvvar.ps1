<#
.SYNOPSIS
    Windows Setenvvar

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
    $Variable,
    $Value,
$PrintValue = " true"
)
#region Functions
Set-StrictMode -Version Latest
Write-Host $(if ($PrintValue -eq " true" ) { "Setting variable $Variable with value $Value" } else { "Setting variable $Variable" })
[Environment]::SetEnvironmentVariable(" $Variable" , "$Value" , "Machine" )
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


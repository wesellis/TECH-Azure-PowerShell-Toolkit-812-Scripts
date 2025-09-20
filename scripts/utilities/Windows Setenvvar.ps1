#Requires -Version 7.0

<#`n.SYNOPSIS
    Windows Setenvvar

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
    [Parameter()]
    $Variable,
    [Parameter()]
    $Value,
    [Parameter()]
    $PrintValue = " true"
)
#region Functions-Set-StrictMode -Version Latest
Write-Host $(if ($PrintValue -eq " true" ) { "Setting variable $Variable with value $Value" } else { "Setting variable $Variable" })
[Environment]::SetEnvironmentVariable(" $Variable" , "$Value" , "Machine" )
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}



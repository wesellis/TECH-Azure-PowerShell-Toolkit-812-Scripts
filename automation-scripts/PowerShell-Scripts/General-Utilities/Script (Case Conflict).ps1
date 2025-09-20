<#
.SYNOPSIS
    Script (Case Conflict)

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
    1.0
    Requires appropriate permissions and modules
#>
try {
    # Main script execution

    Wes Ellis (wes@wesellis.com)
    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
  [bool] $myBool,
  [int] $myInt,
  [string] $myString,
  [Object[]]$myArray,
  [Object]$myObject
)
Write-Output " myBool: $myBool"
Write-Output " myInt: $myInt"
Write-Output " myString: $myString"
Write-Output " myArray: $myArray"
Write-Output " myObject: $myObject"
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['myBool'] = $myBool
$DeploymentScriptOutputs['myInt'] = $myInt
$DeploymentScriptOutputs['myString'] = $myString
$DeploymentScriptOutputs['myArray'] = $myArray
$DeploymentScriptOutputs['myObject'] = $myObject
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n
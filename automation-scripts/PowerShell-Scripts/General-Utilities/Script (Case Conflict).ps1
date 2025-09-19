#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Script (Case Conflict)

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Script (Case Conflict)
try {
    # Main script execution
.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
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

#region Functions

Write-Output " myBool: $myBool"
Write-Output " myInt: $myInt"
Write-Output " myString: $myString"
Write-Output " myArray: $myArray"
Write-Output " myObject: $myObject"
; 
$WEDeploymentScriptOutputs = @{}
$WEDeploymentScriptOutputs['myBool'] = $myBool
$WEDeploymentScriptOutputs['myInt'] = $myInt
$WEDeploymentScriptOutputs['myString'] = $myString
$WEDeploymentScriptOutputs['myArray'] = $myArray
$WEDeploymentScriptOutputs['myObject'] = $myObject


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

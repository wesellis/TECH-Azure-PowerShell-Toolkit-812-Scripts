#Requires -Version 7.4

<#`n.SYNOPSIS
    Script (Case Conflict)

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
    1.0
    Requires appropriate permissions and modules
try {

    Wes Ellis (wes@wesellis.com)
    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
  [bool] $MyBool,
  [int] $MyInt,
  [string] $MyString,
  [Object[]]$MyArray,
  [Object]$MyObject
)
Write-Output " myBool: $MyBool"
Write-Output " myInt: $MyInt"
Write-Output " myString: $MyString"
Write-Output " myArray: $MyArray"
Write-Output " myObject: $MyObject"
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['myBool'] = $MyBool
    $DeploymentScriptOutputs['myInt'] = $MyInt
    $DeploymentScriptOutputs['myString'] = $MyString
    $DeploymentScriptOutputs['myArray'] = $MyArray
    $DeploymentScriptOutputs['myObject'] = $MyObject
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

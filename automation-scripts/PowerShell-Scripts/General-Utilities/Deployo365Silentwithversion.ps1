<#
.SYNOPSIS
    Deployo365Silentwithversion

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param([Parameter()][string]$OfficeVersion = "Office2016" )
Process {
 $scriptPath = " ."
 if ($PSScriptRoot) {
   $scriptPath = $PSScriptRoot
 } else {
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
 }
. $scriptPath\Generate-ODTConfigurationXML.ps1
. $scriptPath\Edit-OfficeConfigurationFile.ps1
. $scriptPath\Install-OfficeClickToRun.ps1
$targetFilePath = " $env:temp\configuration.xml"
Generate-ODTConfigurationXml -Languages AllInUseLanguages -TargetFilePath $targetFilePath | Set-ODTAdd -Version $NULL | Set-ODTDisplay -AcceptEULA $true -Level None | Install-OfficeClickToRun -OfficeVersion $OfficeVersion
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n
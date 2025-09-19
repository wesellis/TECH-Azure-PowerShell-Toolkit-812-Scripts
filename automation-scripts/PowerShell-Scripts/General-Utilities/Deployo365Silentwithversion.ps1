#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Deployo365Silentwithversion

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
    We Enhanced Deployo365Silentwithversion

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param([Parameter(Mandatory=$false)][string]$WEOfficeVersion = " Office2016" )

Process {
 $scriptPath = " ."

 if ($WEPSScriptRoot) {
   $scriptPath = $WEPSScriptRoot
 } else {
  ;  $scriptPath = split-path -parent $WEMyInvocation.MyCommand.Definition
 }


. $scriptPath\Generate-ODTConfigurationXML.ps1
. $scriptPath\Edit-OfficeConfigurationFile.ps1
. $scriptPath\Install-OfficeClickToRun.ps1
; 
$targetFilePath = " $env:temp\configuration.xml"





Generate-ODTConfigurationXml -Languages AllInUseLanguages -TargetFilePath $targetFilePath | Set-ODTAdd -Version $WENULL | Set-ODTDisplay -AcceptEULA $true -Level None | Install-OfficeClickToRun -OfficeVersion $WEOfficeVersion


}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

#Requires -Version 7.4

<#
.SYNOPSIS
    Deploy Office 365 Silent with Version

.DESCRIPTION
    Azure automation script for silent Office 365 deployment with version selection
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER OfficeVersion
    Office version to deploy (default: Office2016)

.EXAMPLE
    .\Deployo365Silentwithversion.ps1 -OfficeVersion "Office2019"

.NOTES
    Performs silent Office 365 deployment
    Requires Office Deployment Tool (ODT) scripts
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OfficeVersion = "Office2016"
)

$ErrorActionPreference = "Stop"

try {
    $ScriptPath = "."
    if ($PSScriptRoot) {
        $ScriptPath = $PSScriptRoot
    } else {
        $ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    }

    # Import required ODT scripts
    . $ScriptPath\Generate-ODTConfigurationXML.ps1
    . $ScriptPath\Edit-OfficeConfigurationFile.ps1
    . $ScriptPath\Install-OfficeClickToRun.ps1

    $TargetFilePath = "$env:temp\configuration.xml"

    # Generate configuration and install Office
    Generate-ODTConfigurationXml -Languages AllInUseLanguages -TargetFilePath $TargetFilePath |
        Set-ODTAdd -Version $NULL |
        Set-ODTDisplay -AcceptEULA $true -Level None |
        Install-OfficeClickToRun -OfficeVersion $OfficeVersion

    Write-Output "Office 365 deployment completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
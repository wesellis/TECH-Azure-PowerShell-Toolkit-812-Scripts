#Requires -Version 7.4

<#
.SYNOPSIS
    Gen Templateparameters - Generate Azure Resource Manager Template Parameters

.DESCRIPTION
    Azure automation script that processes parameter files containing GEN values and GET-PREREQ values.
    This script will process the parameter files that contain GEN values and GET-PREREQ values.
    The configuration for GEN values can come from a location config.json file or a url.
    The GET-PREREQ values come from a parameter file written by the prereq step in the deployment and written to the location specified by the prereqOutputsFileName param.

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER ConfigUri
    URI or path to the configuration file (required)

.PARAMETER PrereqOutputsFileName
    Path to the prerequisite outputs file

.PARAMETER TemplateParametersFile
    Path to the template parameters file (default: .\azuredeploy.parameters.json)

.PARAMETER NewTemplateParametersFile
    Path for the new template parameters file (default: .\azuredeploy.parameters.new.json)

.EXAMPLE
    PS C:\> .\Gen_Templateparameters.ps1 -ConfigUri "https://example.com/config.json" -PrereqOutputsFileName "prereq-outputs.json"
    Processes template parameters with configuration from URL

.INPUTS
    Configuration files and parameter settings

.OUTPUTS
    Generated template parameter file

.NOTES
    This script replaces GEN-* and GET-PREREQ-* placeholders in ARM template parameter files
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigUri,

    [Parameter()]
    [string]$PrereqOutputsFileName,

    [Parameter()]
    [string]$TemplateParametersFile = '.\azuredeploy.parameters.json',

    [Parameter()]
    [string]$NewTemplateParametersFile = '.\azuredeploy.parameters.new.json'
)

$ErrorActionPreference = "Stop"

try {
    # Get configuration
    if ($ConfigUri.StartsWith('http')) {
        $config = (Invoke-WebRequest $ConfigUri).Content | ConvertFrom-Json -Depth 30
    }
    else {
        $config = Get-Content -Path $ConfigUri -Raw | ConvertFrom-Json -Depth 30
    }

    # Get prerequisite configuration if available
    if ($PrereqOutputsFileName) {
        if (Test-Path $PrereqOutputsFileName) {
            $PreReqConfig = Get-Content -Path $PrereqOutputsFileName -Raw | ConvertFrom-Json -Depth 30
            Write-Output ($PreReqConfig | Out-String)
        }
    }

    # Find template parameters file
    $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
    Write-Output "Searching for parameter file: $TemplateParametersFile"

    if (!(Test-Path $TemplateParametersFile)) {
        if ($TemplateParametersFile -like "*\prereqs\*") {
            $DefaultParamFile = "\prereq.azuredeploy.parameters.json"
        }
        else {
            $DefaultParamFile = "\azuredeploy.parameters.json"
        }
        $TemplateParametersFile = (Split-Path $TemplateParametersFile) + $DefaultParamFile
        Write-Output "Param file not found, using: $TemplateParametersFile"
    }

    # Read template content
    $txt = Get-Content -ErrorAction Stop $TemplateParametersFile -Raw

    # Replace GEN tokens with config values
    foreach ($c in $config.psobject.properties) {
        $token = "`"GEN-$($c.name)`""
        $txt = $txt.Replace($token, $($c.value | ConvertTo-Json -Depth 30))
    }

    # Replace GET-PREREQ tokens with prereq values
    if ($PreReqConfig) {
        foreach ($p in $PreReqConfig.psobject.properties) {
            $token = "`"GET-PREREQ-$($p.name)`""
            $txt = $txt.Replace($token, $($p.value.value | ConvertTo-Json -Depth 30))
        }
    }

    # Replace GEN-GUID tokens
    While ($txt.Contains("`"GEN-GUID`"")) {
        $v = New-Guid -ErrorAction Stop
        [regex]$r = "GEN-GUID"
        $txt = $r.Replace($txt, $v, 1)
    }

    # Replace GEN-PASSWORD tokens
    While ($txt.Contains("`"GEN-PASSWORD`"")) {
        $v = "cI#" + (New-Guid).ToString().Replace("-", "").Substring(0, 17)
        [regex]$r = "`"GEN-PASSWORD`""
        $txt = $r.Replace($txt, "`"$v`"", 1)
    }

    # Replace GEN-PASSWORD-AMP tokens
    While ($txt.Contains("`"GEN-PASSWORD-AMP`"")) {
        $v = "cI&" + (New-Guid).ToString().Replace("-", "").Substring(0, 17)
        [regex]$r = "`"GEN-PASSWORD-AMP`""
        $txt = $r.Replace($txt, "`"$v`"", 1)
    }

    # Replace GEN-UNIQUE tokens
    While ($txt.Contains("`"GEN-UNIQUE`"")) {
        $v = "ci" + (New-Guid).ToString().Replace("-", "").ToString().Substring(0, 16)
        [regex]$r = "`"GEN-UNIQUE`""
        $txt = $r.Replace($txt, "`"$v`"", 1)
    }

    # Replace GEN-UNIQUE-# tokens
    While ($txt.Contains("`"GEN-UNIQUE-")) {
        $NumStart = $txt.IndexOf("`"GEN-UNIQUE-") + 12
        $NumEnd = $txt.IndexOf("`"", $NumStart)
        $l = $txt.Substring($NumStart, $NumEnd - $NumStart)
        $i = [int]::parse($l) - 2
        if ($i -gt 24) { $i = 24 } elseif ($i -lt 1) { $i = 1 }
        Write-Output "length = $i"
        $v = "ci" + (New-Guid).ToString().Replace("-", "").ToString().Substring(0, $i)
        [regex]$r = "GEN-UNIQUE-$l"
        $txt = $r.Replace($txt, $v, 1)
    }

    Write-Output $txt
    Write-Output "Writing file: $NewTemplateParametersFile"
    $txt | Out-File -FilePath $NewTemplateParametersFile
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
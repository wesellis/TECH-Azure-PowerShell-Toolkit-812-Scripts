<#
.SYNOPSIS
    We Enhanced Gen Templateparameters

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
This script will process the parameter files than contain GEN values and GET-PREREQ values.
The configuration for GEN values can come from a location config.json file or a url.
The GET-PREREQ values come from a parameter file written by the prereq step in the deployment and written to the location specified by the prereqOutputsFileName param


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string][Parameter(mandatory = $true)] $configUri,
    [string] $prereqOutputsFileName,
    [string] $WETemplateParametersFile = '.\azuredeploy.parameters.json',
    [string] $WENewTemplateParametersFile = '.\azuredeploy.parameters.new.json'
)

if ($configUri.StartsWith('http')) {
    #url
    $config = (Invoke-WebRequest "$configUri" ).Content | ConvertFrom-Json  -Depth 30
}
else {
    #Local File
    $config = Get-Content -Path "$configUri" -Raw | ConvertFrom-Json  -Depth 30
}



if ($prereqOutputsFileName) { #Test-Path doesn't work on an empty string
    if (Test-Path $prereqOutputsFileName) {
        #prereqs have to come from a file due to the complexity of getting JSON into a pipeline var
        $WEPreReqConfig = Get-Content -Path $prereqOutputsFileName -Raw | ConvertFrom-Json -Depth 30
        Write-Output ($WEPreReqConfig | Out-String)
    }
}


$WETemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WETemplateParametersFile))
Write-Output " Searching for parameter file: $WETemplateParametersFile"

if (!(Test-Path $WETemplateParametersFile)) {
    # if the requested file has \prereqs\ in the path the default filename is different
    if($WETemplateParametersFile -like " *\prereqs\*"){
        $defaultParamFile = " \prereq.azuredeploy.parameters.json"
    }else{
        $defaultParamFile = " \azuredeploy.parameters.json"
    }
    $WETemplateParametersFile = (Split-Path $WETemplateParametersFile) + $defaultParamFile
    Write-Output " Param file not found, using: $WETemplateParametersFile"
}

$txt = Get-Content $WETemplateParametersFile -Raw




foreach($c in $config.psobject.properties){
    $token = " `"GEN-$($c.name)`""
    $txt = $txt.Replace($token, $($c.value | ConvertTo-Json -Depth 30))
}


foreach($p in $WEPreReqConfig.psobject.properties){
    $token = " `"GET-PREREQ-$($p.name)`""
    $txt = $txt.Replace($token, $($p.value.value | ConvertTo-Json -Depth 30)) #TODO - this does not work with single element arrays - it's a pwsh problem, see: https://github.com/Azure/azure-quickstart-templates/tree/master/demos/backup-policies-report
}



While($txt.Contains(" `"GEN-GUID`"" )){
    $v = New-Guid
    [regex]$r = "GEN-GUID"
    $txt = $r.Replace($txt, $v, 1)
}

While($txt.Contains(" `"GEN-PASSWORD`"" )){
    $v = "cI#" + (New-Guid).ToString().Replace(" -", "" ).Substring(0, 17)
    [regex]$r = "`" GEN-PASSWORD`""
    $txt = $r.Replace($txt, " `"$v`"" , 1)
}

While($txt.Contains("`" GEN-PASSWORD-AMP`"" )){
    $v = "cI&" + (New-Guid).ToString().Replace(" -", "" ).Substring(0, 17)
    [regex]$r = "`" GEN-PASSWORD-AMP`""
    $txt = $r.Replace($txt, " `"$v`"" , 1)
}

While($txt.Contains("`" GEN-UNIQUE`"" )){
    $v = "ci" + (New-Guid).ToString().Replace(" -", "" ).ToString().Substring(0, 16)
    [regex]$r = "`" GEN-UNIQUE`""
    $txt = $r.Replace($txt, " `"$v`"" , 1) # replace and restore quotes so as not to remove the GEN-UNIQUE-* values
}

While($txt.Contains("`" GEN-UNIQUE-")){
    $numStart = $txt.IndexOf(" `"GEN-UNIQUE-" ) + 12
    $numEnd = $txt.IndexOf("`"" , $numStart)
    $l = $txt.Substring($numStart, $numEnd-$numStart)
    $i = [int]::parse($l) - 2 # subtract 2 since 'ci' is prepended
    if($i -gt 24){ $i = 24 } elseif($i -lt 1){ $i = 1}
    Write-Output "length = $i"
    $v = " ci" + (New-Guid).ToString().Replace(" -", "" ).ToString().Substring(0,  $i)
    [regex]$r = "GEN-UNIQUE-$l"
   ;  $txt = $r.Replace($txt, $v, 1)
}

Write-Output $txt

Write-Output " Writing file: $WENewTemplateParametersFile"
$txt | Out-File -FilePath $WENewTemplateParametersFile


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

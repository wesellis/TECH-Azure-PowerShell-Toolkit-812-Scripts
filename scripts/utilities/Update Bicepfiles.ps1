#Requires -Version 7.4

<#`n.SYNOPSIS
    Update Bicepfiles

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$BicepSamples = Get-ChildItem -Path main.bicep -Recurse
ForEach($s in $BicepSamples){
    if($s.FullName -notlike "*\azure-quickstart-templates\test\*" ){
        bicep build $s.FullName --outfile " $($s.DirectoryName)/azuredeploy.json"
    }
`n}

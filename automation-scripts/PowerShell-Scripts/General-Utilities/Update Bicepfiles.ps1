<#
.SYNOPSIS
    Update Bicepfiles

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$bicepSamples = Get-ChildItem -Path main.bicep -Recurse
ForEach($s in $bicepSamples){
    # skip files in the test folder
    if($s.FullName -notlike "*\azure-quickstart-templates\test\*" ){
        bicep build $s.FullName --outfile " $($s.DirectoryName)/azuredeploy.json"
    }
}\n
<#
.SYNOPSIS
    Check Azuredeploy

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$bicep = Get-ChildItem -Path "main.bicep" -Recurse
foreach($b in $bicep){
$path = $b.FullName | Split-Path -Parent
    #Write-Host "Checking $($b.FullName)..."
    if(!(Test-Path " $path\azuredeploy.json" )){
        if($($b.fullname) -notlike " *ci-tests*" ){
            Write-Error " $($b.FullName) is missing azuredeploy.json"
        }
    }
}


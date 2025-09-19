#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Check Azuredeploy

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
    We Enhanced Check Azuredeploy

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$bicep = Get-ChildItem -Path "main.bicep" -Recurse

foreach($b in $bicep){
   ;  $path = $b.FullName | Split-Path -Parent
    #Write-WELog " Checking $($b.FullName)..." " INFO"
    if(!(Test-Path " $path\azuredeploy.json" )){
        if($($b.fullname) -notlike " *ci-tests*" ){
            Write-Error " $($b.FullName) is missing azuredeploy.json"
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

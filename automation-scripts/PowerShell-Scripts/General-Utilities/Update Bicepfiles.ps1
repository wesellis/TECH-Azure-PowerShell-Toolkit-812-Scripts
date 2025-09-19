#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Update Bicepfiles

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
    We Enhanced Update Bicepfiles

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$bicepSamples = Get-ChildItem -Path main.bicep -Recurse

ForEach($s in $bicepSamples){
    # skip files in the test folder
    if($s.FullName -notlike "*\azure-quickstart-templates\test\*" ){
        bicep build $s.FullName --outfile " $($s.DirectoryName)/azuredeploy.json"
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Check Duplicatefoldername

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
    We Enhanced Check Duplicatefoldername

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

    This script will check to see if there any other sample folders with the same name.
    The folder name is used for the urlFragement for doc samples and if there are dupes ingestion will fail.
    We use the folder name (and not the full path)
try {
    # Main script execution
to have more user friendly urls



[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $sampleFolder = $WEENV:SAMPLE_FOLDER,
    $sampleName = $WEENV:SAMPLE_NAME
)

#region Functions

if($WESampleName.StartsWith('modules')){
   # for modules we use version numbers, e.g. 0.9 so will have dupes, the the urlFragment will be the full path for a module and not an issue
}else{
   ;  $fragment = $WESampleName.Split('\')[-1] # if the filesystem uses forward slashes, this won't work, which is true of other scripts as well
}
; 
$d = Get-ChildItem -Directory -Recurse -filter $fragment

Write-Information $d

if($d.count -gt 1){ # there should be at least one since this sample should be found
    Write-WELog " Duplicate folder names found:" " INFO" -ForegroundColor Yellow
    Write-Information $d
    Write-WELog " ##vso[task.setvariable variable=duplicate.folderName]$true" " INFO"
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

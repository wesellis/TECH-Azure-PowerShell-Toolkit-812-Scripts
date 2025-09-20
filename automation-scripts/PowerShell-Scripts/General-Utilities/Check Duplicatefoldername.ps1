<#
.SYNOPSIS
    Check Duplicatefoldername

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    This script will check to see if there any other sample folders with the same name.
    The folder name is used for the urlFragement for doc samples and if there are dupes ingestion will fail.
    We use the folder name (and not the full path)
try {
    # Main script execution
to have more user friendly urls
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $sampleFolder = $ENV:SAMPLE_FOLDER,
    $sampleName = $ENV:SAMPLE_NAME
)
if($SampleName.StartsWith('modules')){
   # for modules we use version numbers, e.g. 0.9 so will have dupes, the the urlFragment will be the full path for a module and not an issue
}else{
$fragment = $SampleName.Split('\')[-1] # if the filesystem uses forward slashes, this won't work, which is true of other scripts as well
}
$d = Get-ChildItem -Directory -Recurse -filter $fragment
Write-Host $d
if($d.count -gt 1){ # there should be at least one since this sample should be found
    Write-Host "Duplicate folder names found:" -ForegroundColor Yellow
    Write-Host $d
    Write-Host " ##vso[task.setvariable variable=duplicate.folderName]$true"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


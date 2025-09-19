#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Get Samplefolder Ci

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
    We Enhanced Get Samplefolder Ci

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

When CI is triggered, get the commit from that trigger and run post processing

If the PR contains more than one sample the build must fail

If the PR does not contain changes to a sample folder ??? it will currently fail but we'll TODO this to pass the build in order to trigger a manual review



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $WEGitHubRepository = $WEENV:BUILD_REPOSITORY_NAME, # Azure/azure-quickstart-templates
    $WERepoRoot = $WEENV:BUILD_REPOSITORY_LOCALPATH, # D:\a\1\s
    $commit = $WEENV:BUILD_SOURCEVERSION
    
)

#region Functions



$uri = " https://api.github.com/repos/$($WEGitHubRepository)/commits/$($commit)"


$r = Invoke-Restmethod -method GET -uri " $uri"


$WEFolderArray = @()

foreach ($f in $r.files) {
    <# $f is tr.files tem #>
    Write-Output $f.filename
    if ($f.status -ne " removed" ) {
        # ignore deleted files, for example when a sample folder is renamed
        $WECurrentPath = Split-Path (Join-Path -path $WERepoRoot -ChildPath $f.filename)

        # find metadata.json
        while (!(Test-Path (Join-Path -path $WECurrentPath -ChildPath " metadata.json" )) -and $WECurrentPath -ne $WERepoRoot) {
            $WECurrentPath = Split-Path $WECurrentPath # if it's not in the same folder as this file, search it's parent
        }
        # if we made it to the root searching for metadata.json write the error
        If ($WECurrentPath -eq $WERepoRoot) {
            Write-Error " ### Error ### The scenario folder for $($f.filename) does not include a metadata.json file. Please add a metadata.json file to your scenario folder as part of the pull request."
        }
        Else {
            $WEFolderArray = $WEFolderArray + $currentpath
        }
    }
}


$WEFolderArray = @($WEFolderArray | Select-Object -Unique)
 
If ($WEFolderArray.count -gt 1) {
    Write-Error " ### Error ### The Pull request contains file changes from $($WEFolderArray.count) scenario folders. A pull request can only contain changes to files from a single scenario folder."
}

; 
$WEFolderString = $WEFolderArray[0]
Write-Output " Using sample folder: $WEFolderString"
Write-WELog " ##vso[task.setvariable variable=sample.folder]$WEFolderString" " INFO"


if (Test-Path -Path " $WEFolderString\main.bicep" ) {
    foreach($f in $r.files) {
        # Write-Output " File in PR: $f"
        if (($f.filename).EndsWith(" azuredeploy.json" ) -and ($f.status -ne " removed" )) {
            Write-Warning " $($f.filename) is included in the PR for a bicep sample"
            Write-WELog " ##vso[task.setvariable variable=json.with.bicep]$true" " INFO"
        }
    }
}
; 
$sampleName = $WEFolderString.Replace(" $WERepoRoot\" , "" ).Replace(" $WERepoRoot/" , "" )
Write-Output " Using sample name: $sampleName"
Write-WELog " ##vso[task.setvariable variable=sample.name]$sampleName" " INFO"





} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

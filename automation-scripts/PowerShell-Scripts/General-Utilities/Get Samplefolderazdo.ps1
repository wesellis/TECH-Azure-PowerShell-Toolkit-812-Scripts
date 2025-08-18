<#
.SYNOPSIS
    We Enhanced Get Samplefolderazdo

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
This script will find the sample folder for the PR - Tests are run on that folder only
If the PR contains more than one sample the build must fail
If the PR does not contain changes to a sample folder, it will currently fail but we'll TODO this to
pass the build in order to trigger a manual review


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    $WERepoRoot = $WEENV:BUILD_REPOSITORY_LOCALPATH,
    $WEBuildSourcesDirectory = $WEENV:BUILD_SOURCESDIRECTORY
)


$WEChangedFiles = git diff --name-status --diff-filter AMR origin/main # --name-only -- .

$WEChangedFiles


$WEFolderArray = @()

foreach($f in $WEChangedFiles) {

    $status = $f.split("`t" )[0] # we're filtering out deleted files in the git diff, so may not need this, check below is also commented out
    $fileName = $f.split("`t" )[1]

    Write-WELog "fileName: $fileName" " INFO"

    #if ($status -ne " D") {
        # ignore deleted files, for example when a sample folder is renamed
        $WECurrentPath = Split-Path (Join-Path -path $WERepoRoot -ChildPath $filename)
 
        # File in root of repo - TODO: should we block this?
        If ($WECurrentPath -eq $WERepoRoot) {
            Write-Error " ### Error ### The file $($_.filename) is in the root of the repository. A PR can only contain changes to files from a sample folder at this time."
        }
        Else {
            # find azuredeploy.json
            while (!(Test-Path (Join-Path -path $WECurrentPath -ChildPath " azuredeploy.json")) -and $WECurrentPath -ne $WERepoRoot) {
                $WECurrentPath = Split-Path $WECurrentPath # if it's not in the same folder as this file, search it's parent
            }
            # if we made it to the root searching for metadata.json write the error
            If ($WECurrentPath -eq $WERepoRoot) {
                Write-Error " ### Error ### The scenario folder for $fileName does not include an azuredeploy.json file."
            }
            Else {
                $WEFolderArray = $WEFolderArray + $currentpath
            }
        }
    #}
}


$WEFolderArray = @($WEFolderArray | Select-Object -Unique)

Write-WELog " `nDump folders:" " INFO"
$WEFolderArray | Out-String

If ($WEFolderArray.count -gt 1) {
    Write-Error " ### Error ### The Pull request contains file changes from $($WEFolderArray.count) scenario folders. A pull request can only contain changes to files from a single scenario folder."
}


$WEFolderString = $WEFolderArray[0]
Write-Output " Using sample folder: $WEFolderString"
Write-WELog " ##vso[task.setvariable variable=sample.folder]$WEFolderString" " INFO"
; 
$sampleName = $WEFolderString.Replace(" $WEBuildSourcesDirectory\", "" ).Replace("$WEBuildSourcesDirectory/" , "" )
Write-Output "Using sample name: $sampleName"
Write-WELog " ##vso[task.setvariable variable=sample.name]$sampleName" " INFO"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

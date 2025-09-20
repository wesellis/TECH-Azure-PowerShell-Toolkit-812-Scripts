<#
.SYNOPSIS
    Get Samplefolderazdo

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
This script will find the sample folder for the PR - Tests are run on that folder only
If the PR contains more than one sample the build must fail
If the PR does not contain changes to a sample folder, it will currently fail but we'll TODO this to
pass the build in order to trigger a manual review
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH,
    $BuildSourcesDirectory = $ENV:BUILD_SOURCESDIRECTORY
)
$ChangedFiles = git diff --name-status --diff-filter AMR origin/main # --name-only -- .
$ChangedFiles
$FolderArray = @()
foreach($f in $ChangedFiles) {
    $status = $f.split(" `t" )[0] # we're filtering out deleted files in the git diff, so may not need this, check below is also commented out
    $fileName = $f.split(" `t" )[1]
    Write-Host " fileName: $fileName"
    #if ($status -ne "D" ) {
        # ignore deleted files, for example when a sample folder is renamed
        $CurrentPath = Split-Path (Join-Path -path $RepoRoot -ChildPath $filename)
        # File in root of repo - TODO: should we block this?
        If ($CurrentPath -eq $RepoRoot) {
            Write-Error " ### Error ### The file $($_.filename) is in the root of the repository. A PR can only contain changes to files from a sample folder at this time."
        }
        Else {
            # find azuredeploy.json
            while (!(Test-Path (Join-Path -path $CurrentPath -ChildPath " azuredeploy.json" )) -and $CurrentPath -ne $RepoRoot) {
                $CurrentPath = Split-Path $CurrentPath # if it's not in the same folder as this file, search it's parent
            }
            # if we made it to the root searching for metadata.json write the error
            If ($CurrentPath -eq $RepoRoot) {
                Write-Error " ### Error ### The scenario folder for $fileName does not include an azuredeploy.json file."
            }
            Else {
                $FolderArray = $FolderArray + $currentpath
            }
        }
    #}
}
$FolderArray = @($FolderArray | Select-Object -Unique)
Write-Host " `nDump folders:"
$FolderArray | Out-String
If ($FolderArray.count -gt 1) {
    Write-Error " ### Error ### The Pull request contains file changes from $($FolderArray.count) scenario folders. A pull request can only contain changes to files from a single scenario folder."
}
$FolderString = $FolderArray[0]
Write-Output "Using sample folder: $FolderString"
Write-Host " ##vso[task.setvariable variable=sample.folder]$FolderString"
$sampleName = $FolderString.Replace(" $BuildSourcesDirectory\" , "" ).Replace(" $BuildSourcesDirectory/" , "" )
Write-Output "Using sample name: $sampleName"
Write-Host " ##vso[task.setvariable variable=sample.name]$sampleName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n
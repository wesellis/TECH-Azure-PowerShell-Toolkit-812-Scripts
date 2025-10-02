#Requires -Version 7.4

<#
.SYNOPSIS
    Get Sample Folder for Azure DevOps

.DESCRIPTION
    Azure automation script to find the sample folder for the PR
    Tests are run on that folder only
    If the PR contains more than one sample the build must fail
    If the PR does not contain changes to a sample folder, it will currently fail

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER RepoRoot
    Root path of the repository

.PARAMETER BuildSourcesDirectory
    Build sources directory path

.EXAMPLE
    .\Get_Samplefolderazdo.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    $RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH,

    [Parameter()]
    $BuildSourcesDirectory = $ENV:BUILD_SOURCESDIRECTORY
)

$ErrorActionPreference = "Stop"

try {
    $ChangedFiles = git diff --name-status --diff-filter AMR origin/main
    $ChangedFiles
    $FolderArray = @()
    foreach($f in $ChangedFiles) {
        $status = $f.split("`t")[0] # we're filtering out deleted files in the git diff, so may not need this, check below is also commented out
        $FileName = $f.split("`t")[1]
        Write-Output "fileName: $FileName"
        $CurrentPath = Split-Path (Join-Path -path $RepoRoot -ChildPath $filename)
        If ($CurrentPath -eq $RepoRoot) {
            Write-Error "### Error ### The file $($_.filename) is in the root of the repository. A PR can only contain changes to files from a sample folder at this time."
        }
        Else {
            while (!(Test-Path (Join-Path -path $CurrentPath -ChildPath "azuredeploy.json")) -and $CurrentPath -ne $RepoRoot) {
                $CurrentPath = Split-Path $CurrentPath
            }
            If ($CurrentPath -eq $RepoRoot) {
                Write-Error "### Error ### The scenario folder for $FileName does not include an azuredeploy.json file."
            }
            Else {
                $FolderArray = $FolderArray + $currentpath
            }
        }
    }
    $FolderArray = @($FolderArray | Select-Object -Unique)
    Write-Output "`nDump folders:"
    $FolderArray | Out-String
    If ($FolderArray.count -gt 1) {
        Write-Error "### Error ### The Pull request contains file changes from $($FolderArray.count) scenario folders. A pull request can only contain changes to files from a single scenario folder."
    }
    $FolderString = $FolderArray[0]
    Write-Output "Using sample folder: $FolderString"
    Write-Output "##vso[task.setvariable variable=sample.folder]$FolderString"
    $SampleName = $FolderString.Replace("$BuildSourcesDirectory\", "").Replace("$BuildSourcesDirectory/", "")
    Write-Output "Using sample name: $SampleName"
    Write-Output "##vso[task.setvariable variable=sample.name]$SampleName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

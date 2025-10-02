#Requires -Version 7.4

<#
.SYNOPSIS
    Get Sample folder for CI

.DESCRIPTION
    When CI is triggered, get the commit from that trigger and run post processing
    If the PR contains more than one sample the build must fail
    If the PR does not contain changes to a sample folder it will currently fail

    Author: Wesley Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER GitHubRepository
    GitHub repository name

.PARAMETER RepoRoot
    Root path of the repository

.PARAMETER commit
    Source version commit

.EXAMPLE
    .\Get_Samplefolder_Ci.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    $GitHubRepository = $ENV:BUILD_REPOSITORY_NAME,

    [Parameter()]
    $RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH,

    [Parameter()]
    $commit = $ENV:BUILD_SOURCEVERSION
)

$ErrorActionPreference = "Stop"

try {
    $uri = "https://api.github.com/repos/$($GitHubRepository)/commits/$($commit)"
    $r = Invoke-Restmethod -method GET -uri "$uri"
    $FolderArray = @()
    foreach ($f in $r.files) {
        # Process files item
        Write-Output $f.filename
        if ($f.status -ne "removed") {
            $CurrentPath = Split-Path (Join-Path -path $RepoRoot -ChildPath $f.filename)
            while (!(Test-Path (Join-Path -path $CurrentPath -ChildPath "metadata.json")) -and $CurrentPath -ne $RepoRoot) {
                $CurrentPath = Split-Path $CurrentPath
            }
            If ($CurrentPath -eq $RepoRoot) {
                Write-Error "### Error ### The scenario folder for $($f.filename) does not include a metadata.json file. Please add a metadata.json file to your scenario folder as part of the pull request."
            }
            Else {
                $FolderArray = $FolderArray + $currentpath
            }
        }
    }
    $FolderArray = @($FolderArray | Select-Object -Unique)
    If ($FolderArray.count -gt 1) {
        Write-Error "### Error ### The Pull request contains file changes from $($FolderArray.count) scenario folders. A pull request can only contain changes to files from a single scenario folder."
    }
    $FolderString = $FolderArray[0]
    Write-Output "Using sample folder: $FolderString"
    Write-Output "##vso[task.setvariable variable=sample.folder]$FolderString"
    if (Test-Path -Path "$FolderString\main.bicep") {
        foreach($f in $r.files) {
            if (($f.filename).EndsWith("azuredeploy.json") -and ($f.status -ne "removed")) {
                Write-Warning "$($f.filename) is included in the PR for a bicep sample"
                Write-Output "##vso[task.setvariable variable=json.with.bicep]$true"
            }
        }
    }
    $SampleName = $FolderString.Replace("$RepoRoot\", "").Replace("$RepoRoot/", "")
    Write-Output "Using sample name: $SampleName"
    Write-Output "##vso[task.setvariable variable=sample.name]$SampleName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

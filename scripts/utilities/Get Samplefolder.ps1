#Requires -Version 7.4

<#
.SYNOPSIS
    Get Sample Folder

.DESCRIPTION
    This script will find the sample folder for the PR - Tests are run on that folder only
    If the PR contains more than one sample the build must fail
    If the PR does not contain changes to a sample folder, it will currently fail

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER GitHubRepository
    GitHub repository name

.PARAMETER RepoRoot
    Root path of the repository

.EXAMPLE
    .\Get_Samplefolder.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    $GitHubRepository = $ENV:BUILD_REPOSITORY_NAME,

    [Parameter()]
    $RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH
)

$ErrorActionPreference = 'Stop'

try {
    if ($ENV:BUILD_REASON -eq "PullRequest") {
        $GitHubPRNumber = $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
    }
    elseif ($ENV:BUILD_REASON -eq "BatchedCI" -or $ENV:BUILD_REASON -eq "IndividualCI" -or $ENV:BUILD_REASON -eq "Manual") {
        # When a CI trigger is running, we get no information in the environment about what changed in the incoming PUSH (i.e. PR)
        # In the source version message - so even though this fragile, we can extract from there - the expected format is:
        # BUILD_SOURCEVERSIONMESSAGE = "Merge pull request #9 from bmoore-msft/bmoore-msft-patch-2"
        # 2021-04-18 - they changed the format of the message again, now its:
        # BUILD_SOURCEVERSIONMESSAGE = 101 event grid - Add bicep badge (
        try {
            $pr = $ENV:BUILD_SOURCEVERSIONMESSAGE
            $begin = 0
            $begin = $pr.IndexOf(" #") # look for the #
        }
        catch {
            Write-Error "An error occurred: $($_.Exception.Message)"
            throw
        }
        if ($begin -ge 0) {
            $end = $pr.IndexOf(" )", $begin) # look for the trailing space
            if($end -eq -1){
                $end = $pr.IndexOf(" ", $begin) # look for the trailing space
            }
            $GitHubPRNumber = $pr.Substring($begin + 1, $end - $begin - 1)
        }
        else {
            Write-Error "BuildSourceVersionMessage does not contain PR #: '$pr'"
        }
    }
    else {
        Write-Error "Unknown Build Reason ($ENV:BUILD_REASON) - cannot get PR number..."
    }
    $PRUri = "https://api.github.com/repos/$($GitHubRepository)/pulls/$($GitHubPRNumber)/files"
    $ChangedFile = Invoke-Restmethod "$PRUri"
    $FolderArray = @()
    $ChangedFile | ForEach-Object {
        Write-Output $_.blob_url
        if ($_.status -ne "removed") {
            $CurrentPath = Split-Path (Join-Path -path $RepoRoot -ChildPath $_.filename)
            If ($CurrentPath -eq $RepoRoot) {
                Write-Error "### Error ### The file $($_.filename) is in the root of the repository. A PR can only contain changes to files from a sample folder at this time."
            }
            Else {
                while (!(Test-Path (Join-Path -path $CurrentPath -ChildPath "metadata.json")) -and $CurrentPath -ne $RepoRoot) {
                    $CurrentPath = Split-Path $CurrentPath
                }
                If ($CurrentPath -eq $RepoRoot) {
                    Write-Error "### Error ### The scenario folder for $($_.filename) does not include a metadata.json file. Please add a metadata.json file to your scenario folder as part of the pull request."
                }
                Else {
                    $FolderArray = $FolderArray + $currentpath
                }
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
    if(Test-Path -Path "$FolderString\main.bicep"){
        $ChangedFile | ForEach-Object {
            if ($_.filename.EndsWith("azuredeploy.json") -and ($_.status -ne "removed")) {
                Write-Warning "$($_.filename) is included in the PR for a bicep sample"
                Write-Output "##vso[task.setvariable variable=json.with.bicep]$true"
            }
        }
    }
    $SampleName = $FolderString.Replace("$ENV:BUILD_SOURCESDIRECTORY\", "").Replace("$ENV:BUILD_SOURCESDIRECTORY/", "")
    Write-Output "Using sample name: $SampleName"
    Write-Output "##vso[task.setvariable variable=sample.name]$SampleName"
    Write-Output "Using github PR#: $GitHubPRNumber"
    Write-Output "##vso[task.setvariable variable=github.pr.number]$GitHubPRNumber"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
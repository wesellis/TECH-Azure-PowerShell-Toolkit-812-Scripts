<#
.SYNOPSIS
    Get Samplefolder

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
.SYNOPSIS
    We Enhanced Get Samplefolder

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
This script will find the sample folder for the PR - Tests are run on that folder only
If the PR contains more than one sample the build must fail
If the PR does not contain changes to a sample folder, it will currently fail but we'll TODO this to
pass the build in order to trigger a manual review






$WEGitHubRepository = $WEENV:BUILD_REPOSITORY_NAME
$WERepoRoot = $WEENV:BUILD_REPOSITORY_LOCALPATH

if ($WEENV:BUILD_REASON -eq "PullRequest" ) {
    $WEGitHubPRNumber = $WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
}
elseif ($WEENV:BUILD_REASON -eq " BatchedCI" -or $WEENV:BUILD_REASON -eq " IndividualCI" -or $WEENV:BUILD_REASON -eq " Manual" ) {
    <#
        When a CI trigger is running, we get no information in the environment about what changed in the incoming PUSH (i.e. PR# or files changed) except...
        In the source version message - so even though this fragile, we can extract from there - the expected format is:
        BUILD_SOURCEVERSIONMESSAGE = " Merge pull request #9 from bmoore-msft/bmoore-msft-patch-2…"
        2021-04-18 - they changed the format of the message again, now its:
        BUILD_SOURCEVERSIONMESSAGE = 101 event grid - Add bicep badge (#8997)
    #>
    try {
        $pr = $WEENV:BUILD_SOURCEVERSIONMESSAGE # TODO: sometimes AzDO is not setting the message, not clear why...
        $begin = 0
        $begin = $pr.IndexOf(" #" ) # look for the #
    }
    catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
    if ($begin -ge 0) {
        $end = $pr.IndexOf(" )" , $begin) # look for the trailing space
        if($end -eq -1){
            $end = $pr.IndexOf(" " , $begin) # look for the trailing space
        }
        $WEGitHubPRNumber = $pr.Substring($begin + 1, $end - $begin - 1)
    }
    else {
        Write-Error " BuildSourceVersionMessage does not contain PR #: `'$pr`'"
    }
}
else {
    Write-Error " Unknown Build Reason ($WEENV:BUILD_REASON) - cannot get PR number... "
}

$WEPRUri = " https://api.github.com/repos/$($WEGitHubRepository)/pulls/$($WEGitHubPRNumber)/files"


$WEChangedFile = Invoke-Restmethod " $WEPRUri"


$WEFolderArray = @()

$WEChangedFile | ForEach-Object {
    Write-Output $_.blob_url
    if ($_.status -ne " removed" ) {
        # ignore deleted files, for example when a sample folder is renamed
        $WECurrentPath = Split-Path (Join-Path -path $WERepoRoot -ChildPath $_.filename)
 
        # File in root of repo - TODO: should we block this?
        If ($WECurrentPath -eq $WERepoRoot) {
            Write-Error " ### Error ### The file $($_.filename) is in the root of the repository. A PR can only contain changes to files from a sample folder at this time."
        }
        Else {
            # find metadata.json
            while (!(Test-Path (Join-Path -path $WECurrentPath -ChildPath " metadata.json" )) -and $WECurrentPath -ne $WERepoRoot) {
                $WECurrentPath = Split-Path $WECurrentPath # if it's not in the same folder as this file, search it's parent
            }
            # if we made it to the root searching for metadata.json write the error
            If ($WECurrentPath -eq $WERepoRoot) {
                Write-Error " ### Error ### The scenario folder for $($_.filename) does not include a metadata.json file. Please add a metadata.json file to your scenario folder as part of the pull request."
            }
            Else {
                $WEFolderArray = $WEFolderArray + $currentpath
            }
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


if(Test-Path -Path " $WEFolderString\main.bicep" ){
    $WEChangedFile | ForEach-Object {
        # Write-Output " File in PR: $f"
        if ($_.filename.EndsWith(" azuredeploy.json" ) -and ($_.status -ne " removed" )) {
            Write-Warning " $($_.filename) is included in the PR for a bicep sample"
            Write-WELog " ##vso[task.setvariable variable=json.with.bicep]$true" " INFO"
        }
    }
}

; 
$sampleName = $WEFolderString.Replace(" $WEENV:BUILD_SOURCESDIRECTORY\" , "" ).Replace(" $WEENV:BUILD_SOURCESDIRECTORY/" , "" )
Write-Output " Using sample name: $sampleName"
Write-WELog " ##vso[task.setvariable variable=sample.name]$sampleName" " INFO"

Write-Output " Using github PR#: $WEGitHubPRNumber"
Write-WELog " ##vso[task.setvariable variable=github.pr.number]$WEGitHubPRNumber" " INFO"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
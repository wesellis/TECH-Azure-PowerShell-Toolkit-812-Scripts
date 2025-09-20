#Requires -Version 7.0
    Get Samplefolder Ci
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
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
    [Parameter()]
    $GitHubRepository = $ENV:BUILD_REPOSITORY_NAME, # Azure/azure-quickstart-templates
    $RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH, # D:\a\1\s
    $commit = $ENV:BUILD_SOURCEVERSION
)
$uri = "https://api.github.com/repos/$($GitHubRepository)/commits/$($commit)"
$r = Invoke-Restmethod -method GET -uri " $uri"
$FolderArray = @()
foreach ($f in $r.files) {
    <#
.SYNOPSIS
    PowerShell script
.DESCRIPTION
    PowerShell operation
    Author: Wes Ellis (wes@wesellis.com)
#>
$f is tr.files tem #>
    Write-Output $f.filename
    if ($f.status -ne " removed" ) {
        # ignore deleted files, for example when a sample folder is renamed
        $CurrentPath = Split-Path (Join-Path -path $RepoRoot -ChildPath $f.filename)
        # find metadata.json
        while (!(Test-Path (Join-Path -path $CurrentPath -ChildPath " metadata.json" )) -and $CurrentPath -ne $RepoRoot) {
            $CurrentPath = Split-Path $CurrentPath # if it's not in the same folder as this file, search it's parent
        }
        # if we made it to the root searching for metadata.json write the error
        If ($CurrentPath -eq $RepoRoot) {
            Write-Error " ### Error ### The scenario folder for $($f.filename) does not include a metadata.json file. Please add a metadata.json file to your scenario folder as part of the pull request."
        }
        Else {
            $FolderArray = $FolderArray + $currentpath
        }
    }
}
$FolderArray = @($FolderArray | Select-Object -Unique)
If ($FolderArray.count -gt 1) {
    Write-Error " ### Error ### The Pull request contains file changes from $($FolderArray.count) scenario folders. A pull request can only contain changes to files from a single scenario folder."
}
$FolderString = $FolderArray[0]
Write-Output "Using sample folder: $FolderString"
Write-Host " ##vso[task.setvariable variable=sample.folder]$FolderString"
if (Test-Path -Path " $FolderString\main.bicep" ) {
    foreach($f in $r.files) {
        # Write-Output "File in PR: $f"
        if (($f.filename).EndsWith(" azuredeploy.json" ) -and ($f.status -ne " removed" )) {
            Write-Warning " $($f.filename) is included in the PR for a bicep sample"
            Write-Host " ##vso[task.setvariable variable=json.with.bicep]$true"
        }
    }
}
$sampleName = $FolderString.Replace(" $RepoRoot\" , "" ).Replace(" $RepoRoot/" , "" )
Write-Output "Using sample name: $sampleName"
Write-Host " ##vso[task.setvariable variable=sample.name]$sampleName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n


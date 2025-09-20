#Requires -Version 7.0

<#`n.SYNOPSIS
    Get Githubprlabels

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
This script will get the labels on a PR - right now we look to see if the "bypass delete" label is set to preserve the RGs
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string]$GitHubRepository = $ENV:BUILD_REPOSITORY_NAME,
    [string]$GitHubPRNumber = $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER,
    [string]$RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH
)
if ($ENV:BUILD_REASON -eq "PullRequest" ) {
$PRUri = "https://api.github.com/repos/$($GitHubRepository)/pulls/$($GitHubPRNumber)"
$r = Invoke-Restmethod " $PRUri" -Verbose
    foreach ($l in $r.labels) {
        Write-Host "Found label = $($l.name)"
        if($l.name -eq " bypass delete" ){
            Write-Host "Setting bypass.delete env var = true..."
            Write-Host " ##vso[task.setvariable variable=bypass.delete]true"
        }
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

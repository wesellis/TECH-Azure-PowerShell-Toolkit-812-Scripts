<#
.SYNOPSIS
    We Enhanced Get Githubprlabels

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

This script will get the labels on a PR - right now we look to see if the "bypass delete" label is set to preserve the RGs



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string]$WEGitHubRepository = $WEENV:BUILD_REPOSITORY_NAME,
    [string]$WEGitHubPRNumber = $WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER,
    [string]$WERepoRoot = $WEENV:BUILD_REPOSITORY_LOCALPATH
)


if ($WEENV:BUILD_REASON -eq " PullRequest") {

    $WEPRUri = " https://api.github.com/repos/$($WEGitHubRepository)/pulls/$($WEGitHubPRNumber)"

   ;  $r = Invoke-Restmethod " $WEPRUri" -Verbose

    foreach ($l in $r.labels) {
        Write-WELog " Found label = $($l.name)" " INFO"
        if($l.name -eq " bypass delete"){
            Write-WELog " Setting bypass.delete env var = true..." " INFO"
            Write-WELog " ##vso[task.setvariable variable=bypass.delete]true" " INFO"
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

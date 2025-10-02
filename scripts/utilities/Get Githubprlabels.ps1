#Requires -Version 7.4

<#
.SYNOPSIS
    Get Githubprlabels - Retrieve GitHub Pull Request Labels

.DESCRIPTION
    Azure automation script that retrieves labels from GitHub Pull Requests.
    This script will get the labels on a PR - right now we look to see if the "bypass delete" label is set to preserve the RGs.
    This is typically used in Azure DevOps pipelines to control resource group cleanup behavior.

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER GitHubRepository
    GitHub repository name (defaults to BUILD_REPOSITORY_NAME environment variable)

.PARAMETER GitHubPRNumber
    GitHub Pull Request number (defaults to SYSTEM_PULLREQUEST_PULLREQUESTNUMBER environment variable)

.PARAMETER RepoRoot
    Repository root path (defaults to BUILD_REPOSITORY_LOCALPATH environment variable)

.EXAMPLE
    PS C:\> .\Get_Githubprlabels.ps1 -GitHubRepository "owner/repo" -GitHubPRNumber "123"
    Retrieves labels from the specified pull request

.INPUTS
    GitHub repository information and pull request details

.OUTPUTS
    Azure DevOps pipeline variables based on PR labels

.NOTES
    This script is designed to run in Azure DevOps pipelines
    Sets bypass.delete variable to true if "bypass delete" label is found
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$GitHubRepository = $ENV:BUILD_REPOSITORY_NAME,

    [Parameter()]
    [string]$GitHubPRNumber = $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER,

    [Parameter()]
    [string]$RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH
)

$ErrorActionPreference = "Stop"

try {
    if ($ENV:BUILD_REASON -eq "PullRequest") {
        if (-not $GitHubRepository -or -not $GitHubPRNumber) {
            Write-Warning "GitHub repository or PR number not provided. Cannot retrieve PR labels."
            return
        }

        Write-Output "Checking labels for PR #$GitHubPRNumber in repository $GitHubRepository"

        $PRUri = "https://api.github.com/repos/$GitHubRepository/pulls/$GitHubPRNumber"

        try {
            $response = Invoke-RestMethod $PRUri -Verbose

            foreach ($label in $response.labels) {
                Write-Output "Found label = $($label.name)"

                if ($label.name -eq "bypass delete") {
                    Write-Output "Setting bypass.delete env var = true..."
                    Write-Output "##vso[task.setvariable variable=bypass.delete]true"
                }
            }

            if (-not $response.labels -or $response.labels.Count -eq 0) {
                Write-Output "No labels found on this pull request."
            }
        }
        catch {
            Write-Warning "Failed to retrieve PR labels: $($_.Exception.Message)"
            Write-Output "This may be due to API rate limits or repository access permissions."
        }
    }
    else {
        Write-Output "Build reason is not 'PullRequest'. Current build reason: $($ENV:BUILD_REASON)"
        Write-Output "PR label checking is only performed for pull request builds."
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
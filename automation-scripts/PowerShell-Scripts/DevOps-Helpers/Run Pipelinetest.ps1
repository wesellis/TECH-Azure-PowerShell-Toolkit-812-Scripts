<#
.SYNOPSIS
    Run Pipelinetest

.DESCRIPTION
    Creates a set of test deployments by creating PRs for saved test deployment branches (that begin with keep/testdeployment/)
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
)
try {
$repoRoot = Resolve-Path "$PSScriptRoot/../.."
$testBranches = @()
$yesAll = $false
foreach ($shortBranch in $TestBranches) {
  write-warning $shortBranch
  $fullBranch = "keep/testdeployment/$shortBranch"
  write-warning $fullBranch
  $yes = $false
  if (!$yesAll) {
    $answer = Read-Host "Create a PR for $($fullBranch)? (Y/N/A)"
    if ($answer -eq 'Y') {
      $yes = $true
    }
    elseif ($answer -eq 'All' -or $answer -eq 'A') {
      $yes = $true
      $yesAll = $true
    }
  }
  else {
$yes = $true
  }
  if ($yes) {
    git stash
    git checkout master
    git pull
    git checkout $fullBranch
    git rebase master
    git push -f
$body = @"
DO NOT CHECK IN!
This is a test deployment for branch $fullBranch
" @
    gh pr create --head $fullBranch --title "Test: $shortBranch" --body $body --label "test deployment" --repo "Azure/azure-quickstart-templates" --draft
    git stash apply
  }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


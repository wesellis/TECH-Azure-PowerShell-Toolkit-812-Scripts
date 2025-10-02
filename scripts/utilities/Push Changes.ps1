#Requires -Version 7.4

<#
.SYNOPSIS
    Push Changes to Git Repository

.DESCRIPTION
    Azure automation script to commit and push changes to a Git repository.
    Typically used in CI/CD pipelines to update Azure quickstart templates.

.PARAMETER SampleFolder
    Folder containing the sample (defaults to environment variable SAMPLE_FOLDER)

.PARAMETER SampleName
    Name of the sample being updated (defaults to environment variable SAMPLE_NAME)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires Git to be installed and configured
    Used in Azure Quickstart Templates pipeline
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SampleFolder = $ENV:SAMPLE_FOLDER,

    [Parameter(Mandatory = $false)]
    [string]$SampleName = $ENV:SAMPLE_NAME
)

$ErrorActionPreference = "Stop"

try {
    # Get current Git status
    $GitStatus = git status 2>&1 | Out-String
    Write-Output "Found Git Status of:`n$GitStatus"

    # Show differences
    git diff

    # Check autocrlf setting
    $autocrlf = git config core.autocrlf
    Write-Output "Git autocrlf setting: $autocrlf"

    # Check if there are changes to commit
    if ($GitStatus -like "*Changes not staged for commit:*" -or
        $GitStatus -like "*Untracked files:*") {

        Write-Output "Found changes to commit"

        # Configure Git user
        git config --worktree user.email "azure-quickstart-templates@noreply.github.com"
        git config --worktree user.name "Azure Quickstarts Pipeline"

        Write-Output "Checking out master branch..."
        git checkout "master"

        Write-Output "Checking git status..."
        git status

        # Build commit message
        $msg = "Update for ($SampleName)"
        $files = @()

        if ($GitStatus -like "*azuredeploy.json*") {
            $files += "azuredeploy.json"
        }

        if ($GitStatus -like "*readme.md*" -or $GitStatus -like "*README.md*") {
            $files += "README.md"
        }

        if ($files.Count -gt 0) {
            $filesStr = $files -join " and "
            $msg = "Update $filesStr for ($SampleName) ***NO_CI***"
        }
        else {
            $msg = "Update files for ($SampleName) ***NO_CI***"
        }

        Write-Output "Committing changes with message: $msg"

        # Stage and commit changes
        git add -A -v
        git commit -v -a -m $msg

        Write-Output "Status after commit..."
        git status

        Write-Output "Pulling latest changes from origin..."
        git pull --no-edit origin "master"

        # Amend commit message to maintain single commit
        git commit --amend -m $msg

        Write-Output "Pushing changes to origin..."
        git push origin "master"

        Write-Output "Status after push..."
        git status

        Write-Output "Changes successfully pushed to repository"
    }
    else {
        Write-Output "No changes detected to commit"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"

    # Try to show git status for debugging
    try {
        $errorStatus = git status 2>&1 | Out-String
        Write-Error "Current git status: $errorStatus"
    }
    catch {
        Write-Error "Could not get git status"
    }

    throw
}

# Example usage:
# .\Push Changes.ps1 -SampleFolder "101-vm-simple-windows" -SampleName "Simple Windows VM"
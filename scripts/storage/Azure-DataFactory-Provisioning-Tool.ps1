#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$FactoryName,
    [string]$Location,
    [bool]$EnableGitIntegration = $false,
    [string]$GitRepoType = "FactoryGitHubConfiguration",
    [string]$GitAccountName,
    [string]$GitProjectName,
    [string]$GitRepositoryName,
    [string]$GitCollaborationBranch = "main"
)
Write-Output "Provisioning Data Factory: $FactoryName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Git Integration: $EnableGitIntegration"
if ($EnableGitIntegration -and $GitAccountName -and $GitRepositoryName) {
    Write-Output "Git Account: $GitAccountName"
    Write-Output "Git Repository: $GitRepositoryName"
    Write-Output "Collaboration Branch: $GitCollaborationBranch"
    $params = @{
        ResourceGroupName = $ResourceGroupName
        GitRepoType = $GitRepoType
        GitProjectName = $GitProjectName
        Location = $Location
        GitCollaborationBranch = $GitCollaborationBranch
        GitAccountName = $GitAccountName
        GitRepositoryName = $GitRepositoryName
        ErrorAction = "Stop"
        Name = $FactoryName
    }
    $DataFactory @params
} else {
    $params = @{
        ErrorAction = "Stop"
        ResourceGroupName = $ResourceGroupName
        Name = $FactoryName
        Location = $Location
    }
    $DataFactory @params
}
Write-Output "`nData Factory $FactoryName provisioned successfully"
Write-Output "Data Factory ID: $($DataFactory.DataFactoryId)"
Write-Output "Provisioning State: $($DataFactory.ProvisioningState)"
Write-Output "Created Time: $($DataFactory.CreateTime)"
if ($DataFactory.RepoConfiguration) {
    Write-Output "`nGit Configuration:"
    Write-Output "Type: $($DataFactory.RepoConfiguration.Type)"
    Write-Output "Account Name: $($DataFactory.RepoConfiguration.AccountName)"
    Write-Output "Repository Name: $($DataFactory.RepoConfiguration.RepositoryName)"
    Write-Output "Collaboration Branch: $($DataFactory.RepoConfiguration.CollaborationBranch)"
}
Write-Output "`nNext Steps:"
Write-Output "1. Create linked services for data sources"
Write-Output "2. Define datasets for input/output data"
Write-Output "3. Create pipelines for data workflows"
Write-Output "4. Set up triggers for pipeline execution"
Write-Output "5. Monitor pipeline runs in Azure Portal"
Write-Output "`nData Factory Access:"
Write-Output "Portal URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName"
Write-Output "`nData Factory provisioning completed at $(Get-Date)"




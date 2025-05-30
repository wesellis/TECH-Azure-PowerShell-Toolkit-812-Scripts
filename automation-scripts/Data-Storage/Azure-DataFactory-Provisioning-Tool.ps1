# ============================================================================
# Script Name: Azure Data Factory Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Data Factory for data integration and ETL workflows
# ============================================================================

param (
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

Write-Host "Provisioning Data Factory: $FactoryName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Git Integration: $EnableGitIntegration"

# Create the Data Factory
if ($EnableGitIntegration -and $GitAccountName -and $GitRepositoryName) {
    Write-Host "Git Account: $GitAccountName"
    Write-Host "Git Repository: $GitRepositoryName"
    Write-Host "Collaboration Branch: $GitCollaborationBranch"
    
    # Create Data Factory with Git integration
    $DataFactory = New-AzDataFactoryV2 `
        -ResourceGroupName $ResourceGroupName `
        -Name $FactoryName `
        -Location $Location `
        -GitAccountName $GitAccountName `
        -GitProjectName $GitProjectName `
        -GitRepositoryName $GitRepositoryName `
        -GitCollaborationBranch $GitCollaborationBranch `
        -GitRepoType $GitRepoType
} else {
    # Create Data Factory without Git integration
    $DataFactory = New-AzDataFactoryV2 `
        -ResourceGroupName $ResourceGroupName `
        -Name $FactoryName `
        -Location $Location
}

Write-Host "`nData Factory $FactoryName provisioned successfully"
Write-Host "Data Factory ID: $($DataFactory.DataFactoryId)"
Write-Host "Provisioning State: $($DataFactory.ProvisioningState)"
Write-Host "Created Time: $($DataFactory.CreateTime)"

if ($DataFactory.RepoConfiguration) {
    Write-Host "`nGit Configuration:"
    Write-Host "  Type: $($DataFactory.RepoConfiguration.Type)"
    Write-Host "  Account Name: $($DataFactory.RepoConfiguration.AccountName)"
    Write-Host "  Repository Name: $($DataFactory.RepoConfiguration.RepositoryName)"
    Write-Host "  Collaboration Branch: $($DataFactory.RepoConfiguration.CollaborationBranch)"
}

Write-Host "`nNext Steps:"
Write-Host "1. Create linked services for data sources"
Write-Host "2. Define datasets for input/output data"
Write-Host "3. Create pipelines for data workflows"
Write-Host "4. Set up triggers for pipeline execution"
Write-Host "5. Monitor pipeline runs in Azure Portal"

Write-Host "`nData Factory Access:"
Write-Host "Portal URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName"

Write-Host "`nData Factory provisioning completed at $(Get-Date)"

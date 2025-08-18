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

Write-Information "Provisioning Data Factory: $FactoryName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Git Integration: $EnableGitIntegration"

# Create the Data Factory
if ($EnableGitIntegration -and $GitAccountName -and $GitRepositoryName) {
    Write-Information "Git Account: $GitAccountName"
    Write-Information "Git Repository: $GitRepositoryName"
    Write-Information "Collaboration Branch: $GitCollaborationBranch"
    
    # Create Data Factory with Git integration
    $DataFactory = New-AzDataFactoryV2 -ErrorAction Stop `
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
    $DataFactory = New-AzDataFactoryV2 -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $FactoryName `
        -Location $Location
}

Write-Information "`nData Factory $FactoryName provisioned successfully"
Write-Information "Data Factory ID: $($DataFactory.DataFactoryId)"
Write-Information "Provisioning State: $($DataFactory.ProvisioningState)"
Write-Information "Created Time: $($DataFactory.CreateTime)"

if ($DataFactory.RepoConfiguration) {
    Write-Information "`nGit Configuration:"
    Write-Information "  Type: $($DataFactory.RepoConfiguration.Type)"
    Write-Information "  Account Name: $($DataFactory.RepoConfiguration.AccountName)"
    Write-Information "  Repository Name: $($DataFactory.RepoConfiguration.RepositoryName)"
    Write-Information "  Collaboration Branch: $($DataFactory.RepoConfiguration.CollaborationBranch)"
}

Write-Information "`nNext Steps:"
Write-Information "1. Create linked services for data sources"
Write-Information "2. Define datasets for input/output data"
Write-Information "3. Create pipelines for data workflows"
Write-Information "4. Set up triggers for pipeline execution"
Write-Information "5. Monitor pipeline runs in Azure Portal"

Write-Information "`nData Factory Access:"
Write-Information "Portal URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName"

Write-Information "`nData Factory provisioning completed at $(Get-Date)"

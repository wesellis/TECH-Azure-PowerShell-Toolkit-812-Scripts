#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Datafactory Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$FactoryName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [bool]$EnableGitIntegration = $false,
    [string]$GitRepoType = "FactoryGitHubConfiguration" ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GitAccountName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GitProjectName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GitRepositoryName,
    [string]$GitCollaborationBranch = " main"
)
Write-Output "Provisioning Data Factory: $FactoryName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output "Location: $Location" "INFO"
Write-Output "Git Integration: $EnableGitIntegration" "INFO"
if ($EnableGitIntegration -and $GitAccountName -and $GitRepositoryName) {
    Write-Output "Git Account: $GitAccountName" "INFO"
    Write-Output "Git Repository: $GitRepositoryName" "INFO"
    Write-Output "Collaboration Branch: $GitCollaborationBranch" "INFO"
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
   ; @params
} else {
    $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $FactoryName
       Location = $Location
   }
   ; @params
}
Write-Output " `nData Factory $FactoryName provisioned successfully" "INFO"
Write-Output "Data Factory ID: $($DataFactory.DataFactoryId)" "INFO"
Write-Output "Provisioning State: $($DataFactory.ProvisioningState)" "INFO"
Write-Output "Created Time: $($DataFactory.CreateTime)" "INFO"
if ($DataFactory.RepoConfiguration) {
    Write-Output " `nGit Configuration:" "INFO"
    Write-Output "Type: $($DataFactory.RepoConfiguration.Type)" "INFO"
    Write-Output "Account Name: $($DataFactory.RepoConfiguration.AccountName)" "INFO"
    Write-Output "Repository Name: $($DataFactory.RepoConfiguration.RepositoryName)" "INFO"
    Write-Output "Collaboration Branch: $($DataFactory.RepoConfiguration.CollaborationBranch)" "INFO"
}
Write-Output " `nNext Steps:" "INFO"
Write-Output " 1. Create linked services for data sources" "INFO"
Write-Output " 2. Define datasets for input/output data" "INFO"
Write-Output " 3. Create pipelines for data workflows" "INFO"
Write-Output " 4. Set up triggers for pipeline execution" "INFO"
Write-Output " 5. Monitor pipeline runs in Azure Portal" "INFO"
Write-Output " `nData Factory Access:" "INFO"
Write-Output "Portal URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName" "INFO"
Write-Output " `nData Factory provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}

#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Datafactory Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Provisioning Data Factory: $FactoryName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host "Location: $Location" "INFO"
Write-Host "Git Integration: $EnableGitIntegration" "INFO"
if ($EnableGitIntegration -and $GitAccountName -and $GitRepositoryName) {
    Write-Host "Git Account: $GitAccountName" "INFO"
    Write-Host "Git Repository: $GitRepositoryName" "INFO"
    Write-Host "Collaboration Branch: $GitCollaborationBranch" "INFO"
    # Create Data Factory with Git integration
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
    # Create Data Factory without Git integration
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $FactoryName
       Location = $Location
   }
   ; @params
}
Write-Host " `nData Factory $FactoryName provisioned successfully" "INFO"
Write-Host "Data Factory ID: $($DataFactory.DataFactoryId)" "INFO"
Write-Host "Provisioning State: $($DataFactory.ProvisioningState)" "INFO"
Write-Host "Created Time: $($DataFactory.CreateTime)" "INFO"
if ($DataFactory.RepoConfiguration) {
    Write-Host " `nGit Configuration:" "INFO"
    Write-Host "Type: $($DataFactory.RepoConfiguration.Type)" "INFO"
    Write-Host "Account Name: $($DataFactory.RepoConfiguration.AccountName)" "INFO"
    Write-Host "Repository Name: $($DataFactory.RepoConfiguration.RepositoryName)" "INFO"
    Write-Host "Collaboration Branch: $($DataFactory.RepoConfiguration.CollaborationBranch)" "INFO"
}
Write-Host " `nNext Steps:" "INFO"
Write-Host " 1. Create linked services for data sources" "INFO"
Write-Host " 2. Define datasets for input/output data" "INFO"
Write-Host " 3. Create pipelines for data workflows" "INFO"
Write-Host " 4. Set up triggers for pipeline execution" "INFO"
Write-Host " 5. Monitor pipeline runs in Azure Portal" "INFO"
Write-Host " `nData Factory Access:" "INFO"
Write-Host "Portal URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$ResourceGroupName/providers/Microsoft.DataFactory/factories/$FactoryName" "INFO"
Write-Host " `nData Factory provisioning completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

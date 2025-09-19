#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Datafactory Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Datafactory Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEFactoryName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [bool]$WEEnableGitIntegration = $false,
    [string]$WEGitRepoType = " FactoryGitHubConfiguration" ,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGitAccountName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGitProjectName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGitRepositoryName,
    [string]$WEGitCollaborationBranch = " main"
)

#region Functions

Write-WELog " Provisioning Data Factory: $WEFactoryName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Git Integration: $WEEnableGitIntegration" " INFO"


if ($WEEnableGitIntegration -and $WEGitAccountName -and $WEGitRepositoryName) {
    Write-WELog " Git Account: $WEGitAccountName" " INFO"
    Write-WELog " Git Repository: $WEGitRepositoryName" " INFO"
    Write-WELog " Collaboration Branch: $WEGitCollaborationBranch" " INFO"
    
    # Create Data Factory with Git integration
   $params = @{
       ResourceGroupName = $WEResourceGroupName
       GitRepoType = $WEGitRepoType
       GitProjectName = $WEGitProjectName
       Location = $WELocation
       GitCollaborationBranch = $WEGitCollaborationBranch
       GitAccountName = $WEGitAccountName
       GitRepositoryName = $WEGitRepositoryName
       ErrorAction = "Stop"
       Name = $WEFactoryName
   }
   ; @params
} else {
    # Create Data Factory without Git integration
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $WEResourceGroupName
       Name = $WEFactoryName
       Location = $WELocation
   }
   ; @params
}

Write-WELog " `nData Factory $WEFactoryName provisioned successfully" " INFO"
Write-WELog " Data Factory ID: $($WEDataFactory.DataFactoryId)" " INFO"
Write-WELog " Provisioning State: $($WEDataFactory.ProvisioningState)" " INFO"
Write-WELog " Created Time: $($WEDataFactory.CreateTime)" " INFO"

if ($WEDataFactory.RepoConfiguration) {
    Write-WELog " `nGit Configuration:" " INFO"
    Write-WELog "  Type: $($WEDataFactory.RepoConfiguration.Type)" " INFO"
    Write-WELog "  Account Name: $($WEDataFactory.RepoConfiguration.AccountName)" " INFO"
    Write-WELog "  Repository Name: $($WEDataFactory.RepoConfiguration.RepositoryName)" " INFO"
    Write-WELog "  Collaboration Branch: $($WEDataFactory.RepoConfiguration.CollaborationBranch)" " INFO"
}

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Create linked services for data sources" " INFO"
Write-WELog " 2. Define datasets for input/output data" " INFO"
Write-WELog " 3. Create pipelines for data workflows" " INFO"
Write-WELog " 4. Set up triggers for pipeline execution" " INFO"
Write-WELog " 5. Monitor pipeline runs in Azure Portal" " INFO"

Write-WELog " `nData Factory Access:" " INFO"
Write-WELog " Portal URL: https://adf.azure.com/home?factory=/subscriptions/{subscription-id}/resourceGroups/$WEResourceGroupName/providers/Microsoft.DataFactory/factories/$WEFactoryName" " INFO"

Write-WELog " `nData Factory provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion

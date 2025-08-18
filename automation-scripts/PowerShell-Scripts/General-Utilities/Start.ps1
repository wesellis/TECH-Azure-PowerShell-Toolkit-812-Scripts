<#
.SYNOPSIS
    We Enhanced Start

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

$userPrincipalName = Read-Host "Please enter user principal name e.g. alias@xxx.com"
$resourceGroupName = Read-Host " Please enter resource group name e.g. rg-devbox-dev"
$location = Read-Host " Please enter region name e.g. eastus"; 
$userPrincipalId=(Get-AzADUser -UserPrincipalName $userPrincipalName).Id
if($userPrincipalId){
    Write-WELog " Start provisioning..." " INFO"
    az group create -l $location -n $resourceGroupName
    az group deployment create -g $resourceGroupName -f main.bicep --parameters userPrincipalId=$userPrincipalId
}else {
    Write-WELog " User Principal Name cannot be found." " INFO"
}

Write-WELog " Provisioning Completed." " INFO"

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
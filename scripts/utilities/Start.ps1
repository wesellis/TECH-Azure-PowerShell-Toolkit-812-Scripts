#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Start

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$UserPrincipalName = Read-Host "Please enter user principal name e.g. alias@xxx.com"
$ResourceGroupName = Read-Host "Please enter resource group name e.g. rg-devbox-dev";
$location = Read-Host "Please enter region name e.g. eastus" ;
$UserPrincipalId=(Get-AzADUser -UserPrincipalName $UserPrincipalName).Id
if($UserPrincipalId){
    Write-Output "Start provisioning..."
    az group create -l $location -n $ResourceGroupName
    az group deployment create -g $ResourceGroupName -f main.bicep --parameters userPrincipalId=$UserPrincipalId
}else {
    Write-Output "User Principal Name cannot be found."
}
Write-Output "Provisioning Completed."




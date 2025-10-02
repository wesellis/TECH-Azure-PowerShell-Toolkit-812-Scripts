#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Automation, Az.Accounts

<#
.SYNOPSIS
    Deleteresourcegroups Parent

.DESCRIPTION
    Azure automation script for deleting resource groups
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER RGNames
    Comma-separated list of resource group names to delete

.PARAMETER WhatIf
    Enter the value for WhatIf. Values can be either true or false

.EXAMPLE
    .\DeleteResourceGroups_Parent.ps1 -WhatIf $false

.NOTES
    Version History
    v1.0 - Initial Release
#>

[CmdletBinding()]
param(
    [String]$RGNames,
    [Parameter(HelpMessage="Enter the value for WhatIf. Values can be either true or false")]
    [bool]$WhatIf = $false
)

$ErrorActionPreference = "Stop"
$ConnectionName = "AzureRunAsConnection"

try {
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName
    "Logging in to Azure..."
    $params = @{
        ApplicationId = $ServicePrincipalConnection.ApplicationId
        TenantId = $ServicePrincipalConnection.TenantId
        CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
    }
    Connect-AzAccount -ServicePrincipal @params
}
catch {
    if (!$ServicePrincipalConnection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try {
    [string[]] $VMRGList = $RGNames -split " ,"
    $AutomationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $AroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

    if($null -ne $VMRGList) {
        $Resources = @()
        foreach($Resource in $VMRGList) {
            $CheckRGname = Get-AzResourceGroup -Name $Resource.Trim() -ErrorAction SilentlyContinue
            if ($null -eq $CheckRGname) {
                Write-Output "$($Resource) is not a valid Resource Group Name. Please Verify!"
                Write-Warning "$($Resource) is not a valid Resource Group Name. Please Verify!"
            }
            else {
                if($WhatIf -eq $false) {
                    Write-Output "Calling the child runbook DeleteRG to delete the resource group $($Resource)..."
                    $params = @{"RGName" = $Resource}
                    $runbook = Start-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName -Name "DeleteResourceGroup_Child" -Parameters $params
                }
                $Resources = $Resources + $Resource
            }
        }
        if($WhatIf -eq $true) {
            Write-Output "WhatIf parameter is set to True..."
            Write-Output "When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. RGs), that will be impacted if you choose to deploy this runbook."
            Write-Output "No action will be taken on these resource groups $($Resources) at this time..."
        }
        Write-Output "Execution Completed..."
    }
    else {
        Write-Output "Resource Group Name is empty..."
    }
}
catch {
    Write-Output "Error Occurred in the Delete ResourceGroup Wrapper..."
    Write-Output $_.Exception
}
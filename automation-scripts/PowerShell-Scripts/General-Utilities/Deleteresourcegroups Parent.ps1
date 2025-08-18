<#
.SYNOPSIS
    Deleteresourcegroups Parent

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

<#
.SYNOPSIS
    We Enhanced Deleteresourcegroups Parent

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS  
 Script for deleting the resource groups
.DESCRIPTION  
 Script for deleting the resource groups
.EXAMPLE  
.\DeleteResourceGroups_Parent.ps1 -WhatIf $false
Version History  
v1.0   - Initial Release  


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [String]$WERGNames,
    [Parameter(Mandatory=$false,HelpMessage=" Enter the value for WhatIf. Values can be either true or false" )][bool]$WEWhatIf = $false
)
$connectionName = " AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$servicePrincipalConnection)
    {
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{
    [string[]] $WEVMRGList = $WERGNames -split " ,"
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'


    if($WEVMRGList -ne $null)
    {
        $WEResources=@()
        foreach($WEResource in $WEVMRGList)
        {
            $checkRGname = Get-AzureRmResourceGroup  $WEResource.Trim() -ev notPresent -ea 0  
            if ($checkRGname -eq $null)
            {
                Write-Output " $($WEResource) is not a valid Resource Group Name. Please Verify!"
                Write-Warning " $($WEResource) is not a valid Resource Group Name. Please Verify!"
            }
            else
            {  
                if($WEWhatIf -eq $false)
                {
                    Write-Output " Calling the child runbook DeleteRG to delete the resource group $($WEResource)..."
                   ;  $params = @{" RGName" =$WEResource}                  
                   ;  $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name " DeleteResourceGroup_Child" -Parameters $params
                }                
               ;  $WEResources = $WEResources + $WEResource                
            }
        }
        if($WEWhatIf -eq $true)
        {
            Write-Output " WhatIf parameter is set to True..."
            Write-Output " When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. RGs), that will be impacted if you choose to deploy this runbook."
            Write-Output " No action will be taken on these resource groups $($WEResources) at this time..."            
        }
        write-output " Execution Completed..."
    }
    else
    {
        Write-Output " Resource Group Name is empty..."
    }     
}
catch
{
    Write-Output " Error Occurred in the Delete ResourceGroup Wrapper..."
    Write-Output $_.Exception
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
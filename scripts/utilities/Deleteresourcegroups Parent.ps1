#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Deleteresourcegroups Parent

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
 Script for deleting the resource groups
 Script for deleting the resource groups
.\DeleteResourceGroups_Parent.ps1 -WhatIf $false
Version History
v1.0   - Initial Release
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [String]$RGNames,
    [Parameter(HelpMessage="Enter the value for WhatIf. Values can be either true or false" )][bool]$WhatIf = $false
)
#region Functions
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
    "Logging in to Azure..."
    $params = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }
    Add-AzureRmAccount @params
}
catch
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
try
{
    [string[]] $VMRGList = $RGNames -split " ,"
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'
    if($null -ne $VMRGList)
    {
        $Resources=@()
        foreach($Resource in $VMRGList)
        {
            $checkRGname = Get-AzureRmResourceGroup -ErrorAction Stop  $Resource.Trim() -ev notPresent -ea 0
            if ($null -eq $checkRGname)
            {
                Write-Output " $($Resource) is not a valid Resource Group Name. Please Verify!"
                Write-Warning " $($Resource) is not a valid Resource Group Name. Please Verify!"
            }
            else
            {
                if($WhatIf -eq $false)
                {
                    Write-Output "Calling the child runbook DeleteRG to delete the resource group $($Resource)..."
$params = @{"RGName" =$Resource}
$runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name "DeleteResourceGroup_Child" -Parameters $params
                }
$Resources = $Resources + $Resource
            }
        }
        if($WhatIf -eq $true)
        {
            Write-Output "WhatIf parameter is set to True..."
            Write-Output "When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. RGs), that will be impacted if you choose to deploy this runbook."
            Write-Output "No action will be taken on these resource groups $($Resources) at this time..."
        }
        write-output "Execution Completed..."
    }
    else
    {
        Write-Output "Resource Group Name is empty..."

} catch
{
    Write-Output "Error Occurred in the Delete ResourceGroup Wrapper..."
    Write-Output $_.Exception
}



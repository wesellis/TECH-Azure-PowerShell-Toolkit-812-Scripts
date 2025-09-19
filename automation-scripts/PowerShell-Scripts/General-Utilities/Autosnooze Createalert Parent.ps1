#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Autosnooze Createalert Parent

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
    We Enhanced Autosnooze Createalert Parent

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS  
 Runbook for shutdown the Azure VM based on CPU usage
.DESCRIPTION  
 Runbook for shutdown the Azure VM based on CPU usage
.EXAMPLE  
.\AutoSnooze_CreateAlert_Parent.ps1 -WhatIf $false
Version History  
v1.0   - Initial Release  


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
[Parameter(Mandatory=$false,HelpMessage=" Enter the value for WhatIf. Values can be either true or false" )][bool]$WEWhatIf = $false
)

#region Functions

function WE-CheckExcludeVM ($WEFilterVMList)
{
    
    $WEAzureVM= Get-AzureRmVM -ErrorAction SilentlyContinue
    [boolean] $WEISexists = $false
            
    [string[]] $invalidvm=@()
    $WEExAzureVMList=@()

    foreach($filtervm in $WEVMfilterList)
    {
        foreach($vmname in $WEAzureVM)
        {
            if($WEVmname.Name.ToLower().Trim() -eq $filtervm.Tolower().Trim())
            {                    
                $WEISexists = $true
                $WEExAzureVMList = $WEExAzureVMList + $vmname
                break                    
            }
            else
            {
                $WEISexists = $false
            }
        }
        if($WEISexists -eq $false)
        {
            $invalidvm = $invalidvm+$filtervm
        }
    }

    if($null -ne $invalidvm)
    {
        Write-Output " Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        Write-Warning " Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        exit
    }
    else
    {
        return $WEExAzureVMList
    }
    
}


$connectionName = " AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
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
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}



$WESubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
$WEResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
$WEExcludeVMNames = Get-AutomationVariable -Name 'External_ExcludeVMNames'
$automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
$aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'


$webhookUri = Get-AutomationVariable -Name 'Internal_AutoSnooze_WebhookUri'

try
    {  
        Write-Output " Runbook Execution Started..."
        [string[]] $WEVMfilterList = $WEExcludeVMNames -split " ,"
        [string[]] $WEVMRGList = $WEResourceGroupNames -split " ,"

        #Validate the Exclude List VM's and stop the execution if the list contains any invalid VM
        if([string]::IsNullOrEmpty($WEExcludeVMNames) -ne $true)
        {
            Write-Output " Exclude VM's added so validating the resource(s)..."            
           ;  $WEExAzureVMList = CheckExcludeVM -FilterVMList $WEVMfilterList
        } 

        if ($null -ne $WEExAzureVMList -and $WEWhatIf -eq $false)
        {
            foreach($WEVM in $WEExAzureVMList)
            {
                try
                {
                        Write-Output " Disabling the alert rules for VM : $($WEVM.Name)" 
                       ;  $params = @{" VMObject" =$WEVM;" AlertAction" =" Disable" ;" WebhookUri" =$webhookUri}                    
                        $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $aroResourceGroupName –Parameters $params
                }
                catch
                {
                    $ex = $_.Exception
                    Write-Output $_.Exception 
                }
            }
        }
        elseif($null -ne $WEExAzureVMList -and $WEWhatIf -eq $true)
        {
            Write-Output " WhatIf parameter is set to True..."
            Write-Output " What if: Performing the alert rules disable for the Exclude VM's..."
            Write-Output $WEExcludeVMNames
        }

        $WEAzureVMListTemp = $null
        $WEAzureVMList=@()
        ##Getting VM Details based on RG List or Subscription
        if($null -ne $WEVMRGList)
        {
            foreach($WEResource in $WEVMRGList)
            {
                Write-Output " Validating the resource group name ($($WEResource.Trim()))" 
                $checkRGname = Get-AzureRmResourceGroup -ErrorAction Stop  $WEResource.Trim() -ev notPresent -ea 0  
                if ($null -eq $checkRGname)
                {
                    Write-Output " $($WEResource) is not a valid Resource Group Name. Please Verify!"
                    Write-Warning " $($WEResource) is not a valid Resource Group Name. Please Verify!"
                }
                else
                {                   
                    $WEAzureVMListTemp = Get-AzureRmVM -ResourceGroupName $WEResource -ErrorAction SilentlyContinue
                    if($null -ne $WEAzureVMListTemp)
                    {
                        $WEAzureVMList = $WEAzureVMList + $WEAzureVMListTemp
                    }
                }
            }
        } 
        else
        {
            Write-Output " Getting all the VM's from the subscription..."  
            $WEAzureVMList=Get-AzureRmVM -ErrorAction SilentlyContinue
        }        
        
        $WEActualAzureVMList=@()
        if($null -ne $WEVMfilterList)
        {
            foreach($WEVM in $WEAzureVMList)
            {  
                ##Checking Vm in excluded list                         
                if($WEVMfilterList -notcontains ($($WEVM.Name)))
                {
                    $WEActualAzureVMList = $WEActualAzureVMList + $WEVM
                }
            }
        }
        else
        {
           ;  $WEActualAzureVMList = $WEAzureVMList
        }

        if($WEWhatIf -eq $false)
        {    
            foreach($WEVM in $WEActualAzureVMList)
            {  
                    Write-Output " Creating alert rules for the VM : $($WEVM.Name)"
                   ;  $params = @{" VMObject" =$WEVM;" AlertAction" =" Create" ;" WebhookUri" =$webhookUri}                    
                    $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $aroResourceGroupName –Parameters $params
            }
            Write-Output " Note: All the alert rules creation are processed in parallel. Please check the child runbook (AutoSnooze_CreateAlert_Child) job status..."
        }
        elseif($WEWhatIf -eq $true)
        {
            Write-Output " WhatIf parameter is set to True..."
            Write-Output " When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. VMs), that will be impacted if you choose to deploy this runbook."
            Write-Output " No action will be taken at this time..."
            Write-Output $($WEActualAzureVMList) | Select-Object Name, ResourceGroupName | Format-List
        }
        Write-Output " Runbook Execution Completed..."
    }
    catch
    {
       ;  $ex = $_.Exception
        Write-Output $_.Exception
    }


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion

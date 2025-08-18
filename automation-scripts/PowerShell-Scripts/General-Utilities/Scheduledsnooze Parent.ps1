<#
.SYNOPSIS
    Scheduledsnooze Parent

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
    We Enhanced Scheduledsnooze Parent

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
 Wrapper script for get all the VM's in all RG's or subscription level and then call the Start or Stop runbook
.DESCRIPTION  
 Wrapper script for get all the VM's in all RG's or subscription level and then call the Start or Stop runbook
.EXAMPLE  
.\ScheduledSnooze_Parent.ps1 -Action "Value1" -WhatIf " False"
Version History  
v1.0   - Initial Release  

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory = $true, HelpMessage = " Enter the value for Action. Values can be either stop or start" )][String]$WEAction,
    [Parameter(Mandatory = $false, HelpMessage = " Enter the value for WhatIf. Values can be either true or false" )][bool]$WEWhatIf = $false
)

function WE-ScheduleSnoozeAction ($WEVMObject, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction) {
    
    Write-Output " Calling the ScheduledSnooze_Child wrapper (Action = $($WEAction))..."
    if ($WEAction.ToLower() -eq 'start') {
       ;  $params = @{" VMName" = " $($WEVMObject.Name)" ; " Action" = " start" ; " ResourceGroupName" = " $($WEVMObject.ResourceGroupName)" }   
    }    
    elseif ($WEAction.ToLower() -eq 'stop') {
        $params = @{" VMName" = " $($WEVMObject.Name)" ; " Action" = " stop" ; " ResourceGroupName" = " $($WEVMObject.ResourceGroupName)" }                    
    }    

    Write-Output " Performing the schedule $($WEAction) for the VM : $($WEVMObject.Name)"
    $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'ScheduledSnooze_Child' -ResourceGroupName $aroResourceGroupName –Parameters $params
}

function WE-CheckExcludeVM ($WEFilterVMList) {
    $WEAzureVM = Get-AzureRmVM -ErrorAction SilentlyContinue
    [boolean] $WEISexists = $false
            
    [string[]] $invalidvm = @()
    $WEExAzureVMList = @()

    foreach ($filtervm in $WEVMfilterList) {
        foreach ($vmname in $WEAzureVM) {
            if ($WEVmname.Name.ToLower().Trim() -eq $filtervm.Tolower().Trim()) {                    
                $WEISexists = $true
                $WEExAzureVMList = $WEExAzureVMList + $vmname
                break                    
            }
            else {
                $WEISexists = $false
            }
        }
        if ($WEISexists -eq $false) {
            $invalidvm = $invalidvm + $filtervm
        }
    }
    if ($invalidvm -ne $null) {
        Write-Output " Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        Write-Warning " Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        exit
    }
    else {
        Write-Output " Exclude VM's validation completed..."
    }    
}


$connectionName = " AzureRunAsConnection"
try {
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}



$WESubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
$WEResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
$WEExcludeVMNames = Get-AutomationVariable -Name 'External_ExcludeVMNames'
$automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
$aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

try {  
    $WEAction = $WEAction.Trim().ToLower()

    if (!($WEAction -eq " start" -or $WEAction -eq " stop" )) {
        Write-Output " `$WEAction parameter value is : $($WEAction). Value should be either start or stop!"
        Write-Output " Completed the runbook execution..."
        exit
    }            
    Write-Output " Runbook Execution Started..."
    [string[]] $WEVMfilterList = $WEExcludeVMNames -split " ,"
    [string[]] $WEVMRGList = $WEResourceGroupNames -split " ,"

    #Validate the Exclude List VM's and stop the execution if the list contains any invalid VM
    if ([string]::IsNullOrEmpty($WEExcludeVMNames) -ne $true) {
        Write-Output " Exclude VM's added so validating the resource(s)..."
        CheckExcludeVM -FilterVMList $WEVMfilterList
    } 
    $WEAzureVMListTemp = $null
    $WEAzureVMList = @()
    ##Getting VM Details based on RG List or Subscription
    if ($WEVMRGList -ne $null) {
        foreach ($WEResource in $WEVMRGList) {
            Write-Output " Validating the resource group name ($($WEResource.Trim()))" 
            $checkRGname = Get-AzureRmResourceGroup -Name $WEResource.Trim() -ev notPresent -ea 0  
            if ($checkRGname -eq $null) {
                Write-Warning " $($WEResource) is not a valid Resource Group Name. Please Verify!"
            }
            else {                   
                Write-Output " Resource Group Exists..."
                $WEAzureVMListTemp = Get-AzureRmVM -ResourceGroupName $WEResource -ErrorAction SilentlyContinue
                if ($WEAzureVMListTemp -ne $null) {
                    $WEAzureVMList = $WEAzureVMList + $WEAzureVMListTemp
                }
            }
        }
    } 
    else {
        Write-Output " Getting all the VM's from the subscription..."  
        $WEAzureVMList = Get-AzureRmVM -ErrorAction SilentlyContinue
    }

    $WEActualAzureVMList = @()
    if ($WEVMfilterList -ne $null) {
        foreach ($WEVM in $WEAzureVMList) {  
            ##Checking Vm in excluded list                         
            if ($WEVMfilterList -notcontains ($($WEVM.Name))) {
                $WEActualAzureVMList = $WEActualAzureVMList + $WEVM
            }
        }
    }
    else {
       ;  $WEActualAzureVMList = $WEAzureVMList
    }

    Write-Output " The current action is $($WEAction)"
        
    if ($WEWhatIf -eq $false) {    
                
        foreach ($WEVM in $WEActualAzureVMList) {  
            ScheduleSnoozeAction -VMObject $WEVM -Action $WEAction
        }
    }
    elseif ($WEWhatIf -eq $true) {
        Write-Output " WhatIf parameter is set to True..."
        Write-Output " When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. VMs), that will be impacted if you choose to deploy this runbook."
        Write-Output " No action will be taken at this time..."
        Write-Output $($WEActualAzureVMList) | Select-Object Name, ResourceGroupName | Format-List
    }
    Write-Output " Runbook Execution Completed..."
}
catch {
   ;  $ex = $_.Exception
    Write-Output $_.Exception
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
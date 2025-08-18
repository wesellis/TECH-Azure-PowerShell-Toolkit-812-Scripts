<#
.SYNOPSIS
    Sequencedsnooze Parent

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
    We Enhanced Sequencedsnooze Parent

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
 This runbook used to perform sequenced start or stop Azure RM VM
.DESCRIPTION  
 This runbook used to perform sequenced start or stop Azure RM VM
.EXAMPLE  
.\SequencedSnooze_Parent.ps1 -Action "Value1" 
Version History  
v1.0   - <Team-A> - Initial Release  

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
[Parameter(Mandatory=$true,HelpMessage=" Enter the value for Action. Values can be either stop or start" )][String]$WEAction,
[Parameter(Mandatory=$false,HelpMessage=" Enter the value for WhatIf. Values can be either true or false" )][bool]$WEWhatIf = $false,
[Parameter(Mandatory=$false,HelpMessage=" Enter the value for ContinueOnError. Values can be either true or false" )][bool]$WEContinueOnError = $false
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

function WE-CheckVMState ($WEVMObject,[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction)
{
    [bool]$WEIsValid = $false
    
    $WECheckVMState = (Get-AzureRmVM -ResourceGroupName $WEVMObject.ResourceGroupName -Name $WEVMObject.Name -Status -ErrorAction SilentlyContinue).Statuses.Code[1]
    if($WEAction.ToLower() -eq 'start' -and $WECheckVMState -eq 'PowerState/running')
    {
        $WEIsValid = $true
    }    
    elseif($WEAction.ToLower() -eq 'stop' -and $WECheckVMState -eq 'PowerState/deallocated')
    {
            $WEIsValid = $true
    }    
    return $WEIsValid
}


$automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
$aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

try
{
    $WEAction = $WEAction.Trim().ToLower()

    if(!($WEAction -eq " start" -or $WEAction -eq " stop" ))
    {
        Write-Output " `$WEAction parameter value is : $($WEAction). Value should be either start or stop!"
        Write-Output " Completed the runbook execution..."
        exit
    }
     
    Write-Output " Executing the Sequenced $($WEAction)..."   
    Write-Output " Input parameter values..."
    Write-Output " `$WEAction : $($WEAction)"
    Write-Output " `$WEWhatIf : $($WEWhatIf)"
    Write-Output " `$WEContinueOnError : $($WEContinueOnError)"
    Write-Output " Filtering the tags across all the VM's..."
    
    $tagValue = " sequence"    
    $WETagKeys = Get-AzureRmVM | Where-Object {$_.Tags.Keys -eq $tagValue.ToLower()} | Select Tags
    $WESequences=[System.Collections.ArrayList]@()
    foreach($tag in $WETagKeys.Tags)
    {
        if($tag.ContainsKey($tagValue))
        {
            [void]$WESequences.add([int]$tag.sequence)
        }
    }

    $WESequences = $WESequences | Sort-Object -Unique
    if($WEAction.ToLower() -eq 'start')
    {
        $WESequences = $WESequences | Sort -Descending
    }

    foreach($seq in $WESequences)
    {
        if($WEWhatIf -eq $false)
        {
            Write-Output " Performing the $($WEAction) for the sequence-$($seq) VM's..."
           ;  $WEAzureVMList=Find-AzureRmResource -TagName $tagValue.ToLower() -TagValue $seq | Where-Object {$_.ResourceType -eq “Microsoft.Compute/virtualMachines”} | Select Name, ResourceGroupName
        
            foreach($vmObj in $WEAzureVMList)
            {                
                Write-Output " Performing the $($WEAction) action on VM: $($vmobj.Name)"
               ;  $params = @{" VMName" =" $($vmObj.Name)" ;" Action" =$WEAction;" ResourceGroupName" =" $($vmObj.ResourceGroupName)" }                    
                Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'ScheduledSnooze_Child' -ResourceGroupName $aroResourceGroupName –Parameters $params                
            }

            Write-Output " Completed the sequenced $($WEAction) for the sequence-$($seq) VM's..."

            if(($WEAction -eq 'stop' -and $seq -ne $WESequences.Count) -or ($WEAction -eq 'start' -and $seq -ne [int]$WESequences.Count - ([int]$WESequences.Count-1)))
            {
                Write-Output " Validating the status before processing the next sequence..."
            }        

            foreach($vmObjStatus in $WEAzureVMList)
            {
                [int]$WESleepCount = 0 
                $WECheckVMStatus = CheckVMState -VMObject $vmObjStatus -Action $WEAction
                While($WECheckVMStatus -eq $false)
                {                
                    Write-Output " Checking the VM Status in 10 seconds..."
                    Start-Sleep -Seconds 10
                    $WESleepCount = $WESleepCount + 10
                    if($WESleepCount -gt 600 -and $WEContinueOnError -eq $false)
                    {
                        Write-Output " Unable to $($WEAction) the VM $($vmObjStatus.Name). ContinueOnError is set to False, hence terminating the sequenced $($WEAction)..."
                        Write-Output " Completed the sequenced $($WEAction)..."
                        exit
                    }
                    elseif($WESleepCount -gt 600 -and $WEContinueOnError -eq $true)
                    {
                        Write-Output " Unable to $($WEAction) the VM $($vmObjStatus.Name). ContinueOnError is set to True, hence moving to the next resource..."
                        break
                    }
                   ;  $WECheckVMStatus = CheckVMState -VMObject $vmObjStatus -Action $WEAction
                }
            }
        }
        elseif($WEWhatIf -eq $true)
        {
            Write-Output " WhatIf parameter is set to True..."
            Write-Output " When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. VMs), that will be impacted if you choose to deploy this runbook."
            Write-Output " No action will be taken at this time..."
           ;  $WEAzureVMList=Find-AzureRmResource -TagName $tagValue.ToLower() -TagValue $seq | Where-Object {$_.ResourceType -eq “Microsoft.Compute/virtualMachines”} | Select-Object Name, ResourceGroupName            
            Write-Output $($WEAzureVMList)
        }
    }
    Write-Output " Completed the sequenced $($WEAction)..."
}
catch
{
    Write-Output " Error Occurred in the sequence $($WEAction) runbook..."   
    Write-Output $_.Exception
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
<#
.SYNOPSIS
    Autosnooze Createalert Parent

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
 Runbook for shutdown the Azure VM based on CPU usage
 Runbook for shutdown the Azure VM based on CPU usage
.\AutoSnooze_CreateAlert_Parent.ps1 -WhatIf $false
Version History
v1.0   - Initial Release
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
[Parameter(HelpMessage="Enter the value for WhatIf. Values can be either true or false" )][bool]$WhatIf = $false
)
function CheckExcludeVM ($FilterVMList)
{
    $AzureVM= Get-AzureRmVM -ErrorAction SilentlyContinue
    [boolean] $ISexists = $false
    [string[]] $invalidvm=@()
    $ExAzureVMList=@()
    foreach($filtervm in $VMfilterList)
    {
        foreach($vmname in $AzureVM)
        {
            if($Vmname.Name.ToLower().Trim() -eq $filtervm.Tolower().Trim())
            {
                $ISexists = $true
                $ExAzureVMList = $ExAzureVMList + $vmname
                break
            }
            else
            {
                $ISexists = $false
            }
        }
        if($ISexists -eq $false)
        {
            $invalidvm = $invalidvm+$filtervm
        }
    }
    if($null -ne $invalidvm)
    {
        Write-Output "Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        Write-Warning "Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        exit
    }
    else
    {
        return $ExAzureVMList
    }
}
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
$SubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
$ResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
$ExcludeVMNames = Get-AutomationVariable -Name 'External_ExcludeVMNames'
$automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
$aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'
$webhookUri = Get-AutomationVariable -Name 'Internal_AutoSnooze_WebhookUri'
try
    {
        Write-Output "Runbook Execution Started..."
        [string[]] $VMfilterList = $ExcludeVMNames -split " ,"
        [string[]] $VMRGList = $ResourceGroupNames -split " ,"
        #Validate the Exclude List VM's and stop the execution if the list contains any invalid VM
        if([string]::IsNullOrEmpty($ExcludeVMNames) -ne $true)
        {
            Write-Output "Exclude VM's added so validating the resource(s)..."
$ExAzureVMList = CheckExcludeVM -FilterVMList $VMfilterList
        }
        if ($null -ne $ExAzureVMList -and $WhatIf -eq $false)
        {
            foreach($VM in $ExAzureVMList)
            {
                try
                {
                        Write-Output "Disabling the alert rules for VM : $($VM.Name)"
$params = @{"VMObject" =$VM;"AlertAction" ="Disable" ;"WebhookUri" =$webhookUri}
                        $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $aroResourceGroupName Parameters $params
                }
                catch
                {
                    $ex = $_.Exception
                    Write-Output $_.Exception
                }
            }
        }
        elseif($null -ne $ExAzureVMList -and $WhatIf -eq $true)
        {
            Write-Output "WhatIf parameter is set to True..."
            Write-Output "What if: Performing the alert rules disable for the Exclude VM's..."
            Write-Output $ExcludeVMNames
        }
        $AzureVMListTemp = $null
        $AzureVMList=@()
        ##Getting VM Details based on RG List or Subscription
        if($null -ne $VMRGList)
        {
            foreach($Resource in $VMRGList)
            {
                Write-Output "Validating the resource group name ($($Resource.Trim()))"
                $checkRGname = Get-AzureRmResourceGroup -ErrorAction Stop  $Resource.Trim() -ev notPresent -ea 0
                if ($null -eq $checkRGname)
                {
                    Write-Output " $($Resource) is not a valid Resource Group Name. Please Verify!"
                    Write-Warning " $($Resource) is not a valid Resource Group Name. Please Verify!"
                }
                else
                {
                    $AzureVMListTemp = Get-AzureRmVM -ResourceGroupName $Resource -ErrorAction SilentlyContinue
                    if($null -ne $AzureVMListTemp)
                    {
                        $AzureVMList = $AzureVMList + $AzureVMListTemp
                    }
                }
            }
        }
        else
        {
            Write-Output "Getting all the VM's from the subscription..."
            $AzureVMList=Get-AzureRmVM -ErrorAction SilentlyContinue
        }
        $ActualAzureVMList=@()
        if($null -ne $VMfilterList)
        {
            foreach($VM in $AzureVMList)
            {
                ##Checking Vm in excluded list
                if($VMfilterList -notcontains ($($VM.Name)))
                {
                    $ActualAzureVMList = $ActualAzureVMList + $VM
                }
            }
        }
        else
        {
$ActualAzureVMList = $AzureVMList
        }
        if($WhatIf -eq $false)
        {
            foreach($VM in $ActualAzureVMList)
            {
                    Write-Output "Creating alert rules for the VM : $($VM.Name)"
$params = @{"VMObject" =$VM;"AlertAction" =Create" ;"WebhookUri" =$webhookUri}
                    $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $aroResourceGroupName Parameters $params
            }
            Write-Output "Note: All the alert rules creation are processed in parallel. Please check the child runbook (AutoSnooze_CreateAlert_Child) job status..."
        }
        elseif($WhatIf -eq $true)
        {
            Write-Output "WhatIf parameter is set to True..."
            Write-Output "When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. VMs), that will be impacted if you choose to deploy this runbook."
            Write-Output "No action will be taken at this time..."
            Write-Output $($ActualAzureVMList) | Select-Object Name, ResourceGroupName | Format-List
        }
        Write-Output "Runbook Execution Completed..."
    }
    catch
    {
$ex = $_.Exception
        Write-Output $_.Exception
    }\n
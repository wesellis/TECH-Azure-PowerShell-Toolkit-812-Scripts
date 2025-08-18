<#
.SYNOPSIS
    Autosnooze Disable

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
    We Enhanced Autosnooze Disable

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
 Disable AutoSnooze feature
.DESCRIPTION  
 Disable AutoSnooze feature
.EXAMPLE  
.\AutoSnooze_Disable.ps1 
Version History  
v1.0   - Initial Release  



$connectionName = "AzureRunAsConnection"
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
    Write-Output " Performing the AutoSnooze Disable..."

    Write-Output " Collecting all the schedule names for AutoSnooze..."

    #---------Read all the input variables---------------
    $WESubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
    $WEResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

    $webhookUri = Get-AutomationVariable -Name 'Internal_AutoSnooze_WebhookUri'
    $scheduleNameforCreateAlert = " Schedule_AutoSnooze_CreateAlert_Parent"

    Write-Output " Disabling the schedules for AutoSnooze..."

    #Disable the schedule for AutoSnooze
    Set-AzureRmAutomationSchedule -automationAccountName $automationAccountName -Name $scheduleNameforCreateAlert -ResourceGroupName $aroResourceGroupName -IsEnabled $false

    Write-Output " Disabling the alerts on all the VM's configured as per asset variable..."

    [string[]] $WEVMRGList = $WEResourceGroupNames -split " ,"

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
                Write-Warning " $($WEResource) is not a valid Resource Group Name. Please Verify!"
				Write-Output " $($WEResource) is not a valid Resource Group Name. Please Verify!"
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
       ;  $WEAzureVMList=Get-AzureRmVM -ErrorAction SilentlyContinue
    }

    Write-Output " Calling child runbook to disable the alert on all the VM's..."    

    foreach($WEVM in $WEAzureVMList)
    {
        try
        {
           ;  $params = @{" VMObject" =$WEVM;" AlertAction" =" Disable" ;" WebhookUri" =$webhookUri}                    
            $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $aroResourceGroupName –Parameters $params
        }
        catch
        {
            Write-Output " Error Occurred on Alert disable..."   
            Write-Output $_.Exception 
        }
    }

    Write-Output " AutoSnooze disable execution completed..."

}
catch
{
    Write-Output " Error Occurred on AutoSnooze Disable Wrapper..."   
    Write-Output $_.Exception
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
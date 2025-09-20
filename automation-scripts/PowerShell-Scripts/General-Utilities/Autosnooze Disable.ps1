#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Autosnooze Disable

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
 Disable AutoSnooze feature
 Disable AutoSnooze feature
.\AutoSnooze_Disable.ps1
Version History
v1.0   - Initial Release
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
    Write-Output "Performing the AutoSnooze Disable..."
    Write-Output "Collecting all the schedule names for AutoSnooze..."
    #---------Read all the input variables---------------
    $SubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
    $ResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'
    $webhookUri = Get-AutomationVariable -Name 'Internal_AutoSnooze_WebhookUri'
    $scheduleNameforCreateAlert = "Schedule_AutoSnooze_CreateAlert_Parent"
    Write-Output "Disabling the schedules for AutoSnooze..."
    #Disable the schedule for AutoSnooze
    Set-AzureRmAutomationSchedule -automationAccountName $automationAccountName -Name $scheduleNameforCreateAlert -ResourceGroupName $aroResourceGroupName -IsEnabled $false
    Write-Output "Disabling the alerts on all the VM's configured as per asset variable..."
    [string[]] $VMRGList = $ResourceGroupNames -split " ,"
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
                Write-Warning " $($Resource) is not a valid Resource Group Name. Please Verify!"
				Write-Output " $($Resource) is not a valid Resource Group Name. Please Verify!"
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
    Write-Output "Calling child runbook to disable the alert on all the VM's..."
    foreach($VM in $AzureVMList)
    {
        try
        {
$params = @{"VMObject" =$VM;"AlertAction" ="Disable" ;"WebhookUri" =$webhookUri}
            $runbook = Start-AzureRmAutomationRunbook -automationAccountName $automationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $aroResourceGroupName Parameters $params
        }
        catch
        {
            Write-Output "Error Occurred on Alert disable..."
            Write-Output $_.Exception
        }
    }
    Write-Output "AutoSnooze disable execution completed..."
}
catch
{
    Write-Output "Error Occurred on AutoSnooze Disable Wrapper..."
    Write-Output $_.Exception
}\n


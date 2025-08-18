<#
.SYNOPSIS
    We Enhanced Stop Azurev2Vmrunbook

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
  Azure Automation runbook that stops of all VMs in the specified Azure subscription or resource group

.DESCRIPTION
  This Azure runbook connects to Azure and stops all VMs in an Azure subscription or resource group.  
  You can attach a schedule to this runbook to run it at a specific time. Note that this runbook does not stop
  Azure classic VMs. Use https://gallery.technet.microsoft.com/scriptcenter/Stop-Azure-Classic-VMs-7a4ae43e for that.



.PARAMETER automationConnectionName
   Optional with default of " AzureRunAsConnection".
   The name of an Automation Connection used to authenticate

.PARAMETER ResourceGroupName
   Required
   Allows you to specify the resource group containing the VMs to stop.  
   If this parameter is included, only VMs in the specified resource group will be stopped, otherwise all VMs in the subscription will be stopped.  

.NOTES
   AUTHOR: Jeff Bowles
   LASTEDIT: Sept 6, 2016


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [string]$automationConnectionName = 'AzureRunAsConnection',

        
    [Parameter(Mandatory=$false)] 
    [String] $WEResourceGroupName
)




try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $automationConnectionName          

    # Log into Azure
    $login = Connect-AzureRmAccount `
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

write-output " Logged in as $($login.Context.Account.id) to subscriptionID $($login.Context.Subscription.SubscriptionId)."






if ($WEResourceGroupName) 
{ 
	$WEVMs = Get-AzureRmVM -ResourceGroupName $WEResourceGroupName
}
else 
{ 
	$WEVMs = Get-AzureRmVM
}


foreach ($WEVM in $WEVMs)
{
	$vmName = $vm.Name
    $WEResourceGroupName = $vm.resourceGroupName
    $status = ((Get-AzureRmVm -ResourceGroupName $WEResourceGroupName -Name $vmName -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus

    if($status -ne 'VM deallocated')
    {
    ; 	$stopRtn = Stop-AzureRMVM -Name $WEVMName -ResourceGroupName $resourceGroupName -force -ea SilentlyContinue

		if (-not($WEStopRtn))
		{
			# The VM failed to stop, so send notice
        	Write-Output ($WEVMName + " failed to stop" )
        	Write-Error ($WEVMName + " failed to stop. Error was:" ) -ErrorAction Continue
			Write-Error (ConvertTo-Json $WEStopRtn.Error) -ErrorAction Continue
		}
		else
		{
			# The VM stopped, so send notice
			Write-Output ($WEVMName + " has been stopped" )
		}
	}
	else
	{
		Write-Output ($WEVMName + " is already stopped" )
	}
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================